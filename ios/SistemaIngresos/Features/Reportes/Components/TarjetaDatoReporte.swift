import SwiftUI

struct TarjetaDatoReporte: View {
    var valor: String
    var etiqueta: String
    var resaltado: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(valor)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(resaltado ? Palette.turquesa : .primary)

            Text(etiqueta)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

#Preview {
    HStack(spacing: 0) {
        TarjetaDatoReporte(valor: "$540,000", etiqueta: "Comprometido", resaltado: false)
        Divider()
        TarjetaDatoReporte(valor: "$418,900", etiqueta: "Cobrado", resaltado: true)
        Divider()
        TarjetaDatoReporte(valor: "Cobranza", etiqueta: "Tipo", resaltado: false)
    }
    .background(Palette.superficie)
    .cornerRadius(14)
    .padding()
    .background(Palette.fondo)
}
