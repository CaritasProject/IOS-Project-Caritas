import Foundation

struct Donante: Identifiable, Codable {
    let id: Int
    let nombre: String
    let segmento: String
    let estado: String
    let nivelRiesgo: NivelRiesgoDonante
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
        EstadoVisualDonante(nivelRiesgo: nivelRiesgo)
    }
}

enum NivelRiesgoDonante: String, Codable {
    case verde
    case amarillo
    case naranja
    case rojo
}

enum EstadoVisualDonante {
    case verde, amarillo, naranja, rojo

    init(nivelRiesgo: NivelRiesgoDonante) {
        switch nivelRiesgo {
        case .verde: self = .verde
        case .amarillo: self = .amarillo
        case .naranja: self = .naranja
        case .rojo: self = .rojo
        }
    }

    var title: String {
        switch self {
        case .verde: "Riesgo bajo"
        case .amarillo: "Riesgo medio"
        case .naranja: "Riesgo elevado"
        case .rojo: "Riesgo alto"
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
