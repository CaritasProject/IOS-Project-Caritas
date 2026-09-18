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
    let rol: String        // "Administrador", "Capturista", "Consulta"
    let area: String       // "Dirección General", "Procuración de Fondos"

    // TODO: completar con último acceso.
}
