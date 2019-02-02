import XCTest
@testable import ImportSpecification

final class DependencyURLTests: XCTestCase {

    func testDefaultDomain() {
        let spec = ImportSpecification(
            importName: "Foo",
            dependencyName: "mxcl/Foo",
            constraint: .upToNextMajor(from: .one)
        )
        XCTAssertEqual(
            spec.dependencyURL,
            URL(string: "https://github.com/mxcl/Foo.git")!
        )
    }
    
    func testGievnURL() {
        let spec = ImportSpecification(
            importName: "Foo",
            dependencyName: "https://gitlab.com/mxcl/Foo.git",
            constraint: .upToNextMajor(from: .one)
        )
        XCTAssertEqual(
            spec.dependencyURL,
            URL(string: "https://gitlab.com/mxcl/Foo.git")!
        )
    }
    
    func testInvalidURL() {
        let spec = ImportSpecification(
            importName: "Foo",
            dependencyName: "^^^",
            constraint: .upToNextMajor(from: .one)
        )
        XCTAssertNil(spec.dependencyURL)
    }
}
