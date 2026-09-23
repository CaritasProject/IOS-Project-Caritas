import SwiftUI

struct TarjetaIngresos: View {
    let comprometido: String
    let detalleComprometido: String
    let cobrado: String
    let detalleCobrado: String
    let porcentajeCobranza: Double

    var body: some View {
        TarjetaPanel(titulo: "Ingresos del periodo") {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 28) {
                    ColumnaMonto(etiqueta: "Comprometido",
                                 monto: comprometido,
                                 detalle: detalleComprometido,
                                 color: paletaResumen.separador)

                    ColumnaMonto(etiqueta: "Cobrado",
                                 monto: cobrado,
                                 detalle: detalleCobrado,
                                 color: paletaResumen.turquesa)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cobranza sobre lo comprometido")
                            .font(.system(size: 14))
                            .foregroundColor(paletaResumen.textoSecundario)

                        Spacer()

                        Text("\(porcentajeCobranza, specifier: "%.1f") %")
                            .font(.system(size: 14))
                            .foregroundColor(paletaResumen.textoSecundario)
                    }

                    ProgressView(value: porcentajeCobranza, total: 100)
                        .tint(paletaResumen.turquesa)
                        .scaleEffect(x: 1, y: 2)
                        .padding(.vertical, 3)
                }
            }
        }
    }
}

#Preview {
    TarjetaIngresos(comprometido: "$2,340,000",
                    detalleComprometido: "1,842 compromisos",
                    cobrado: "$1,812,400",
                    detalleCobrado: "1,394 cobros aplicados",
                    porcentajeCobranza: 77.5)
        .padding()
        .background(paletaResumen.fondo)
}
