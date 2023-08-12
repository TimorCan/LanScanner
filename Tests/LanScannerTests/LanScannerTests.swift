import XCTest
@testable import SwiftLanScanner

final class LanScannerTests: XCTestCase {
    func testExample() async throws {
        // XCTest Documenation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        do {
            let result = try await SwiftLanScanner.requestInformation(macaddress: "00:3D:E1:00:00")
            assert(result.success ?? false)
        }catch {
            assertionFailure(error.localizedDescription)
        }
        
    }
}
