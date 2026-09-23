import Foundation

struct SemanaIngreso: Codable, Identifiable {
    let semana: Int
    let etiqueta: String
    let comprometido: Double
    let cobrado: Double

    var id: Int { return semana }
}
