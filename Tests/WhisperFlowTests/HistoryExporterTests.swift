import XCTest
@testable import WhisperCore

final class HistoryExporterTests: XCTestCase {

    // MARK: - Helpers

    private func makeRecord(
        text: String = "Hello world",
        language: String = "en",
        duration: TimeInterval = 5.0,
        sourceApp: String? = nil,
        sourceFile: String? = nil,
        title: String? = nil
    ) -> TranscriptionRecord {
        TranscriptionRecord(
            text: text,
            language: language,
            duration: duration,
            modelUsed: "tiny",
            createdAt: Date(timeIntervalSince1970: 1700000000),
            sourceApp: sourceApp,
            sourceFile: sourceFile,
            title: title
        )
    }

    // MARK: - Export Formats

    func testExportFormatFileExtensions() {
        XCTAssertEqual(ExportFormat.plainText.fileExtension, "txt")
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
    }

    func testExportFormatAllCases() {
        XCTAssertEqual(ExportFormat.allCases.count, 3)
    }

    // MARK: - Plain Text

    func testPlainTextExportContainsText() {
        let records = [makeRecord(text: "Test transcription")]
        let data = HistoryExporter.export(records: records, format: .plainText)
        let output = String(data: data, encoding: .utf8)!

        XCTAssertTrue(output.contains("Test transcription"))
        XCTAssertTrue(output.contains("Language: en"))
        XCTAssertTrue(output.contains("Model: tiny"))
    }

    func testPlainTextExportEmptyRecords() {
        let data = HistoryExporter.export(records: [], format: .plainText)
        let output = String(data: data, encoding: .utf8)!

        XCTAssertEqual(output, "No transcriptions.\n")
    }

    func testPlainTextExportIncludesSourceFile() {
        let records = [makeRecord(text: "From file", sourceFile: "meeting.wav")]
        let data = HistoryExporter.export(records: records, format: .plainText)
        let output = String(data: data, encoding: .utf8)!

        XCTAssertTrue(output.contains("Source File: meeting.wav"))
    }

    // MARK: - JSON

    func testJSONExportIsValidJSON() throws {
        let records = [makeRecord(text: "JSON test")]
        let data = HistoryExporter.export(records: records, format: .json)

        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.count, 1)
        XCTAssertEqual(parsed?.first?["text"] as? String, "JSON test")
    }

    func testJSONExportEmptyRecords() throws {
        let data = HistoryExporter.export(records: [], format: .json)
        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.count, 0)
    }

    // MARK: - CSV

    func testCSVExportHasHeader() {
        let records = [makeRecord()]
        let data = HistoryExporter.export(records: records, format: .csv)
        let output = String(data: data, encoding: .utf8)!
        let lines = output.components(separatedBy: "\n")

        XCTAssertTrue(lines[0].contains("Date,Language,Duration,Model"))
        XCTAssertEqual(lines.count, 2) // header + 1 record
    }

    func testCSVExportEmptyRecords() {
        let data = HistoryExporter.export(records: [], format: .csv)
        let output = String(data: data, encoding: .utf8)!
        let lines = output.components(separatedBy: "\n")

        XCTAssertEqual(lines.count, 1) // header only
    }

    func testCSVEscapesCommasInText() {
        let records = [makeRecord(text: "Hello, world")]
        let data = HistoryExporter.export(records: records, format: .csv)
        let output = String(data: data, encoding: .utf8)!

        // Text containing comma should be quoted
        XCTAssertTrue(output.contains("\"Hello, world\""))
    }

    func testCSVEscapesQuotesInText() {
        let records = [makeRecord(text: "He said \"hello\"")]
        let data = HistoryExporter.export(records: records, format: .csv)
        let output = String(data: data, encoding: .utf8)!

        // Quotes should be doubled and the field quoted
        XCTAssertTrue(output.contains("\"He said \"\"hello\"\"\""))
    }

    func testCSVEscapesNewlinesInText() {
        let records = [makeRecord(text: "Line 1\nLine 2")]
        let data = HistoryExporter.export(records: records, format: .csv)
        let output = String(data: data, encoding: .utf8)!

        XCTAssertTrue(output.contains("\"Line 1\nLine 2\""))
    }

    // MARK: - CSV Escape Helper

    func testCsvEscapeNoSpecialChars() {
        XCTAssertEqual(HistoryExporter.csvEscape("hello"), "hello")
    }

    func testCsvEscapeWithComma() {
        XCTAssertEqual(HistoryExporter.csvEscape("a,b"), "\"a,b\"")
    }

    func testCsvEscapeWithQuotes() {
        XCTAssertEqual(HistoryExporter.csvEscape("say \"hi\""), "\"say \"\"hi\"\"\"")
    }
}
