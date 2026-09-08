import SwiftData
import SwiftUI

@main
@MainActor
struct KeaApp: App {
    private let persistence: PersistenceController
    @State private var state: AppState

    init() {
        let persistence = PersistenceController.make()
        self.persistence = persistence
        _state = State(initialValue: AppState(
            modelContext: persistence.container.mainContext,
            startupError: persistence.startupError
        ))
    }

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(state)
                .modelContainer(persistence.container)
                .preferredColorScheme(preferredColorScheme)
        }
        .defaultSize(width: 1180, height: 760)
        .windowResizability(.contentMinSize)
        .commands {
            AppCommands(state: state)
        }

        Settings {
            SettingsView()
                .environment(state)
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
