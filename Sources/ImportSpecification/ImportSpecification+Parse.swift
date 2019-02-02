import Foundation

extension ImportSpecification {
    
    public static func parse(_ script: String) throws -> [ImportSpecification] {
        var dependencies = [ImportSpecification]()
        
        // We are not a thorough parser, and that would be inefficient.
        // Since any line starting with import that is not in a comment
        // must be at file-scope or it is invalid Swift we just look
        // for that
        //TODO if we are inside a comment block, know that, and wait for
        // end of comment block.
        //TODO may need to parse `#if os()` etc. too, which may mean we
        // should just use SourceKitten and do a proper parse
        //TODO well also could have an import structure where is split
        // over multiple lines with semicolons. So maybe parser?
        for (index, line) in script.split(separator: "\n").enumerated() {
            if index == 0, line.hasPrefix("#!") { continue }
            
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("import") || trimmed.hasPrefix("@testable"), let parse = ImportSpecification(line: trimmed) {
                dependencies.append(parse)
            }
        }
        
        return dependencies
    }
    
}

extension ImportSpecification {
    
    /// - Parameter line: Contract: Single line string trimmed of whitespace.
    public init?(line: String) {
        let pattern = "import\\s+(.*?)\\s*//\\s*(.*?)\\s*(==|~>)\\s*([^\\s]*)"
        let rx = try! NSRegularExpression(pattern: pattern)
        guard let match = rx.firstMatch(in: line, range: line.nsRange) else { return nil }
        guard match.numberOfRanges == 5 else { return nil }
        
        let importName = extractImport(line: line.substring(with: match.range(at: 1))!)
        let depSpec = line.substring(with: match.range(at: 2))!
        let constrainer = line.substring(with: match.range(at: 3))!
        let requirement = line.substring(with: match.range(at: 4))!
        
        let depName: String
        if depSpec.hasPrefix("@") {
            depName = depSpec.dropFirst() + "/" + importName
        } else {
            depName = depSpec
        }
        
        let constraint: Constraint
        if let v = Version(tolerant: requirement) {
            if constrainer == "~>" {
                constraint = .upToNextMajor(from: v)
            } else {
                constraint = .exact(v)
            }
        } else {
            constraint = .ref(requirement)
        }
        
        self.init(importName: importName, dependencyName: depName, constraint: constraint)
    }
}

private func extractImport(line: String) -> String {
    //TODO throw if syntax is weird
    let parts = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
    
    if parts.count == 1 {
        return line
    }
    
    return parts[1].split(separator: ".").first.map(String.init) ?? line
}
