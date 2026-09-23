import Foundation

struct ResumenService {
    private let api = APIClient()

    func obtenerKPIs(periodo: String) async throws -> ResumenKPIs {
        return try await api.get("resumen/kpis/\(periodo)")
    }
}
