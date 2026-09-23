import SwiftUI

struct BarraLateral: View {
    @State private var seccionSeleccionada: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Image("LogoCaritas")
                .resizable(resizingMode: .stretch)
                .aspectRatio(contentMode: .fit)
                .frame(width: 150)
                .padding(.top, 28)

            Text("Sistema de Ingresos")
                .font(.system(size: 13))
                .foregroundColor(paletaResumen.textoSecundario)
                .padding(.top, 8)

            VStack(spacing: 4) {
                RenglonBarraLateral(titulo: "Resumen",
                                    icono: "house",
                                    seleccionado: seccionSeleccionada == 0) {
                    seccionSeleccionada = 0
                }

                RenglonBarraLateral(titulo: "Donantes",
                                    icono: "person.crop.circle",
                                    seleccionado: seccionSeleccionada == 1) {
                    seccionSeleccionada = 1
                }

                RenglonBarraLateral(titulo: "Reportes",
                                    icono: "folder",
                                    seleccionado: seccionSeleccionada == 2) {
                    seccionSeleccionada = 2
                }

                RenglonBarraLateral(titulo: "Metas",
                                    icono: "safari",
                                    seleccionado: seccionSeleccionada == 3) {
                    seccionSeleccionada = 3
                }
            }
            .padding(.top, 32)

            Spacer()

            Text("Datos de demostración")
                .font(.system(size: 12))
                .foregroundColor(paletaResumen.textoSecundario)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 20)
        .frame(width: 300)
        .frame(maxHeight: .infinity)
        .background(paletaResumen.fondo)
    }
}

#Preview {
    BarraLateral()
}
