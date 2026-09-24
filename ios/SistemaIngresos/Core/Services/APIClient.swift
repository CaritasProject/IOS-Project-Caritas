import Foundation

final class APIClient {
    static let compartido = APIClient()
    static var tokenSesion: String?

    private let baseURL: String
    private let sesion: URLSession
    private let token: () -> String?

    init(baseURL: String? = nil, sesion: URLSession = .shared,
         token: @escaping () -> String? = { APIClient.tokenSesion }) {
        self.baseURL = baseURL ?? APIClient.baseURLConfigurada()
        self.sesion = sesion
        self.token = token
    }

    enum ErrorAPI: LocalizedError {
        case configuracion
        case http(Int)
        case datos

        var errorDescription: String? {
            switch self {
            case .configuracion: "Configura una URL válida para la API."
            case .http(401): "Tu sesión expiró. Cierra la app y vuelve a iniciar sesión."
            case .http(404): "El recurso ya no está disponible."
            case .http(503): "El servicio no está configurado o no está disponible."
            case .http(let codigo): "La API respondió con un error (\(codigo))."
            case .datos: "La respuesta de la API no tiene el formato esperado."
            }
        }
    }

    func get<T: Decodable>(_ ruta: String) async throws -> T {
        let request = try armarPeticion(ruta: ruta)
        return try await enviar(request)
    }

    func post<Cuerpo: Encodable, T: Decodable>(_ ruta: String, cuerpo: Cuerpo) async throws -> T {
        var request = try armarPeticion(ruta: ruta)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(cuerpo)
        return try await enviar(request)
    }

    private static func baseURLConfigurada() -> String {
        if let desdeScheme = ProcessInfo.processInfo.environment["API_BASE_URL"] {
            return desdeScheme
        }
        if let desdeInfoPlist = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
            return desdeInfoPlist
        }
        return "http://localhost:5000"
    }

    private func armarPeticion(ruta: String) throws -> URLRequest {
        guard let base = URL(string: baseURL),
              base.scheme == "http" || base.scheme == "https",
              base.host != nil else {
            throw ErrorAPI.configuracion
        }

        var request = URLRequest(url: base.appending(path: ruta))
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = token(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func enviar<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await sesion.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ErrorAPI.datos
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw ErrorAPI.http(httpResponse.statusCode)
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw ErrorAPI.datos
        }
    }
}
