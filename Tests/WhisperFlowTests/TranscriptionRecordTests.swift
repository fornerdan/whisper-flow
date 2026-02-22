import XCTest
@testable import WhisperCore
@testable import WhisperFlow

final class TranscriptionRecordTests: XCTestCase {

    // MARK: - Helpers

    private func makeRecord(
        text: String = "Hello world",
        title: String? = nil
    ) -> TranscriptionRecord {
        TranscriptionRecord(
            text: text,
            language: "en",
            duration: 2.0,
            modelUsed: "base",
            title: title
        )
    }

    // MARK: - Title Property

    func testTitleDefaultsToNil() {
        let record = makeRecord()
        XCTAssertNil(record.title)
    }

    func testTitleCanBeSetViaInit() {
        let record = makeRecord(title: "My Meeting Notes")
        XCTAssertEqual(record.title, "My Meeting Notes")
    }

    func testTitleIsMutable() {
        let record = makeRecord()
        record.title = "Updated Title"
        XCTAssertEqual(record.title, "Updated Title")
    }

    func testTitleCanBeClearedToNil() {
        let record = makeRecord(title: "Some Title")
        record.title = nil
        XCTAssertNil(record.title)
    }

    // MARK: - displayTitle

    func testDisplayTitleReturnsTitleWhenSet() {
        let record = makeRecord(text: "Some long transcription text", title: "Quick Note")
        XCTAssertEqual(record.displayTitle, "Quick Note")
    }

    func testDisplayTitleReturnsTextWhenNoTitle() {
        let record = makeRecord(text: "Hello world")
        XCTAssertEqual(record.displayTitle, "Hello world")
    }

    func testDisplayTitleReturnsTextWhenTitleIsEmpty() {
        let record = makeRecord(text: "Fallback text", title: "")
        XCTAssertEqual(record.displayTitle, "Fallback text")
    }

    func testDisplayTitleReturnsFirstLineOnly() {
        let record = makeRecord(text: "First line\nSecond line\nThird line")
        XCTAssertEqual(record.displayTitle, "First line")
    }

    func testDisplayTitleHandlesCarriageReturn() {
        let record = makeRecord(text: "First line\r\nSecond line")
        XCTAssertEqual(record.displayTitle, "First line")
    }

    func testDisplayTitleTruncatesLongText() {
        let longText = String(repeating: "a", count: 200)
        let record = makeRecord(text: longText)
        XCTAssertEqual(record.displayTitle.count, 101) // 100 chars + "…"
        XCTAssertTrue(record.displayTitle.hasSuffix("…"))
    }

    func testDisplayTitleDoesNotTruncateExactly100Chars() {
        let text = String(repeating: "b", count: 100)
        let record = makeRecord(text: text)
        XCTAssertEqual(record.displayTitle, text)
        XCTAssertFalse(record.displayTitle.hasSuffix("…"))
    }

    func testDisplayTitlePrefersCustomTitleOverLongText() {
        let longText = String(repeating: "x", count: 200)
        let record = makeRecord(text: longText, title: "Short Title")
        XCTAssertEqual(record.displayTitle, "Short Title")
    }

    // MARK: - Codable Backward Compatibility

    func testDecodingWithoutTitleField() throws {
        // Simulates loading a record saved before the title field was added
        let json = """
        {
            "id": "12345678-1234-1234-1234-123456789ABC",
            "text": "Old transcription",
            "language": "en",
            "duration": 5.0,
            "modelUsed": "tiny",
            "createdAt": "2025-01-01T12:00:00Z",
            "isFavorite": false
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let record = try decoder.decode(TranscriptionRecord.self, from: Data(json.utf8))

        XCTAssertEqual(record.text, "Old transcription")
        XCTAssertNil(record.title)
        XCTAssertEqual(record.displayTitle, "Old transcription")
    }

    func testDecodingWithTitleField() throws {
        let json = """
        {
            "id": "12345678-1234-1234-1234-123456789ABC",
            "text": "Some transcription text",
            "language": "en",
            "duration": 3.0,
            "modelUsed": "base",
            "createdAt": "2025-06-15T10:30:00Z",
            "isFavorite": true,
            "title": "Team Standup"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let record = try decoder.decode(TranscriptionRecord.self, from: Data(json.utf8))

        XCTAssertEqual(record.title, "Team Standup")
        XCTAssertEqual(record.displayTitle, "Team Standup")
    }

    func testEncodingIncludesTitle() throws {
        let record = makeRecord(text: "Test text", title: "My Title")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["title"] as? String, "My Title")
    }

    func testRoundTripEncodingDecoding() throws {
        let original = makeRecord(text: "Round trip text", title: "Saved Title")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TranscriptionRecord.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.text, original.text)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.displayTitle, "Saved Title")
    }

    // MARK: - DataStore Rename

    @MainActor
    func testRenameRecordSetsTitle() async throws {
        let store = DataStore.shared
        // Save a new transcription
        let text = "Rename test \(UUID().uuidString)"
        await store.saveTranscription(
            text: text,
            language: "en",
            duration: 1.0,
            modelUsed: "tiny"
        )

        // Find the record we just saved
        let records = try store.fetchRecords(searchText: text)
        guard let record = records.first else {
            XCTFail("Could not find saved record")
            return
        }
        XCTAssertNil(record.title)

        // Rename it
        try store.renameRecord(record, title: "My Custom Title")

        // Fetch again and verify
        let updated = try store.fetchRecords(searchText: text)
        XCTAssertEqual(updated.first?.title, "My Custom Title")
        XCTAssertEqual(updated.first?.displayTitle, "My Custom Title")

        // Clear the title
        try store.renameRecord(record, title: "")
        let cleared = try store.fetchRecords(searchText: text)
        XCTAssertNil(cleared.first?.title)

        // Cleanup
        try store.deleteRecord(record)
    }

    @MainActor
    func testSearchMatchesTitle() async throws {
        let store = DataStore.shared
        let uniqueText = "searchtest \(UUID().uuidString)"
        let uniqueTitle = "UniqueSearchTitle\(Int.random(in: 10000...99999))"

        await store.saveTranscription(
            text: uniqueText,
            language: "en",
            duration: 1.0,
            modelUsed: "tiny"
        )

        let records = try store.fetchRecords(searchText: uniqueText)
        guard let record = records.first else {
            XCTFail("Could not find saved record")
            return
        }

        // Rename with unique title
        try store.renameRecord(record, title: uniqueTitle)

        // Search by title should find it
        let byTitle = try store.fetchRecords(searchText: uniqueTitle)
        XCTAssertEqual(byTitle.count, 1)
        XCTAssertEqual(byTitle.first?.id, record.id)

        // Search by text should still find it
        let byText = try store.fetchRecords(searchText: uniqueText)
        XCTAssertEqual(byText.count, 1)

        // Cleanup
        try store.deleteRecord(record)
    }
}
