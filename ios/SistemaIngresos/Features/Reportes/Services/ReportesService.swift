import Foundation

let urlBaseAPI = "http://10.14.255.42:10206"

func peticionConSesion(ruta: String) throws -> URLRequest {
    guard let url = URL(string: "\(urlBaseAPI)/\(ruta)") else {
        print("URL incorrecto")
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    if let token = APIClient.tokenSesion {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    return request
}

func validarRespuesta(_ response: URLResponse, codigosAceptados: [Int] = [200]) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
        print("Respuesta no válida del servidor")
        throw URLError(.badServerResponse)
    }

    guard codigosAceptados.contains(httpResponse.statusCode) else {
        print("Código de error del API: \(httpResponse.statusCode)")
        throw URLError(.badServerResponse)
    }
}

func obtenerReportes() async throws -> [Reporte] {
    let request = try peticionConSesion(ruta: "reportes")
    let (data, response) = try await URLSession.shared.data(for: request)
    try validarRespuesta(response)

    let listaReportes = try JSONDecoder().decode([Reporte].self, from: data)
    return listaReportes
}

func obtenerReporte(idReporte: Int) async throws -> Reporte {
    let request = try peticionConSesion(ruta: "reportes/\(idReporte)")
    let (data, response) = try await URLSession.shared.data(for: request)
    try validarRespuesta(response)

    let reporte = try JSONDecoder().decode(Reporte.self, from: data)
    return reporte
}

func generarReporte(configuracion: ConfiguracionReporte) async throws -> Reporte {
    var request = try peticionConSesion(ruta: "reportes")
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(configuracion)

    let (data, response) = try await URLSession.shared.data(for: request)
    try validarRespuesta(response, codigosAceptados: [200, 201])

    let reporteGenerado = try JSONDecoder().decode(Reporte.self, from: data)
    return reporteGenerado
}

func obtenerDatosReporte(idReporte: Int) async throws -> DatosReporte {
    let request = try peticionConSesion(ruta: "reportes/\(idReporte)/datos")
    let (data, response) = try await URLSession.shared.data(for: request)
    try validarRespuesta(response)

    let datos = try JSONDecoder().decode(DatosReporte.self, from: data)
    return datos
}

func descargarArchivo(idReporte: Int) async throws -> URL {
    let request = try peticionConSesion(ruta: "reportes/\(idReporte)/archivo")
    let (data, response) = try await URLSession.shared.data(for: request)
    try validarRespuesta(response)

    let nombreArchivo = response.suggestedFilename ?? "reporte-\(idReporte)"
    let archivo = FileManager.default.temporaryDirectory.appendingPathComponent(nombreArchivo)
    try data.write(to: archivo)
    return archivo
}
