import Foundation
import SwiftUI
import ServiceManagement

final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    // MARK: - Model

    @AppStorage("selectedModel") var selectedModel: String = "tiny"

    // MARK: - Transcription

    @AppStorage("language") var language: String = "auto"
    @AppStorage("translateToEnglish") var translateToEnglish: Bool = false
    @AppStorage("autoInjectText") var autoInjectText: Bool = true
    @AppStorage("copyToClipboard") var copyToClipboard: Bool = true

    // MARK: - History

    @AppStorage("historyRetentionDays") var historyRetentionDays: Int = 0  // 0 = keep forever

    // MARK: - Audio Input (macOS)

    @AppStorage("preferredMicDeviceUID") var preferredMicDeviceUID: String = ""  // empty = system default

    // MARK: - UI

    @AppStorage("showOverlayHUD") var showOverlayHUD: Bool = true
    @AppStorage("playSound") var playSound: Bool = true
    @AppStorage("showInDock") var showInDock: Bool = false
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet {
            updateLoginItem()
        }
    }

    // MARK: - Hotkey Display

    var hotkeyDisplayString: String {
        // KeyboardShortcuts handles the actual key binding.
        // This is just for display in the menu bar.
        return "\u{2318}\u{21E7}Space"
    }

    var launcherHotkeyDisplayString: String {
        return "\u{2318}\u{21E7}W"
    }

    // MARK: - Launch at Login

    private func updateLoginItem() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update login item: \(error)")
        }
    }

    // MARK: - Language Options

    static let supportedLanguages: [(code: String, name: String)] = [
        ("auto", "Auto-detect"),
        ("en", "English"),
        ("zh", "Chinese"),
        ("de", "German"),
        ("es", "Spanish"),
        ("ru", "Russian"),
        ("ko", "Korean"),
        ("fr", "French"),
        ("ja", "Japanese"),
        ("pt", "Portuguese"),
        ("tr", "Turkish"),
        ("pl", "Polish"),
        ("ca", "Catalan"),
        ("nl", "Dutch"),
        ("ar", "Arabic"),
        ("sv", "Swedish"),
        ("it", "Italian"),
        ("id", "Indonesian"),
        ("hi", "Hindi"),
        ("fi", "Finnish"),
        ("vi", "Vietnamese"),
        ("he", "Hebrew"),
        ("uk", "Ukrainian"),
        ("el", "Greek"),
        ("ms", "Malay"),
        ("cs", "Czech"),
        ("ro", "Romanian"),
        ("da", "Danish"),
        ("hu", "Hungarian"),
        ("ta", "Tamil"),
        ("no", "Norwegian"),
        ("th", "Thai"),
        ("ur", "Urdu"),
        ("hr", "Croatian"),
        ("bg", "Bulgarian"),
        ("lt", "Lithuanian"),
        ("la", "Latin"),
        ("mi", "Maori"),
        ("ml", "Malayalam"),
        ("cy", "Welsh"),
        ("sk", "Slovak"),
        ("te", "Telugu"),
        ("fa", "Persian"),
        ("lv", "Latvian"),
        ("bn", "Bengali"),
        ("sr", "Serbian"),
        ("az", "Azerbaijani"),
        ("sl", "Slovenian"),
        ("kn", "Kannada"),
        ("et", "Estonian"),
        ("mk", "Macedonian"),
        ("br", "Breton"),
        ("eu", "Basque"),
        ("is", "Icelandic"),
        ("hy", "Armenian"),
        ("ne", "Nepali"),
        ("mn", "Mongolian"),
        ("bs", "Bosnian"),
        ("kk", "Kazakh"),
        ("sq", "Albanian"),
        ("sw", "Swahili"),
        ("gl", "Galician"),
        ("mr", "Marathi"),
        ("pa", "Punjabi"),
        ("si", "Sinhala"),
        ("km", "Khmer"),
        ("sn", "Shona"),
        ("yo", "Yoruba"),
        ("so", "Somali"),
        ("af", "Afrikaans"),
        ("oc", "Occitan"),
        ("ka", "Georgian"),
        ("be", "Belarusian"),
        ("tg", "Tajik"),
        ("sd", "Sindhi"),
        ("gu", "Gujarati"),
        ("am", "Amharic"),
        ("yi", "Yiddish"),
        ("lo", "Lao"),
        ("uz", "Uzbek"),
        ("fo", "Faroese"),
        ("ht", "Haitian Creole"),
        ("ps", "Pashto"),
        ("tk", "Turkmen"),
        ("nn", "Nynorsk"),
        ("mt", "Maltese"),
        ("sa", "Sanskrit"),
        ("lb", "Luxembourgish"),
        ("my", "Myanmar"),
        ("bo", "Tibetan"),
        ("tl", "Tagalog"),
        ("mg", "Malagasy"),
        ("as", "Assamese"),
        ("tt", "Tatar"),
        ("haw", "Hawaiian"),
        ("ln", "Lingala"),
        ("ha", "Hausa"),
        ("ba", "Bashkir"),
        ("jw", "Javanese"),
        ("su", "Sundanese")
    ]

    private init() {}
}
