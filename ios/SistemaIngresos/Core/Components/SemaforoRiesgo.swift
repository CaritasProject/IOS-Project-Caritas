//
//  SemaforoRiesgo.swift
//  Core / Components — ARCHIVO COMPARTIDO.
//  Lo usan Resumen (tarjetas), Donantes (listado y ficha) y Metas.
//

import SwiftUI

enum NivelRiesgo {
    case alto      // dos o más cobros vencidos
    case medio     // un cobro vencido
    case bajo      // al corriente
}

struct SemaforoRiesgo: View {
    let nivel: NivelRiesgo
    var texto: String?

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            if let texto {
                Text(texto)
                    .font(.subheadline)
            }
        }
    }

    private var color: Color {
        switch nivel {
        case .alto:  return Palette.riesgoAlto
        case .medio: return Palette.riesgoMedio
        case .bajo:  return Palette.riesgoBajo
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SemaforoRiesgo(nivel: .alto, texto: "Riesgo alto")
        SemaforoRiesgo(nivel: .medio, texto: "Un cobro vencido")
        SemaforoRiesgo(nivel: .bajo, texto: "Al corriente")
    }
    .padding()
}
