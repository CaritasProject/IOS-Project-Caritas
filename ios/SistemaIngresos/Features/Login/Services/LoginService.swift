import Foundation

struct CredencialesLogin: Encodable {
    let correo: String
    let password: String
}

struct RespuestaLogin: Decodable {
    let token: String
    let usuario: Usuario
}

final class LoginService {
    private let api: APIClient

    init(api: APIClient = .compartido) {
        self.api = api
    }

    func iniciarSesion(correo: String, password: String) async throws -> RespuestaLogin {
        let credenciales = CredencialesLogin(correo: correo, password: password)
        return try await api.post("auth/login", cuerpo: credenciales)
    }
}
