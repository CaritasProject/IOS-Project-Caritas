import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sesion: SesionService

    @State private var seccionSeleccionada: Int = 0

    var body: some View {
        if sesion.sesionIniciada {
            principal
        } else {
            LoginView()
        }
    }

    private var principal: some View {
        HStack(spacing: 0) {
            BarraLateral(seccionSeleccionada: $seccionSeleccionada)

            Rectangle()
                .fill(Palette.separador)
                .frame(width: 1)

            pantalla
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Palette.fondo.ignoresSafeArea())
    }

    @ViewBuilder
    private var pantalla: some View {
        switch seccionSeleccionada {
        case 1:
            DonantesView()
        case 2:
            ReportesView()
        case 3:
            MetasView()
        default:
            ResumenView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SesionService())
}
