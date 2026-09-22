//
//  LoginView.swift
//  Features / Login — Dueño: Persona 1 (Login + Perfil).
//

import SwiftUI

struct LoginView: View {
    let textoCorreo = "nombre@caritas.org.mx"

    @State private var correo: String = ""
    @State private var contrasena: String = ""
    @FocusState private var campoEnFoco: Bool

    var body: some View {
        ZStack {
            //fondo gris de toda la pantalla
            Color(red: 242/255, green: 242/255, blue: 247/255)

            VStack {
                Image("LogoCaritas")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 196)

                Spacer().frame(height: 28)

                //tarjeta blanca con el formulario
                ZStack {
                    Color.white

                    VStack {
                        HStack {
                            Text("Sistema de Ingresos")
                                .font(.system(size: 22))
                            Spacer()
                        }
                        HStack {
                            Text("Dirección General")
                                .font(.system(size: 15))
                            Spacer()
                        }

                        Spacer().frame(height: 20)

                        HStack {
                            Text("Correo institucional")
                                .font(.system(size: 13))
                            Spacer()
                        }
                        ZStack {
                            Color(red: 118/255, green: 118/255, blue: 128/255, opacity: 0.12)
                            TextField(textoCorreo, text: $correo)
                                .focused($campoEnFoco)
                                .padding()
                        }
                        .frame(height: 56)

                        Spacer().frame(height: 12)

                        HStack {
                            Text("Contraseña")
                                .font(.system(size: 13))
                            Spacer()
                        }
                        ZStack {
                            Color(red: 118/255, green: 118/255, blue: 128/255, opacity: 0.12)
                            TextField("••••••••", text: $contrasena)
                                .focused($campoEnFoco)
                                .padding()
                        }
                        .frame(height: 56)

                        Spacer().frame(height: 20)

                        Button("Iniciar sesión") {
                            campoEnFoco = false
                            print("Correo = \(correo)")
                            print("Contraseña = \(contrasena)")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0/255, green: 152/255, blue: 174/255))
                        .frame(height: 50)
                    }
                    .frame(width: 356)
                }
                .frame(width: 420, height: 360)

                Spacer().frame(height: 28)

                Text("Acceso de uso interno. Cáritas de Monterrey, A.B.P.")
                    .font(.system(size: 13))
            }
        }
        .onTapGesture {
            campoEnFoco = false
        }
    }
}

#Preview {
    LoginView()
}
