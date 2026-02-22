import SwiftUI
import WhisperCore

// MARK: - Models

enum LauncherAction {
    case startRecording
    case stopRecording
    case cancelRecording
    case openSettings
    case openHistory
    case copyTranscription(TranscriptionRecord)
}

struct LauncherItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String?
    let action: LauncherAction
}

// MARK: - Launcher View

struct LauncherView: View {
    var onDismiss: () -> Void

    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    @ObservedObject private var engine = TranscriptionEngine.shared

    private var items: [LauncherItem] {
        var result: [LauncherItem] = []

        // When searching, prepend matching transcriptions
        if !query.isEmpty {
            let records = (try? DataStore.shared.fetchRecords(searchText: query, limit: 10)) ?? []
            result += records.map { record in
                LauncherItem(
                    icon: "doc.on.clipboard",
                    title: record.displayTitle,
                    subtitle: formatDate(record.createdAt),
                    action: .copyTranscription(record)
                )
            }
        }

        // Command items (always shown, filtered by query)
        let commands = buildCommands()
        if query.isEmpty {
            result += commands
        } else {
            result += commands.filter {
                $0.title.localizedCaseInsensitiveContains(query)
            }
        }

        return result
    }

    private func buildCommands() -> [LauncherItem] {
        var commands: [LauncherItem] = []

        switch engine.state {
        case .recording:
            commands.append(LauncherItem(
                icon: "stop.circle.fill",
                title: "Stop Recording",
                subtitle: "Finish recording and transcribe",
                action: .stopRecording
            ))
            commands.append(LauncherItem(
                icon: "xmark.circle",
                title: "Cancel Recording",
                subtitle: "Discard current recording",
                action: .cancelRecording
            ))
        case .idle, .done, .error:
            commands.append(LauncherItem(
                icon: "mic.fill",
                title: "Start Recording",
                subtitle: "Begin voice transcription",
                action: .startRecording
            ))
        default:
            break
        }

        commands.append(LauncherItem(
            icon: "gear",
            title: "Open Settings",
            subtitle: nil,
            action: .openSettings
        ))
        commands.append(LauncherItem(
            icon: "clock",
            title: "Open History",
            subtitle: nil,
            action: .openHistory
        ))

        return commands
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.title3)

                TextField("Search commands and transcriptions...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isSearchFocused)
                    .onSubmit { executeSelected() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Results list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            LauncherItemRow(item: item, isSelected: index == selectedIndex)
                                .id(item.id)
                                .onTapGesture {
                                    selectedIndex = index
                                    executeSelected()
                                }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                }
                .onChange(of: selectedIndex) { _, newIndex in
                    if let item = items[safe: newIndex] {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(item.id, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: 600, height: 400)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThickMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            isSearchFocused = true
            selectedIndex = 0
        }
        .onChange(of: query) { _, _ in
            selectedIndex = 0
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 { selectedIndex -= 1 }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < items.count - 1 { selectedIndex += 1 }
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
        .onKeyPress(.return) {
            executeSelected()
            return .handled
        }
    }

    private func executeSelected() {
        guard let item = items[safe: selectedIndex] else { return }
        executeAction(item.action)
    }

    private func executeAction(_ action: LauncherAction) {
        onDismiss()

        Task { @MainActor in
            switch action {
            case .startRecording:
                TranscriptionEngine.shared.toggleRecording()
            case .stopRecording:
                TranscriptionEngine.shared.stopRecordingAndTranscribe()
            case .cancelRecording:
                TranscriptionEngine.shared.cancelRecording()
            case .openSettings:
                AppDelegate.shared?.showSettings()
            case .openHistory:
                AppDelegate.shared?.showHistory()
            case .copyTranscription(let record):
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(record.text, forType: .string)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Item Row

private struct LauncherItemRow: View {
    let item: LauncherItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.body)
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Safe Collection Access

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
