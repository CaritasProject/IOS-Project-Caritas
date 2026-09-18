//
//  Formatos.swift
//  Core / Utils — ARCHIVO COMPARTIDO.
//  Formato de moneda, porcentaje y fecha en español de México.
//

import Foundation

enum Formatos {
    static let localeMexico = Locale(identifier: "es_MX")

    /// Montos como $1,812,400
    static func moneda(_ monto: Decimal) -> String {
        // TODO: implementar con FormatStyle .currency(code: "MXN").
        return ""
    }

    /// Porcentajes como 77.5 %
    static func porcentaje(_ valor: Double) -> String {
        // TODO: implementar.
        return ""
    }

    /// Fechas cortas como 12 jun 2026
    static func fechaCorta(_ fecha: Date) -> String {
        // TODO: implementar.
        return ""
    }
}
