import SwiftUI

struct BarraSuperior: View {
    var titulo: String
    var mostrarPeriodo: Bool
    @Binding var periodoSeleccionado: Int

    var body: some View {
        HStack {
            Text(titulo)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Palette.texto)

            Spacer()

            if mostrarPeriodo {
                Picker(selection: $periodoSeleccionado, label: Text("Periodo")) {
                    Text("Día").tag(0)
                    Text("Semana").tag(1)
                    Text("Mes").tag(2)
                    Text("Trimestre").tag(3)
                    Text("Año").tag(4)
                }
                .pickerStyle(.segmented)
                .frame(width: 450)

                Spacer()
            }

            AvatarUsuario()
        }
        .padding(.horizontal, 24)
        .frame(height: 64)
        .frame(maxWidth: .infinity)
        .background(Palette.superficie)
    }
}

#Preview {
    VStack(spacing: 20) {
        BarraSuperior(titulo: "Resumen",
                      mostrarPeriodo: true,
                      periodoSeleccionado: .constant(2))

        BarraSuperior(titulo: "Reportes",
                      mostrarPeriodo: false,
                      periodoSeleccionado: .constant(0))
    }
    .background(Palette.fondo)
    .environmentObject(SesionService())
}
