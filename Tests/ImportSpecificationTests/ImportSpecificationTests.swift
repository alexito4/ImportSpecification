import XCTest
@testable import Path
@testable import ImportSpecification

final class ImportSpecificationTests: XCTestCase {
    
    func testMultipleDependenciesFullySpecified() throws {
        let script = """
        import Foo // @mxcl ~> 1.0
        import Bar // @mxcl ~> 1.0
        """
        try testScript(script) {
            XCTAssertEqual($0.count, 2)
        }
    }
    
    func testMultipleDependenciesPartiallySpecified() throws {
        let script = """
        import Foo // @mxcl ~> 1.0
        import Bar
        """
        try testScript(script) {
            XCTAssertEqual($0.count, 1)
        }
    }
    
    func testMultipleDependenciesMissingVersion() throws {
        let script = """
        import Foo // @mxcl ~> 1.0
        import Bar // @mxcl
        """
        try testScript(script) {
            XCTAssertEqual($0.count, 1)
        }
    }
    
    func testWigglyArrow() {
        let a = ImportSpecification(line: "import Foo // @mxcl ~> 1.0")
        XCTAssertEqual(a?.dependencyName, "mxcl/Foo")
        XCTAssertEqual(a?.constraint, .upToNextMajor(from: .one))
        XCTAssertEqual(a?.importName, "Foo")
    }
    
    func testExact() {
        let a = ImportSpecification(line: "import Foo // @mxcl == 1.0")
        XCTAssertEqual(a?.dependencyName, "mxcl/Foo")
        XCTAssertEqual(a?.constraint, .exact(.one))
        XCTAssertEqual(a?.importName, "Foo")
    }
    
    func testMissingVersion() {
        let a = ImportSpecification(line: "import Foo // @mxcl")
        XCTAssertNil(a)
    }
    
    func testMoreSpaces() {
        let b = ImportSpecification(line: "import    Foo       //     @mxcl    ~>      1.0")
        XCTAssertEqual(b?.dependencyName, "mxcl/Foo")
        XCTAssertEqual(b?.constraint, .upToNextMajor(from: .one))
        XCTAssertEqual(b?.importName, "Foo")
    }
    
    func testMinimalSpaces() {
        let b = ImportSpecification(line: "import Foo//@mxcl~>1.0")
        XCTAssertEqual(b?.dependencyName, "mxcl/Foo")
        XCTAssertEqual(b?.constraint, .upToNextMajor(from: .one))
        XCTAssertEqual(b?.importName, "Foo")
    }
    
    func testCanOverrideImportName() {
        let b = ImportSpecification(line: "import Foo  // mxcl/Bar ~> 1.0")
        XCTAssertEqual(b?.dependencyName, "mxcl/Bar")
        XCTAssertEqual(b?.constraint, .upToNextMajor(from: .one))
        XCTAssertEqual(b?.importName, "Foo")
    }
    
    func testCanProvideFullURL() {
        let b = ImportSpecification(line: "import Foo  // https://example.com/mxcl/Bar.git ~> 1.0")
        XCTAssertEqual(b?.dependencyName, "https://example.com/mxcl/Bar.git")
        XCTAssertEqual(b?.constraint, .upToNextMajor(from: .one))
        XCTAssertEqual(b?.importName, "Foo")
    }
    
    func testCanDoSpecifiedImports() {
        let kinds = [
            "struct",
            "class",
            "enum",
            "protocol",
            "typealias",
            "func",
            "let",
            "var"
        ]
        for kind in kinds {
            let b = ImportSpecification(line: "import \(kind) Foo.bar  // https://example.com/mxcl/Bar.git ~> 1.0")
            XCTAssertEqual(b?.dependencyName, "https://example.com/mxcl/Bar.git")
            XCTAssertEqual(b?.constraint, .upToNextMajor(from: .one))
            XCTAssertEqual(b?.importName, "Foo")
        }
    }
    
