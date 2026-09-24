import Foundation

@MainActor
final class SesionService: ObservableObject {
    @Published private(set) var usuario: Usuario?
    @Published private(set) var sesionIniciada: Bool = false
    @Published private(set) var cargando: Bool = false
    @Published var mensajeError: String?

    private let loginService = LoginService()

    func iniciarSesion(correo: String, password: String) async {
        mensajeError = nil

        let correoSinEspacios = correo.trimmingCharacters(in: .whitespacesAndNewlines)
        if correoSinEspacios.isEmpty || password.isEmpty {
            mensajeError = "Escribe tu correo y contraseña."
            return
        }

        cargando = true
        defer { cargando = false }

        do {
            let respuesta = try await loginService.iniciarSesion(correo: correoSinEspacios, password: password)
            APIClient.tokenSesion = respuesta.token
            usuario = respuesta.usuario
            sesionIniciada = true
        } catch APIClient.ErrorAPI.http(401) {
            mensajeError = "Correo o contraseña incorrectos."
        } catch let error as APIClient.ErrorAPI {
            mensajeError = error.errorDescription
        } catch {
            mensajeError = "Ocurrió un error inesperado."
        }
    }

    func cerrarSesion() {
        APIClient.tokenSesion = nil
        usuario = nil
        sesionIniciada = false
        mensajeError = nil
    }
}
