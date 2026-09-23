import SwiftUI

struct SelectorPeriodo: View {
    @Binding var periodoSeleccionado: Int

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { periodoSeleccionado = 0 }) {
                etiqueta("Día", activo: periodoSeleccionado == 0)
            }
            .buttonStyle(.plain)

            Button(action: { periodoSeleccionado = 1 }) {
                etiqueta("Semana", activo: periodoSeleccionado == 1)
            }
            .buttonStyle(.plain)

            Button(action: { periodoSeleccionado = 2 }) {
                etiqueta("Mes", activo: periodoSeleccionado == 2)
            }
            .buttonStyle(.plain)

            Button(action: { periodoSeleccionado = 3 }) {
                etiqueta("Trimestre", activo: periodoSeleccionado == 3)
            }
            .buttonStyle(.plain)

            Button(action: { periodoSeleccionado = 4 }) {
                etiqueta("Año", activo: periodoSeleccionado == 4)
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(paletaResumen.rielSelector)
        )
    }

    private func etiqueta(_ texto: String, activo: Bool) -> some View {
        Text(texto)
            .font(.system(size: 16))
            .fontWeight(activo ? .semibold : .regular)
            .foregroundColor(activo ? paletaResumen.texto : paletaResumen.textoSecundario)
            .frame(height: 40)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(activo ? paletaResumen.superficie : Color.clear)
                    .shadow(color: activo ? Color.black.opacity(0.10) : Color.clear,
                            radius: 3, y: 1)
            )
    }
}

#Preview {
    SelectorPeriodo(periodoSeleccionado: .constant(2))
        .padding()
        .background(paletaResumen.superficie)
}
