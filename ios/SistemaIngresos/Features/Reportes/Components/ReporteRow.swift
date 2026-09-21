import SwiftUI

struct ReporteRow: View {
    var reporte: Reporte
    var seleccionado: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reporte.periodicidad == "Semanal" ? "list.bullet" : "folder")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(Palette.turquesa)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(reporte.nombre)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Text("\(reporte.fecha) · \(reporte.meta)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(seleccionado ? Palette.turquesa.opacity(0.12) : Palette.superficie)
        .cornerRadius(10)
    }
}

#Preview {
    VStack(spacing: 10) {
        ReporteRow(reporte: reportesDeMuestra()[0], seleccionado: true)
        ReporteRow(reporte: reportesDeMuestra()[2], seleccionado: false)
    }
    .padding()
    .background(Palette.fondo)
}
