import SwiftUI

struct TarjetaTelemarketing: View {
    let datos: Telemarketing

    var body: some View {
        TarjetaPanel(titulo: "Telemarketing") {
            VStack(spacing: 0) {
                renglon("Llamadas realizadas",
                        formatosResumen.entero(datos.llamadas),
                        color: paletaResumen.texto)
                Divider()
                renglon("Compromisos generados",
                        formatosResumen.entero(datos.compromisosGenerados),
                        color: paletaResumen.texto)
                Divider()
                renglon("Tasa de conversión",
                        "\(datos.tasaConversion.formatted(.number.precision(.fractionLength(1)))) %",
                        color: paletaResumen.turquesa)

                Spacer()
            }
        }
    }

    private func renglon(_ etiqueta: String, _ valor: String, color: Color) -> some View {
        HStack {
            Text(etiqueta)
                .font(.system(size: 15))
                .foregroundColor(paletaResumen.texto)

            Spacer()

            Text(valor)
                .font(.system(size: 20))
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(height: 44)
    }
}

#Preview {
    TarjetaTelemarketing(datos: Telemarketing(llamadas: 4820, compromisosGenerados: 612,
                                              tasaConversion: 12.7))
        .frame(width: 340)
        .padding()
        .background(paletaResumen.fondo)
}
