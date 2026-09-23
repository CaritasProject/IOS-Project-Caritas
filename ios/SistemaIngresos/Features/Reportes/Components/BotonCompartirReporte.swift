import SwiftUI

struct BotonCompartirReporte: View {
    var reporte: Reporte
    var destacado: Bool

    @State private var archivo: URL?
    @State private var preparando = false
    @State private var mostrarError = false

    var body: some View {
        VStack {
            if let archivoListo = archivo {
                if destacado {
                    ShareLink(item: archivoListo) {
                        etiqueta
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.turquesa)
                } else {
                    ShareLink(item: archivoListo) {
                        etiqueta
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button {
                    Task {
                        await preparar(avisarSiFalla: true)
                    }
                } label: {
                    etiqueta
                }
                .buttonStyle(.bordered)
                .disabled(preparando)
            }
        }
        .controlSize(.large)
        .task(id: reporte.id) {
            await preparar(avisarSiFalla: false)
        }
        .alert("No se pudo preparar el archivo", isPresented: $mostrarError) {
            Button("OK") {}
        } message: {
            Text("Revisa que estés conectado a la red de la universidad e intenta de nuevo.")
        }
    }

    var etiqueta: some View {
        Label(preparando ? "Preparando…" : "Compartir \(reporte.formato)", systemImage: "square.and.arrow.up")
            .font(destacado ? .title3 : .headline)
            .fontWeight(destacado ? .bold : .regular)
            .padding(.horizontal, destacado ? 24 : 16)
            .padding(.vertical, 12)
    }

    func preparar(avisarSiFalla: Bool) async {
        archivo = nil
        preparando = true
        do {
            archivo = try await descargarArchivo(idReporte: reporte.id)
        } catch {
            if avisarSiFalla {
                mostrarError.toggle()
            }
        }
        preparando = false
    }
}

#Preview {
    BotonCompartirReporte(reporte: reportesDeMuestra()[0], destacado: true)
}
