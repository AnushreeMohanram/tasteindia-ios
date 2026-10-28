import XCTest
@testable import TasteIndia

final class MealMapperTests: XCTestCase {
    func testDecodesIndianMealsFixture() throws {
        let data = try fixtureData(named: "indian_meals")
        let response = try JSONDecoder().decode(MealsListResponseDTO.self, from: data)
        XCTAssertEqual(response.meals?.count, 15)
        let first = try XCTUnwrap(response.meals?.first)
        XCTAssertEqual(first.idMeal, "52807")
    }

    func testNormalizesIngredientsAndOmitsEmptyPairs() throws {
        let data = try fixtureData(named: "meal_detail_52795")
        let response = try JSONDecoder().decode(MealLookupResponseDTO.self, from: data)
        let dto = try XCTUnwrap(response.meals?.first)
        let detail = MealMapper.mapDetail(dto)

        XCTAssertEqual(detail.ingredients.count, 16)
        XCTAssertFalse(detail.ingredients.contains(where: { $0.name.isEmpty && $0.measurement.isEmpty }))
        XCTAssertEqual(detail.ingredients.first?.name, "Chicken")
    }

    func testInstructionParagraphsPreserveBreaks() throws {
        let data = try fixtureData(named: "meal_detail_52795")
        let response = try JSONDecoder().decode(MealLookupResponseDTO.self, from: data)
        let detail = MealMapper.mapDetail(try XCTUnwrap(response.meals?.first))
        XCTAssertGreaterThan(detail.instructionParagraphs.count, 1)
    }

    func testSafeURLRejectsInvalidSchemes() {
        XCTAssertNil(URL.safe(string: "not-a-url"))
        XCTAssertNil(URL.safe(string: "ftp://example.com"))
        XCTAssertNotNil(URL.safe(string: "https://www.themealdb.com/images/media/meals/wyxwsp1486979827.jpg"))
    }

    private func fixtureData(named name: String) throws -> Data {
        try TestFixtures.data(named: name)
    }
}
