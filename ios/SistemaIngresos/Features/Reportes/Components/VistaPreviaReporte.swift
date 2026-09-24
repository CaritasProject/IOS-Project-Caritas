import SwiftUI

struct VistaPreviaReporte: View {
    var idReporte: Int

    @State private var datos: DatosReporte?
    @State private var fallo = false

    let anchoColumna: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Vista previa")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                if let datosListos = datos {
                    Text("\(datosListos.filas.count) registros · datos al \(datosListos.datosAl)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            contenido
        }
        .padding(16)
        .background(Palette.superficie)
        .cornerRadius(14)
        .task(id: idReporte) {
            await cargar()
        }
    }

    @ViewBuilder
    var contenido: some View {
        if let datosListos = datos {
            if datosListos.filas.isEmpty {
                Text("Sin registros en este periodo.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            ForEach(datosListos.columnas) { columna in
                                Text(columna.nombre)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: anchoColumna, alignment: .leading)
                                    .padding(8)
                            }
                        }
                        .background(Palette.turquesa)

                        ForEach(datosListos.filas) { fila in
                            HStack(spacing: 0) {
                                ForEach(fila.celdas) { celda in
                                    Text(celda.valor)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .frame(width: anchoColumna, alignment: .leading)
                                        .padding(8)
                                }
                            }
                            .background(fila.id % 2 == 0 ? Palette.superficie : Palette.fondo)
                        }
                    }
                }
            }
        } else if fallo {
            Text("No se pudo cargar la vista previa. Revisa que estés conectado a la red de la universidad.")
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        }
    }

    func cargar() async {
        datos = nil
        fallo = false
        do {
            datos = try await obtenerDatosReporte(idReporte: idReporte)
        } catch {
            fallo = true
        }
    }
}

#Preview {
    VistaPreviaReporte(idReporte: 7)
        .padding()
        .background(Palette.fondo)
}
