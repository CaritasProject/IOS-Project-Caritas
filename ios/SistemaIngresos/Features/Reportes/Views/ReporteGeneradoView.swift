import SwiftUI

struct ReporteGeneradoView: View {
    var reporte: Reporte

    @Binding var mostrandoConfigurar: Bool
    @Binding var mostrandoGenerado: Bool

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundColor(Palette.turquesa)
                .frame(width: 110, height: 110)
                .background(Palette.turquesa.opacity(0.15))
                .clipShape(.circle)

            Text("Reporte generado")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("\(reporte.nombre) · \(reporte.formato). Ya está disponible en la biblioteca de reportes.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)

            HStack(spacing: 14) {
                BotonCompartirReporte(reporte: reporte, destacado: true)

                Button {
                    mostrandoGenerado = false
                } label: {
                    Text("Volver a Reportes")
                        .font(.title3)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    mostrandoGenerado = false
                    mostrandoConfigurar = true
                } label: {
                    Text("Generar otro")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Palette.turquesa)
                        .padding(.vertical, 12)
                }
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}

#Preview {
    ReporteGeneradoView(reporte: reportesDeMuestra()[0],
                        mostrandoConfigurar: .constant(false),
                        mostrandoGenerado: .constant(true))
        .background(Palette.fondo)
}
