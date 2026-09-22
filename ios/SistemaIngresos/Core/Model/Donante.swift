import Foundation

struct Donante: Identifiable, Codable {
    let id: Int
    let nombre: String
    let segmento: String
    let estado: String
    var montoTotal: Decimal = 0
    var ultimaDonacion: Date = .distantPast
    var primeraDonacion: Date = .distantPast
    var frecuencia: String = ""
    var montoPromedio: Decimal = 0
    var acumulado12Meses: Decimal = 0
    var detalleEstado: String = ""
    var pagos: [PagoDonante] = []
    var llamadas: [LlamadaDonante] = []

    var estadoVisual: EstadoVisualDonante {
        if estado == "inactivo" { return .inactive }
        if segmento == "en_riesgo" { return .risk }
        if segmento == "alto_valor" { return .highValue }
        return .active
    }
}

enum EstadoVisualDonante {
    case active, risk, highValue, inactive
    var title: String {
        switch self {
        case .active: "Activo"
        case .risk: "Riesgo alto"
        case .highValue: "Alto valor"
        case .inactive: "Inactivo"
        }
    }
}

struct PagoDonante: Identifiable, Codable {
    let id: Int
    let date: Date
    let amount: Decimal
    let status: EstadoPagoDonante
}

enum EstadoPagoDonante: String, Codable {
    case paid = "cobrado"
    case rejected = "rechazado"
    case pending = "pendiente"
    var title: String {
        switch self {
        case .paid: "Cobrado"
        case .rejected: "Rechazado"
        case .pending: "Pendiente"
        }
    }
}

struct LlamadaDonante: Identifiable, Codable {
    let id: Int
    let date: Date
    let result: String
    let notes: String
}
