//
//  SesionService.swift
//  Core / Services — ARCHIVO COMPARTIDO.
//
//  Estado de sesión que observa toda la app (usuario activo y token).
//  Dueño: Login + Perfil. Los demás solo leen.
//
//  Avisa al equipo antes de modificarlo.
//

import Foundation

@MainActor
final class SesionService: ObservableObject {
    @Published private(set) var usuario: Usuario?
    @Published private(set) var sesionIniciada: Bool = false
    @Published private(set) var cargando: Bool = false
    @Published var mensajeError: String?

    /// Token JWT de la sesión. Los demás servicios lo piden para llamar a la API.
    private(set) var token: String?

    private let loginService = LoginService()

    /// Inicia sesión contra /auth. Si algo falla, deja el motivo en `mensajeError`.
    func iniciarSesion(correo: String, password: String) async {
        mensajeError = nil

        let correoLimpio = correo.trimmingCharacters(in: .whitespacesAndNewlines)
        if correoLimpio.isEmpty || password.isEmpty {
            mensajeError = "Escribe tu correo y contraseña."
            return
        }

        cargando = true
        defer { cargando = false }

        do {
            let respuesta = try await loginService.iniciarSesion(correo: correoLimpio, password: password)
            self.token = respuesta.token
            // Lo dejamos en APIClient para que todos los servicios lo manden en sus peticiones.
            APIClient.tokenSesion = respuesta.token
            self.usuario = respuesta.usuario
            self.sesionIniciada = true
        } catch APIClient.ErrorAPI.http(401) {
            // En el login, un 401 quiere decir que el correo o la contraseña no coinciden.
            self.mensajeError = "Correo o contraseña incorrectos."
        } catch let error as APIClient.ErrorAPI {
            self.mensajeError = error.errorDescription ?? "No se pudo iniciar sesión."
        } catch {
            self.mensajeError = "Ocurrió un error inesperado."
        }
    }

    /// Cierra la sesión y limpia todo el estado.
    func cerrarSesion() {
        self.usuario = nil
        self.token = nil
        APIClient.tokenSesion = nil
        self.sesionIniciada = false
        self.mensajeError = nil
    }
}
