import SwiftUI

struct BarraLateral: View {
    @EnvironmentObject private var sesion: SesionService
    @Binding var seccionSeleccionada: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Image("LogoCaritas")
                .resizable(resizingMode: .stretch)
                .aspectRatio(contentMode: .fit)
                .frame(width: 150)
                .padding(.top, 28)

            Text("Sistema de Ingresos")
                .font(.system(size: 13))
                .foregroundColor(Palette.textoSecundario)
                .padding(.top, 8)

            VStack(spacing: 4) {
                RenglonBarraLateral(titulo: "Resumen",
                                    icono: "house",
                                    seleccionado: seccionSeleccionada == 0) {
                    seccionSeleccionada = 0
                }

                RenglonBarraLateral(titulo: "Donantes",
                                    icono: "person.2",
                                    seleccionado: seccionSeleccionada == 1) {
                    seccionSeleccionada = 1
                }

                RenglonBarraLateral(titulo: "Reportes",
                                    icono: "folder",
                                    seleccionado: seccionSeleccionada == 2) {
                    seccionSeleccionada = 2
                }

                RenglonBarraLateral(titulo: "Metas",
                                    icono: "target",
                                    seleccionado: seccionSeleccionada == 3) {
                    seccionSeleccionada = 3
                }
            }
            .padding(.top, 32)

            Spacer()

            HStack(spacing: 12) {
                AvatarUsuario()

                if let usuario = sesion.usuario {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(usuario.nombre)
                            .font(.system(size: 15))
                            .fontWeight(.semibold)
                            .foregroundColor(Palette.texto)
                            .lineLimit(1)

                        Text(usuario.rol.capitalized)
                            .font(.system(size: 13))
                            .foregroundColor(Palette.textoSecundario)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 20)
        .frame(width: 300)
        .frame(maxHeight: .infinity)
        .background(Palette.fondo)
    }
}

#Preview {
    BarraLateral(seccionSeleccionada: .constant(0))
        .environmentObject(SesionService())
}
