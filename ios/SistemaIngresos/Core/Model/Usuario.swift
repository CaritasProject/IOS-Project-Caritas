//
//  Usuario.swift
//  Core / Model — ARCHIVO COMPARTIDO.
//  Lo consumen Login + Perfil y el resto de pantallas para permisos.
//

import Foundation

struct Usuario: Identifiable, Codable {
    let id: Int
    let nombre: String
    let correo: String
    let rol: String        // "ADMINISTRADOR", "TELEFONISTA", "RECOLECTOR"
    let area: String       // "Dirección General", "Procuración de Fondos"
}
