import SwiftUI

struct TarjetaMetas: View {
    let porcentaje: Double
    let detalle: String

    var body: some View {
        TarjetaPanel(titulo: "Metas del periodo", mostrarFlecha: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("\(Int(porcentaje)) %")
                    .font(.system(size: 40))
                    .fontWeight(.bold)
                    .foregroundColor(paletaResumen.texto)

                ProgressView(value: porcentaje, total: 100)
                    .tint(paletaResumen.turquesa)
                    .scaleEffect(x: 1, y: 2)
                    .padding(.vertical, 3)

                Text(detalle)
                    .font(.system(size: 14))
                    .foregroundColor(paletaResumen.textoSecundario)

                Spacer()
            }
        }
    }
}

#Preview {
    TarjetaMetas(porcentaje: 76, detalle: "$1,812,400 de $2,400,000")
        .frame(width: 340)
        .padding()
        .background(paletaResumen.fondo)
}
