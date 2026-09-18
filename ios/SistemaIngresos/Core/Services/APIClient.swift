//
//  APIClient.swift
//  Core / Services — ARCHIVO COMPARTIDO.
//
//  Único punto de la app que habla con la API REST.
//  Ninguna View instancia URLSession ni decodifica JSON: todo pasa por aquí
//  o por el servicio de la Feature correspondiente.
//
//  Avisa al equipo antes de modificarlo.
//

import Foundation

final class APIClient {
    static let compartido = APIClient()

    private let baseURL: URL
    private let sesion: URLSession

    private init() {
        // TODO: leer la URL base de la configuración del entorno.
        if let url = URL(string: "http://localhost:8000") {
            self.baseURL = url
        } else {
            self.baseURL = URL(fileURLWithPath: "/")
        }
        self.sesion = URLSession.shared
    }

    // TODO: implementar la petición genérica (GET/POST) y el manejo de errores.
}
