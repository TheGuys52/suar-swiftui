//
//  ScriptParserServiceTests.swift
//  Suar
//
//  Created by Adiat Rahman on 29/08/26.
//

@testable import Suar
import XCTest

final class ScriptParserServiceTests: XCTestCase {

    var sut: ScriptParserService!

    override func setUp() {
        super.setUp()
        sut = ScriptParserService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_splitMixedLine_singleCharacterName() async throws {
        let result = sut.splitMixedLine("PRIA:")

        print("=== TEST: PRIA: ===")
        for (i, block) in result.enumerated() {
            print("Block \(i): [\(block.0)] \"\(block.1)\"")
        }

        XCTAssertEqual(result.count, 1)
    }

    func test_splitMixedLine_withStageDirection() async throws {
        let result = sut.splitMixedLine("PRIA: (mengelus dada)")

        print("=== TEST: PRIA: (mengelus dada) ===")
        for (i, block) in result.enumerated() {
            print("Block \(i): [\(block.0)] \"\(block.1)\"")
        }

        XCTAssertEqual(result.count, 2)
    }

    func test_splitMixedLine_fullLine() async throws {
        let result = sut.splitMixedLine("PRIA: (mengelus dada) Ya Tuhan.")

        print("=== TEST: PRIA: (mengelus dada) Ya Tuhan. ===")
        for (i, block) in result.enumerated() {
            print("Block \(i): [\(block.0)] \"\(block.1)\"")
        }

        XCTAssertEqual(result.count, 3)
    }
}
