import SwiftUI

struct BarraSuperior: View {
    let titulo: String
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

            AvatarUsuario(tamano: 38)
        }
        .padding(.horizontal, 24)
        .frame(height: 64)
        .frame(maxWidth: .infinity)
        .background(paletaResumen.superficie)
    }
}

#Preview {
    BarraSuperior(titulo: "Resumen",
                  periodoSeleccionado: .constant(2))
        .environmentObject(SesionService())
}
