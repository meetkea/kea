import Foundation
import SwiftData

struct PersistenceController {
    let container: ModelContainer
    let startupError: String?

    @MainActor
    static func make() -> PersistenceController {
        let schema = Schema([AccountProfile.self])

        do {
            let configuration = ModelConfiguration("Kea", schema: schema)
            return PersistenceController(
                container: try ModelContainer(for: schema, configurations: [configuration]),
                startupError: nil
            )
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return PersistenceController(
                    container: try ModelContainer(for: schema, configurations: [fallback]),
                    startupError: "Kea could not open its local account database. Changes made in this session will not be saved."
                )
            } catch {
                fatalError("Unable to create a SwiftData container: \(error.localizedDescription)")
            }
        }
    }
}
