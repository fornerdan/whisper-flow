import SwiftUI
import WhisperCore

enum ExportScope: String, CaseIterable, Identifiable {
    case all = "All Transcriptions"
    case favorites = "Favorites Only"
    case dateRange = "Date Range"

    var id: String { rawValue }
}

@MainActor
struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var format: ExportFormat = .plainText
    @State private var scope: ExportScope = .all
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var isExporting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Export Transcriptions")
                .font(.headline)

            Form {
                Picker("Format", selection: $format) {
                    ForEach(ExportFormat.allCases) { fmt in
                        Text(fmt.rawValue).tag(fmt)
                    }
                }

                Picker("Scope", selection: $scope) {
                    ForEach(ExportScope.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }

                if scope == .dateRange {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                }
            }
            .formStyle(.grouped)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Export...") { performExport() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(isExporting)
            }
        }
        .padding()
        .frame(width: 380)
    }

    private func performExport() {
        isExporting = true
        errorMessage = nil

        do {
            var records = try DataStore.shared.fetchRecords(
                favoritesOnly: scope == .favorites
            )

            if scope == .dateRange {
                let startOfDay = Calendar.current.startOfDay(for: startDate)
                let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
                records = records.filter { $0.createdAt >= startOfDay && $0.createdAt <= endOfDay }
            }

            let data = HistoryExporter.export(records: records, format: format)

            let savePanel = NSSavePanel()
            savePanel.title = "Export Transcriptions"
            savePanel.nameFieldStringValue = "transcriptions.\(format.fileExtension)"
            savePanel.allowedContentTypes = [.data]

            guard savePanel.runModal() == .OK, let url = savePanel.url else {
                isExporting = false
                return
            }

            try data.write(to: url, options: .atomic)
            isExporting = false
            dismiss()

        } catch {
            errorMessage = error.localizedDescription
            isExporting = false
        }
    }
}
