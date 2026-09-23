import SwiftUI

struct AvatarUsuario: View {
    @EnvironmentObject private var sesion: SesionService
    @State private var mostrandoPerfil = false

    var tamano: CGFloat = 40

    var body: some View {
        Button {
            mostrandoPerfil = true
        } label: {
            Text(iniciales())
                .font(.system(size: tamano * 0.38))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: tamano, height: tamano)
                .background(Palette.turquesa)
                .clipShape(.circle)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $mostrandoPerfil) {
            PerfilView()
                .environmentObject(sesion)
        }
    }

    func iniciales() -> String {
        if let usuario = sesion.usuario {
            let palabras = usuario.nombre.split(separator: " ").prefix(2)
            var letras = ""
            for palabra in palabras {
                if let primera = palabra.first {
                    letras += String(primera)
                }
            }
            return letras.uppercased()
        }
        return ""
    }
}

#Preview {
    AvatarUsuario()
        .environmentObject(SesionService())
}