    func testCanUseTestable() {
        let b = ImportSpecification(line: "@testable import Foo  // @bar ~> 1.0")
        XCTAssertEqual(b?.dependencyName, "bar/Foo")
        XCTAssertEqual(b?.constraint, .upToNextMajor(from: .one))
        XCTAssertEqual(b?.importName, "Foo")
    }

    static var allTests = [
        ("testCanDoSpecifiedImports", testCanDoSpecifiedImports),
        ("testCanOverrideImportName", testCanOverrideImportName),
        ("testCanProvideFullURL", testCanProvideFullURL),
        ("testCanUseTestable", testCanUseTestable),
        ("testExact", testExact),
        ("testMinimalSpaces", testMinimalSpaces),
        ("testMoreSpaces", testMoreSpaces),
        ("testWigglyArrow", testWigglyArrow),
        ("testMissingVersion", testMissingVersion),
        ("testMultipleDependenciesFullySpecified", testMultipleDependenciesFullySpecified),
        ("testMultipleDependenciesPartiallySpecified", testMultipleDependenciesPartiallySpecified),
        ("testMultipleDependenciesMissingVersion", testMultipleDependenciesMissingVersion),
    ]
}

extension Constraint: Equatable {
    public static func ==(lhs: Constraint, rhs: Constraint) -> Bool {
        switch (lhs, rhs) {
        case (.upToNextMajor(let v1), .upToNextMajor(let v2)), (.exact(let v1), .exact(let v2)):
            return v1 == v2
        case let (.ref(ref1), .ref(ref2)):
            return ref1 == ref2
        default:
            return false
        }
    }
}

extension Version {
    static var one: Version {
        return Version(1,0,0)
    }
}

private func testScript(_ script: String, line: UInt = #line, body: ([ImportSpecification]) throws -> Void) throws {
    do {
        try Path.mktemp { tmpdir -> Void in
            let file = tmpdir.join("ImportSpecification-test-\(#line).swift")
            try script.write(to: file)
            
            let dependencies = try ImportSpecification.parse(file)
            try body(dependencies)
        }
    } catch {
        XCTFail("\(error)", line: line)
    }
}

// TODO: Shouldn't this be part of the Path package?
class TemporaryDirectory {
    let url: URL
    var path: Path { return Path(string: url.path) }
    
    /**
     Creates a new temporary directory.
     
     The directory is recursively deleted when this object deallocates.
     
     If you need a temporary directory on a specific volume use the `appropriateFor`
     parameter.
     
     - Important: If you are moving a file, ensure to use the `appropriateFor`
     parameter, since it is volume aware and moving the file across volumes will take
     exponentially longer!
     - Important: The `appropriateFor` parameter does not work on Linux.
     - Parameter appropriateFor: The temporary directory will be located on this
     volume.
     */
    init(appropriateFor: URL? = nil) throws {
        #if !os(Linux)
        let appropriate: URL
        if let appropriateFor = appropriateFor {
            appropriate = appropriateFor
        } else if #available(OSX 10.12, iOS 10, tvOS 10, watchOS 3, *) {
            appropriate = FileManager.default.temporaryDirectory
        } else {
            appropriate = URL(fileURLWithPath: NSTemporaryDirectory())
        }
        url = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: appropriate, create: true)
        #else
        let envs = ProcessInfo.processInfo.environment
        let env = envs["TMPDIR"] ?? envs["TEMP"] ?? envs["TMP"] ?? "/tmp"
        let dir = Path.root/env/"swift-sh.XXXXXX"
        var template = [UInt8](dir.string.utf8).map({ Int8($0) }) + [Int8(0)]
        guard mkdtemp(&template) != nil else { throw CocoaError.error(.featureUnsupported) }
        url = URL(fileURLWithPath: String(cString: template))
        #endif
    }
    
    deinit {
        _ = try? FileManager.default.removeItem(at: url)
    }
}

extension Path {
    static func mktemp<T>(body: (Path) throws -> T) throws -> T {
        let tmp = try TemporaryDirectory()
        return try body(tmp.path)
    }
}
