import Foundation

/// Configura API_BASE_URL en el Scheme de Xcode o en Info.plist.
/// El token de la sesión lo escribe SesionService en `tokenSesion`; nunca se guarda en código.
final class APIClient {
    static let compartido = APIClient()

    /// Token JWT de la sesión activa, compartido por toda la app (como UserDefaults.standard).
    /// SesionService lo guarda al iniciar sesión y lo borra al cerrarla.
    static var tokenSesion: String?

    private let baseURL: String
    private let sesion: URLSession
    private let token: () -> String?

    init(baseURL: String? = nil, sesion: URLSession = .shared,
         token: @escaping () -> String? = { APIClient.tokenSesion }) {
        self.baseURL = baseURL ?? ProcessInfo.processInfo.environment["API_BASE_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
            ?? "http://localhost:5000"
        self.sesion = sesion
        self.token = token
    }

    enum ErrorAPI: LocalizedError {
        case configuracion, http(Int), datos
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

    func get<T: Decodable>(_ path: String) async throws -> T {
        guard let base = URL(string: baseURL), ["http", "https"].contains(base.scheme),
              base.host != nil else { throw ErrorAPI.configuracion }
        var request = URLRequest(url: base.appending(path: path))
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = token(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await sesion.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ErrorAPI.datos }
        guard 200..<300 ~= http.statusCode else { throw ErrorAPI.http(http.statusCode) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch { throw ErrorAPI.datos }
    }

    /// POST con cuerpo JSON. Lo usa el login (auth/login). Mismo estilo que get.
    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        guard let base = URL(string: baseURL), ["http", "https"].contains(base.scheme),
              base.host != nil else { throw ErrorAPI.configuracion }
        var request = URLRequest(url: base.appending(path: path))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await sesion.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ErrorAPI.datos }
        guard 200..<300 ~= http.statusCode else { throw ErrorAPI.http(http.statusCode) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch { throw ErrorAPI.datos }
    }
}
