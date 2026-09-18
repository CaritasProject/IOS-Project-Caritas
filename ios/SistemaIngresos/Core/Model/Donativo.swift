//
//  Donativo.swift
//  Core / Model — ARCHIVO COMPARTIDO.
//  Lo consumen Resumen (KPIs), Donantes (historial de pagos) y Reportes.
//

import Foundation

struct Donativo: Identifiable, Codable {
    let id: Int
    let donanteId: Int
    let monto: Decimal
    let fecha: Date
    let estatus: String    // "Cobrado", "Rechazado", "Pendiente"

    // TODO: completar con forma de pago y campaña asociada.
}
