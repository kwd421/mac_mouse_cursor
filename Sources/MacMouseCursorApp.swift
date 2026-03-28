import SwiftUI

@main
struct CapeForgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var localization = LocalizationController.shared

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandMenu("Language") {
                ForEach(AppLanguage.allCases) { language in
                    Button(Localized.string(language.titleKey)) {
                        languageBinding.wrappedValue = language
                    }
                    .disabled(languageBinding.wrappedValue == language)
                }
            }
        }
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { localization.selectedLanguage ?? inferredInitialLanguage },
            set: { newValue in
                localization.setLanguage(newValue)
                appDelegate.controller.relocalize()
            }
        )
    }

    private var inferredInitialLanguage: AppLanguage {
        Localized.inferredLanguage(from: Locale.preferredLanguages.first)
    }
}
