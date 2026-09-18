//
//  SesionService.swift
//  Core / Services — ARCHIVO COMPARTIDO.
//
//  Estado de sesión que observa toda la app (usuario activo y token).
//  Dueño: Login + Perfil. Los demás solo leen.
//
//  Avisa al equipo antes de modificarlo.
//

import Foundation

@MainActor
final class SesionService: ObservableObject {
    @Published private(set) var usuario: Usuario?
    @Published private(set) var sesionIniciada: Bool = false

    // TODO: implementar inicio y cierre de sesión contra /auth de la API.
}
