import SwiftUI

@main
struct SistemaIngresosApp: App {
    @StateObject private var sesion = SesionService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sesion)
        }
    }
}
