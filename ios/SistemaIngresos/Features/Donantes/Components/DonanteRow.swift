import SwiftUI

struct DonanteRow: View {
    let donor: Donante
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(donor.estadoVisual.color)
                .frame(width: 9, height: 9)

            VStack(alignment: .leading, spacing: 3) {
                Text(donor.nombre)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Text("Última donación \(donor.ultimaDonacion.donorDate)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(donor.montoTotal.currency)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .contentShape(Rectangle())
        .background(isSelected ? Palette.turquesa.opacity(0.14) : .white)
    }
}

extension EstadoVisualDonante {
    var color: Color {
        switch self {
        case .active: Palette.riesgoBajo
        case .risk: Palette.riesgoAlto
        case .highValue: Palette.riesgoMedio
        case .inactive: .gray
        }
    }
}

extension Decimal {
    var currency: String {
        formatted(.currency(code: "MXN").precision(.fractionLength(0)).locale(Locale(identifier: "es_MX")))
    }
}

extension Date {
    var donorDate: String {
        formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "es_MX")))
    }
}
