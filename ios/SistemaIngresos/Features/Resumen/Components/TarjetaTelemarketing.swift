import SwiftUI

struct TarjetaTelemarketing: View {
    let llamadas: String
    let compromisos: String
    let conversion: String

    var body: some View {
        TarjetaPanel(titulo: "Telemarketing") {
            VStack(spacing: 0) {
                renglon("Llamadas realizadas", llamadas, color: paletaResumen.texto)
                Divider()
                renglon("Compromisos generados", compromisos, color: paletaResumen.texto)
                Divider()
                renglon("Tasa de conversión", conversion, color: paletaResumen.turquesa)

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
    TarjetaTelemarketing(llamadas: "4,820",
                         compromisos: "612",
                         conversion: "12.7 %")
        .frame(width: 340)
        .padding()
        .background(paletaResumen.fondo)
}
