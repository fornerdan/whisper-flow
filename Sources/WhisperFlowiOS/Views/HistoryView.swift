import SwiftUI
import WhisperCore

struct HistoryView: View {
    @State private var records: [TranscriptionRecord] = []
    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No Transcriptions",
                        systemImage: "waveform.slash",
                        description: Text("Your transcription history will appear here.")
                    )
                } else {
                    List {
                        ForEach(records) { record in
                            HistoryRow(record: record) {
                                loadRecords()
                            }
                        }
                        .onDelete(perform: deleteRecords)
                    }
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                    }
                }
            }
            .onChange(of: searchText) { _, _ in loadRecords() }
            .onChange(of: showFavoritesOnly) { _, _ in loadRecords() }
            .onAppear { loadRecords() }
        }
    }

    private func loadRecords() {
        Task { @MainActor in
            records = (try? DataStore.shared.fetchRecords(
                searchText: searchText,
                favoritesOnly: showFavoritesOnly
            )) ?? []
        }
    }

    private func deleteRecords(at offsets: IndexSet) {
        Task { @MainActor in
            for index in offsets {
                try? DataStore.shared.deleteRecord(records[index])
            }
            loadRecords()
        }
    }
}

struct HistoryRow: View {
    let record: TranscriptionRecord
    let onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(record.text)
                .font(.body)
                .lineLimit(3)

            HStack {
                Text(record.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let app = record.sourceApp {
                    Text(app)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(record.language.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(String(format: "%.1fs", record.duration))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .leading) {
            Button {
                Task { @MainActor in
                    try? DataStore.shared.toggleFavorite(record)
                    onUpdate()
                }
            } label: {
                Image(systemName: record.isFavorite ? "star.slash" : "star.fill")
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing) {
            Button {
                UIPasteboard.general.string = record.text
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .tint(.blue)
        }
    }
}
