import Foundation

let urlBaseAPI = "http://10.14.255.42:10206"

func obtenerReportes() async throws -> [Reporte] {
    guard let url = URL(string: "\(urlBaseAPI)/reportes") else {
        print("URL incorrecto")
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    if let token = APIClient.tokenSesion {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        print("Respuesta no válida del servidor")
        throw URLError(.badServerResponse)
    }

    guard httpResponse.statusCode == 200 else {
        print("Código de error del API: \(httpResponse.statusCode)")
        throw URLError(.badServerResponse)
    }

    let jsonDecoder = JSONDecoder()
    let listaReportes = try jsonDecoder.decode([Reporte].self, from: data)
    return listaReportes
}

func obtenerReporte(idReporte: Int) async throws -> Reporte {
    guard let url = URL(string: "\(urlBaseAPI)/reportes/\(idReporte)") else {
        print("URL incorrecto")
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    if let token = APIClient.tokenSesion {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        print("Respuesta no válida del servidor")
        throw URLError(.badServerResponse)
    }

    guard httpResponse.statusCode == 200 else {
        print("Código de error del API: \(httpResponse.statusCode)")
        throw URLError(.badServerResponse)
    }

    let jsonDecoder = JSONDecoder()
    let reporte = try jsonDecoder.decode(Reporte.self, from: data)
    return reporte
}

func generarReporte(configuracion: ConfiguracionReporte) async throws -> Reporte {
    guard let url = URL(string: "\(urlBaseAPI)/reportes") else {
        print("URL incorrecto")
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let token = APIClient.tokenSesion {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    request.httpBody = try JSONEncoder().encode(configuracion)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        print("Respuesta no válida del servidor")
        throw URLError(.badServerResponse)
    }

    guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
        print("Código de error del API: \(httpResponse.statusCode)")
        throw URLError(.badServerResponse)
    }

    let jsonDecoder = JSONDecoder()
    let reporteGenerado = try jsonDecoder.decode(Reporte.self, from: data)
    return reporteGenerado
}

func obtenerDatosReporte(idReporte: Int) async throws -> DatosReporte {
    guard let url = URL(string: "\(urlBaseAPI)/reportes/\(idReporte)/datos") else {
        print("URL incorrecto")
        throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        print("Respuesta no válida del servidor")
        throw URLError(.badServerResponse)
    }

    guard httpResponse.statusCode == 200 else {
        print("Código de error del API: \(httpResponse.statusCode)")
        throw URLError(.badServerResponse)
    }

    let jsonDecoder = JSONDecoder()
    let datos = try jsonDecoder.decode(DatosReporte.self, from: data)
    return datos
}

func descargarArchivo(idReporte: Int) async throws -> URL {
    guard let url = URL(string: "\(urlBaseAPI)/reportes/\(idReporte)/archivo") else {
        print("URL incorrecto")
        throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        print("Respuesta no válida del servidor")
        throw URLError(.badServerResponse)
    }

    guard httpResponse.statusCode == 200 else {
        print("Código de error del API: \(httpResponse.statusCode)")
        throw URLError(.badServerResponse)
    }

    let nombreArchivo = httpResponse.suggestedFilename ?? "reporte-\(idReporte)"
    let archivo = FileManager.default.temporaryDirectory.appendingPathComponent(nombreArchivo)
    try data.write(to: archivo)
    return archivo
}
