//
//  Meta.swift
//  Core / Model — ARCHIVO COMPARTIDO.
//  Lo consumen Metas, Resumen (tarjeta de metas del periodo) y Reportes.
//

import Foundation

struct Meta: Identifiable, Codable {
    let id: Int
    let lineaEstrategica: String   // "Banco de Alimentos", "Dispensarios Médicos", ...
    let comprometido: Decimal
    let cobrado: Decimal

    // TODO: completar con avance mensual y donantes activos.
}
