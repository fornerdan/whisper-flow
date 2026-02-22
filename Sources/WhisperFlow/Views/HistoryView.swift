import SwiftUI
import WhisperCore

struct HistoryView: View {
    @State private var searchText = ""
    @State private var favoritesOnly = false
    @State private var records: [TranscriptionRecord] = []
    @State private var selectedRecord: TranscriptionRecord?
    @State private var recordToRename: TranscriptionRecord?
    @State private var renameText = ""

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Filter bar
                HStack {
                    Toggle(isOn: $favoritesOnly) {
                        Image(systemName: favoritesOnly ? "star.fill" : "star")
                    }
                    .toggleStyle(.button)
                    .help("Show favorites only")

                    Spacer()

                    Text("\(records.count) transcriptions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // Record list
                List(records, selection: $selectedRecord) { record in
                    HistoryRow(record: record)
                        .tag(record)
                        .contextMenu {
                            Button("Copy Text") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(record.text, forType: .string)
                            }

                            ShareLink(item: record.text) {
                                Label("Share…", systemImage: "square.and.arrow.up")
                            }

                            Divider()

                            Button("Rename…") {
                                renameText = record.title ?? ""
                                recordToRename = record
                            }

                            Button(record.isFavorite ? "Unfavorite" : "Favorite") {
                                toggleFavorite(record)
                            }

                            Divider()

                            Button("Delete", role: .destructive) {
                                deleteRecord(record)
                            }
                        }
                }
            }
            .searchable(text: $searchText, prompt: "Search transcriptions")
            .onChange(of: searchText) { _, _ in refreshRecords() }
            .onChange(of: favoritesOnly) { _, _ in refreshRecords() }
        } detail: {
            if let record = selectedRecord {
                HistoryDetailView(record: record) {
                    refreshRecords()
                }
            } else {
                ContentUnavailableView(
                    "Select a Transcription",
                    systemImage: "text.bubble",
                    description: Text("Choose a transcription from the list to view details")
                )
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear { refreshRecords() }
        .navigationTitle("Transcription History")
        .alert("Rename Transcription", isPresented: Binding(
            get: { recordToRename != nil },
            set: { if !$0 { recordToRename = nil } }
        )) {
            TextField("Title", text: $renameText)
            Button("Cancel", role: .cancel) { recordToRename = nil }
            Button("Save") {
                if let record = recordToRename {
                    renameRecord(record, title: renameText)
                }
                recordToRename = nil
            }
        } message: {
            Text("Enter a custom title for this transcription. Leave empty to use the original text.")
        }
    }

    private func refreshRecords() {
        do {
            records = try DataStore.shared.fetchRecords(
                searchText: searchText,
                favoritesOnly: favoritesOnly
            )
        } catch {
            print("Failed to fetch records: \(error)")
        }
    }

    private func toggleFavorite(_ record: TranscriptionRecord) {
        try? DataStore.shared.toggleFavorite(record)
        refreshRecords()
    }

    private func deleteRecord(_ record: TranscriptionRecord) {
        if selectedRecord == record {
            selectedRecord = nil
        }
        try? DataStore.shared.deleteRecord(record)
        refreshRecords()
    }

    private func renameRecord(_ record: TranscriptionRecord, title: String) {
        try? DataStore.shared.renameRecord(record, title: title)
        refreshRecords()
    }
}

// MARK: - Row

struct HistoryRow: View {
    let record: TranscriptionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if record.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }

                Text(record.displayTitle)
                    .lineLimit(1)
                    .font(.body)

                Spacer()
            }

            if record.title != nil && !record.title!.isEmpty {
                Text(record.text.prefix(while: { $0 != "\n" && $0 != "\r" }).prefix(80))
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Text(record.createdAt, style: .relative)
                Text(formatDuration(record.duration))

                if let app = record.sourceApp {
                    Text(app)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remaining = seconds % 60
        return "\(minutes)m \(remaining)s"
    }
}

// MARK: - Detail

struct HistoryDetailView: View {
    let record: TranscriptionRecord
    var onRename: () -> Void

    @State private var renameText = ""
    @State private var showRenameAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let title = record.title, !title.isEmpty {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                // Metadata
                HStack(spacing: 16) {
                    Label(record.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    Label(formatDuration(record.duration), systemImage: "timer")
                    Label(record.language.uppercased(), systemImage: "globe")
                    Label(record.modelUsed, systemImage: "cpu")

                    if let app = record.sourceApp {
                        Label(app, systemImage: "app")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Divider()

                // Full text
                Text(record.text)
                    .font(.body)
                    .textSelection(.enabled)

                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ShareLink(item: record.text) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(record.text, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                Button {
                    renameText = record.title ?? ""
                    showRenameAlert = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
            }
        }
        .alert("Rename Transcription", isPresented: $showRenameAlert) {
            TextField("Title", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                try? DataStore.shared.renameRecord(record, title: renameText)
                onRename()
            }
        } message: {
            Text("Enter a custom title. Leave empty to use the original text.")
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remaining = seconds % 60
        return "\(minutes)m \(remaining)s"
    }
}
