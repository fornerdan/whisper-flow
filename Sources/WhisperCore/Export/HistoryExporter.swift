import Foundation

public enum ExportFormat: String, CaseIterable, Identifiable {
    case plainText = "Plain Text"
    case json = "JSON"
    case csv = "CSV"

    public var id: String { rawValue }

    public var fileExtension: String {
        switch self {
        case .plainText: return "txt"
        case .json: return "json"
        case .csv: return "csv"
        }
    }
}

public final class HistoryExporter {

    public static func export(records: [TranscriptionRecord], format: ExportFormat) -> Data {
        switch format {
        case .plainText:
            return exportPlainText(records)
        case .json:
            return exportJSON(records)
        case .csv:
            return exportCSV(records)
        }
    }

    // MARK: - Plain Text

    private static func exportPlainText(_ records: [TranscriptionRecord]) -> Data {
        guard !records.isEmpty else {
            return Data("No transcriptions.\n".utf8)
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var output = ""
        for (index, record) in records.enumerated() {
            if index > 0 { output += "\n---\n\n" }
            output += "Date: \(formatter.string(from: record.createdAt))\n"
            output += "Language: \(record.language)\n"
            output += "Duration: \(formatDuration(record.duration))\n"
            output += "Model: \(record.modelUsed)\n"
            if let app = record.sourceApp {
                output += "Source App: \(app)\n"
            }
            if let file = record.sourceFile {
                output += "Source File: \(file)\n"
            }
            if let title = record.title, !title.isEmpty {
                output += "Title: \(title)\n"
            }
            output += "\n\(record.text)\n"
        }

        return Data(output.utf8)
    }

    // MARK: - JSON

    private static func exportJSON(_ records: [TranscriptionRecord]) -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        // Use the Codable conformance directly
        return (try? encoder.encode(records)) ?? Data("[]".utf8)
    }

    // MARK: - CSV

    private static func exportCSV(_ records: [TranscriptionRecord]) -> Data {
        var rows: [String] = []
        rows.append("Date,Language,Duration,Model,Source App,Source File,Title,Favorite,Text")

        for record in records {
            let formatter = ISO8601DateFormatter()
            let date = formatter.string(from: record.createdAt)
            let row = [
                date,
                record.language,
                formatDuration(record.duration),
                record.modelUsed,
                record.sourceApp ?? "",
                record.sourceFile ?? "",
                record.title ?? "",
                record.isFavorite ? "Yes" : "No",
                record.text
            ].map { csvEscape($0) }.joined(separator: ",")
            rows.append(row)
        }

        return Data(rows.joined(separator: "\n").utf8)
    }

    // MARK: - Helpers

    static func csvEscape(_ value: String) -> String {
        let needsQuoting = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
        if needsQuoting {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    private static func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remaining = seconds % 60
        return "\(minutes)m \(remaining)s"
    }
}
