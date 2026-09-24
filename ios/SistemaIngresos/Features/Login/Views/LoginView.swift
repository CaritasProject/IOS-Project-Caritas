import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var sesion: SesionService

    @State private var correo: String = ""
    @State private var contrasena: String = ""
    @FocusState private var campoEnFoco: Bool

    var body: some View {
        ZStack {
            Palette.fondo
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Image("LogoCaritas")
                    .resizable(resizingMode: .stretch)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 196)

                formulario

                Text("Acceso de uso interno. Cáritas de Monterrey, A.B.P.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textoSecundario)
            }
        }
        .onTapGesture {
            campoEnFoco = false
        }
    }

    private var formulario: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sistema de Ingresos")
                    .font(.system(size: 22))
                Text("Dirección General")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textoSecundario)
            }
            .padding(.bottom, 8)

            Text("Correo institucional")
                .font(.system(size: 13))
            TextField("nombre@caritas.org.mx", text: $correo)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .focused($campoEnFoco)
                .padding()
                .background(Palette.campoTexto)

            Text("Contraseña")
                .font(.system(size: 13))
            SecureField("••••••••", text: $contrasena)
                .focused($campoEnFoco)
                .padding()
                .background(Palette.campoTexto)

            if let mensaje = sesion.mensajeError {
                Text(mensaje)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
            }

            Button {
                campoEnFoco = false
                Task {
                    await sesion.iniciarSesion(correo: correo, password: contrasena)
                }
            } label: {
                if sesion.cargando {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Iniciar sesión")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Palette.turquesa)
            .disabled(sesion.cargando)
            .padding(.top, 8)
        }
        .padding(32)
        .frame(width: 420)
        .background(Palette.superficie)
    }
}

#Preview {
    LoginView()
        .environmentObject(SesionService())
}
