import SwiftUI

struct DetalleReporteView: View {
    var reporte: Reporte

    @State private var mostrarCompartir = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(reporte.nombre)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Generado el \(reporte.fecha) · \(reporte.meta)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        mostrarCompartir.toggle()
                    } label: {
                        Label("Compartir", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                HStack(spacing: 0) {
                    TarjetaDatoReporte(valor: montoEnPesos(reporte.comprometido),
                                       etiqueta: "Comprometido",
                                       resaltado: false)
                    Divider()
                    TarjetaDatoReporte(valor: montoEnPesos(reporte.cobrado),
                                       etiqueta: "Cobrado",
                                       resaltado: true)
                    Divider()
                    TarjetaDatoReporte(valor: reporte.tipo,
                                       etiqueta: "Tipo",
                                       resaltado: false)
                }
                .background(Palette.superficie)
                .cornerRadius(14)

                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 44))
                        .foregroundColor(.gray)

                    Text("Vista previa del documento")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(14)

                Spacer()
            }
            .padding(28)
        }
        .alert("Compartir todavía no está disponible", isPresented: $mostrarCompartir) {
            Button("OK") {}
        } message: {
            Text("El archivo se podrá compartir cuando la API entregue el documento generado.")
        }
    }

    func montoEnPesos(_ monto: Double) -> String {
        return monto.formatted(.currency(code: "MXN").precision(.fractionLength(0)))
    }
}

#Preview {
    DetalleReporteView(reporte: reportesDeMuestra()[0])
        .background(Palette.fondo)
}
