
public enum Constraint {
    case upToNextMajor(from: Version)
    case exact(Version)
    case ref(String)
}

public struct ImportSpecification {
    let importName: String
    let dependencyName: String
    let constraint: Constraint
}
