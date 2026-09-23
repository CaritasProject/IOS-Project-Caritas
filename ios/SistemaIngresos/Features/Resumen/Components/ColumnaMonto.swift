import SwiftUI

struct ColumnaMonto: View {
    let etiqueta: String
    let monto: String
    let detalle: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(color)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(etiqueta)
                    .font(.system(size: 14))
                    .foregroundColor(color == paletaResumen.turquesa ? paletaResumen.turquesa : paletaResumen.textoSecundario)

                Text(monto)
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(color == paletaResumen.turquesa ? paletaResumen.turquesa : paletaResumen.texto)

                Text(detalle)
                    .font(.system(size: 13))
                    .foregroundColor(paletaResumen.textoSecundario)
            }

            Spacer()
        }
        .frame(height: 96)
    }
}

#Preview {
    ColumnaMonto(etiqueta: "Comprometido",
                 monto: "$2,340,000",
                 detalle: "1,842 compromisos",
                 color: paletaResumen.separador)
        .padding()
}
