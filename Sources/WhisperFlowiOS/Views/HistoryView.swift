import SwiftUI
import WhisperCore

struct HistoryView: View {
    @State private var records: [TranscriptionRecord] = []
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var recordToRename: TranscriptionRecord?
    @State private var renameText = ""

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
                            NavigationLink(value: record) {
                                HistoryRow(record: record)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    Task { @MainActor in
                                        try? DataStore.shared.toggleFavorite(record)
                                        loadRecords()
                                    }
                                } label: {
                                    Image(systemName: record.isFavorite ? "star.slash" : "star.fill")
                                }
                                .tint(.yellow)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { @MainActor in
                                        try? DataStore.shared.deleteRecord(record)
                                        loadRecords()
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    UIPasteboard.general.string = record.text
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = record.text
                                } label: {
                                    Label("Copy Text", systemImage: "doc.on.doc")
                                }

                                ShareLink(item: record.text) {
                                    Label("Share…", systemImage: "square.and.arrow.up")
                                }

                                Divider()

                                Button {
                                    renameText = record.title ?? ""
                                    recordToRename = record
                                } label: {
                                    Label("Rename…", systemImage: "pencil")
                                }

                                Button {
                                    Task { @MainActor in
                                        try? DataStore.shared.toggleFavorite(record)
                                        loadRecords()
                                    }
                                } label: {
                                    Label(
                                        record.isFavorite ? "Unfavorite" : "Favorite",
                                        systemImage: record.isFavorite ? "star.slash" : "star.fill"
                                    )
                                }

                                Divider()

                                Button(role: .destructive) {
                                    Task { @MainActor in
                                        try? DataStore.shared.deleteRecord(record)
                                        loadRecords()
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
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
            .navigationDestination(for: TranscriptionRecord.self) { record in
                HistoryDetailViewiOS(record: record) {
                    loadRecords()
                }
            }
            .alert("Rename Transcription", isPresented: Binding(
                get: { recordToRename != nil },
                set: { if !$0 { recordToRename = nil } }
            )) {
                TextField("Title", text: $renameText)
                Button("Cancel", role: .cancel) { recordToRename = nil }
                Button("Save") {
                    if let record = recordToRename {
                        try? DataStore.shared.renameRecord(record, title: renameText)
                        loadRecords()
                    }
                    recordToRename = nil
                }
            } message: {
                Text("Enter a custom title. Leave empty to use the original text.")
            }
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
}

// MARK: - Row

struct HistoryRow: View {
    let record: TranscriptionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if record.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }

                Text(record.displayTitle)
                    .font(.body)
                    .lineLimit(1)
            }

            if record.title != nil && !record.title!.isEmpty {
                Text(record.text.prefix(while: { $0 != "\n" && $0 != "\r" }).prefix(80))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

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
    }
}

// MARK: - Detail

struct HistoryDetailViewiOS: View {
    let record: TranscriptionRecord
    var onUpdate: () -> Void

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
                VStack(alignment: .leading, spacing: 8) {
                    Label(record.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    HStack(spacing: 16) {
                        Label(formatDuration(record.duration), systemImage: "timer")
                        Label(record.language.uppercased(), systemImage: "globe")
                    }
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
            }
            .padding()
        }
        .navigationTitle(record.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: record.text) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button {
                    UIPasteboard.general.string = record.text
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
                onUpdate()
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
