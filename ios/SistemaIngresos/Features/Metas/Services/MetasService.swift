//
//  MetasService.swift
//  Features / Metas — Dueño: Persona 5.
//
//  Aquí vive la llamada a /metas. Ninguna View instancia URLSession
//  ni decodifica JSON por su cuenta.
//

import Foundation

@MainActor
final class MetasService: ObservableObject {
    @Published private(set) var metas: [MetaAvance] = []
    @Published private(set) var rangoConsultado: String = ""
    @Published private(set) var cargando = false
    @Published private(set) var error: String?

    private let api: APIClient
    private let ruta: String

    init(api: APIClient = .compartido, ruta: String = "metas") {
        self.api = api
        self.ruta = ruta
    }

    /// GET /metas/periodo/<periodo>. El periodo va en la ruta y no como query
    /// porque APIClient arma la URL con appending(path:), que escapa el "?".
    func cargar(periodo: Periodo) async {
        guard !cargando else { return }
        cargando = true
        error = nil
        defer { cargando = false }
        do {
            let respuesta: RespuestaMetas = try await api.get("\(ruta)/periodo/\(periodo.rawValue)")
            metas = respuesta.metas
            rangoConsultado = "\(respuesta.desde) a \(respuesta.hasta)"
        } catch is CancellationError {
        } catch {
            guard (error as? URLError)?.code != .cancelled else { return }
            metas = []
            self.error = error.localizedDescription
        }
    }

    /// Solo para #Preview: datos fijos, sin tocar la red.
    static var previsualizacion: MetasService {
        let servicio = MetasService()
        servicio.metas = MetaAvance.muestra
        servicio.rangoConsultado = "2026-07-01 a 2026-09-30"
        return servicio
    }
}
