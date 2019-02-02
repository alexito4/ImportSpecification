
public enum Constraint {
    case upToNextMajor(from: Version)
    case exact(Version)
    case ref(String)
}

public struct ImportSpecification {
    public let importName: String
    public let dependencyName: String
    public let constraint: Constraint
}
