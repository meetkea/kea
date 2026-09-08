import SwiftData
import SwiftUI

@main
@MainActor
struct KeaApp: App {
    private let persistence: PersistenceController
    @State private var state: AppState
    @State private var authentication = AuthenticationAccessService()

    init() {
        let persistence = PersistenceController.make()
        self.persistence = persistence
        _state = State(initialValue: AppState(
            modelContext: persistence.container.mainContext,
            startupError: persistence.startupError
        ))
    }

    var body: some Scene {
        Window("Kea", id: "main") {
            MainWindowView()
                .environment(state)
                .environment(authentication)
                .modelContainer(persistence.container)
                .preferredColorScheme(preferredColorScheme)
        }
        .defaultSize(width: 1180, height: 760)
        .windowResizability(.contentMinSize)
        .commands {
            AppCommands(state: state, authentication: authentication)
        }

        Settings {
            SettingsView()
                .environment(state)
                .environment(authentication)
                .modelContainer(persistence.container)
                .preferredColorScheme(preferredColorScheme)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch state.preferences.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
