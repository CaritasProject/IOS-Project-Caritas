//
//  LoginService.swift
//  Features / Login — Dueño: Persona 1 (Login + Perfil).
//
//  Aquí vive la llamada a /auth. Ninguna View instancia URLSession
//  ni decodifica JSON por su cuenta.
//

import Foundation

/// Lo que se manda a POST /auth/login.
struct CredencialesLogin: Encodable {
    let correo: String
    let password: String
}

/// Lo que devuelve POST /auth/login.
struct RespuestaLogin: Decodable {
    let token: String
    let tipo: String
    let usuario: Usuario
}

@MainActor
final class LoginService: ObservableObject {
    private let api: APIClient

    init(api: APIClient = .compartido) {
        self.api = api
    }

    /// Envía las credenciales a la API y devuelve el token + el usuario.
    func iniciarSesion(correo: String, password: String) async throws -> RespuestaLogin {
        let credenciales = CredencialesLogin(correo: correo, password: password)
        return try await api.post("auth/login", body: credenciales)
    }
}
