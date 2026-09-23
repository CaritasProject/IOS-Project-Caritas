import SwiftUI

struct TarjetaMetas: View {
    let meta: MetaPeriodo

    var body: some View {
        TarjetaPanel(titulo: "Metas del periodo", mostrarFlecha: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("\(Int(meta.porcentaje)) %")
                    .font(.system(size: 40))
                    .fontWeight(.bold)
                    .foregroundColor(paletaResumen.texto)

                ProgressView(value: meta.porcentaje, total: 100)
                    .tint(paletaResumen.turquesa)
                    .scaleEffect(x: 1, y: 2)
                    .padding(.vertical, 3)

                Text("\(formatosResumen.moneda(meta.cobrado)) de \(formatosResumen.moneda(meta.montoMeta))")
                    .font(.system(size: 14))
                    .foregroundColor(paletaResumen.textoSecundario)

                Spacer()
            }
        }
    }
}

#Preview {
    TarjetaMetas(meta: MetaPeriodo(montoMeta: 2400000, cobrado: 1812400, porcentaje: 76))
        .frame(width: 340)
        .padding()
        .background(paletaResumen.fondo)
}
