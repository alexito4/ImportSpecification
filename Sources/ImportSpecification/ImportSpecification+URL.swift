import struct Foundation.URL

public extension ImportSpecification {
    public var dependencyURL: URL? {
        let urlString: String
        if let url = URL(string: dependencyName), url.scheme != nil {
            urlString = dependencyName
        } else {
            urlString = "https://github.com/\(dependencyName).git"
        }
        return URL(string: urlString)
    }
}
