import SwiftUI

struct TarjetaIngresos: View {
    let ingresos: IngresosPeriodo

    var body: some View {
        TarjetaPanel(titulo: "Ingresos del periodo") {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 28) {
                    ColumnaMonto(etiqueta: "Comprometido",
                                 monto: formatosResumen.moneda(ingresos.comprometido),
                                 detalle: "\(formatosResumen.entero(ingresos.compromisos)) compromisos",
                                 color: paletaResumen.separador)

                    ColumnaMonto(etiqueta: "Cobrado",
                                 monto: formatosResumen.moneda(ingresos.cobrado),
                                 detalle: "\(formatosResumen.entero(ingresos.cobrosAplicados)) cobros aplicados",
                                 color: paletaResumen.turquesa)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cobranza sobre lo comprometido")
                            .font(.system(size: 14))
                            .foregroundColor(paletaResumen.textoSecundario)

                        Spacer()

                        Text("\(ingresos.porcentajeCobranza, specifier: "%.1f") %")
                            .font(.system(size: 14))
                            .foregroundColor(paletaResumen.textoSecundario)
                    }

                    ProgressView(value: ingresos.porcentajeCobranza, total: 100)
                        .tint(paletaResumen.turquesa)
                        .scaleEffect(x: 1, y: 2)
                        .padding(.vertical, 3)
                }
            }
        }
    }
}

#Preview {
    TarjetaIngresos(ingresos: IngresosPeriodo(comprometido: 2340000, compromisos: 1842,
                                              cobrado: 1812400, cobrosAplicados: 1394,
                                              porcentajeCobranza: 77.5))
        .padding()
        .background(paletaResumen.fondo)
}
