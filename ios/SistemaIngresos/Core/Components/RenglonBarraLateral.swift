import SwiftUI

struct RenglonBarraLateral: View {
    let titulo: String
    let icono: String
    let seleccionado: Bool
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 14) {
                Image(systemName: icono)
                    .font(.system(size: 18))
                    .frame(width: 24)

                Text(titulo)
                    .font(.system(size: 18))

                Spacer()
            }
            .foregroundColor(seleccionado ? Palette.turquesa : Palette.texto)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(seleccionado ? Palette.turquesaSuave : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 4) {
        RenglonBarraLateral(titulo: "Resumen", icono: "house",
                            seleccionado: true, accion: {})
        RenglonBarraLateral(titulo: "Donantes", icono: "person.crop.circle",
                            seleccionado: false, accion: {})
    }
    .padding()
    .background(Palette.fondo)
}
