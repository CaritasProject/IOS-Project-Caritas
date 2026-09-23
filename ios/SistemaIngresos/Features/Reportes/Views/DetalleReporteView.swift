import SwiftUI

struct DetalleReporteView: View {
    var reporte: Reporte

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

                    BotonCompartirReporte(idReporte: reporte.id, destacado: false)
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
    }

    func montoEnPesos(_ monto: Double) -> String {
        return monto.formatted(.currency(code: "MXN").precision(.fractionLength(0)))
    }
}

#Preview {
    DetalleReporteView(reporte: reportesDeMuestra()[0])
        .background(Palette.fondo)
}
