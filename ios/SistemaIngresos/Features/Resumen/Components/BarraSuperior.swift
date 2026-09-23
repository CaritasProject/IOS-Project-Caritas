import SwiftUI

struct BarraSuperior: View {
    let titulo: String
    let iniciales: String
    @Binding var periodoSeleccionado: Int

    var body: some View {
        HStack(spacing: 0) {
            Text(titulo)
                .font(.system(size: 17))
                .fontWeight(.semibold)
                .foregroundColor(paletaResumen.texto)

            Spacer()

            SelectorPeriodo(periodoSeleccionado: $periodoSeleccionado)

            Spacer()

            Text(iniciales)
                .font(.system(size: 14))
                .fontWeight(.semibold)
                .foregroundColor(paletaResumen.superficie)
                .frame(width: 38, height: 38)
                .background(paletaResumen.turquesa)
                .clipShape(.circle)
        }
        .padding(.horizontal, 24)
        .frame(height: 64)
        .frame(maxWidth: .infinity)
        .background(paletaResumen.superficie)
    }
}

#Preview {
    BarraSuperior(titulo: "Resumen",
                  iniciales: "MG",
                  periodoSeleccionado: .constant(2))
}
