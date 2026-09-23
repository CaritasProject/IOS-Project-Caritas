import SwiftUI

struct TarjetaPanel<Contenido: View>: View {
    let titulo: String
    var mostrarFlecha: Bool = false
    @ViewBuilder let contenido: () -> Contenido

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(titulo)
                    .font(.headline)
                    .foregroundColor(paletaResumen.texto)

                Spacer()

                if mostrarFlecha {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15))
                        .foregroundColor(paletaResumen.textoSecundario)
                }
            }

            contenido()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(paletaResumen.superficie)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TarjetaPanel(titulo: "Ingresos del periodo") {
        Text("Contenido de la tarjeta")
    }
    .padding()
    .background(paletaResumen.fondo)
}
