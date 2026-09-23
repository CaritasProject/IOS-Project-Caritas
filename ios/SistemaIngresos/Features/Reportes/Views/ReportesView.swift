import SwiftUI

struct ReportesView: View {
    @State private var listaReportes: [Reporte] = []
    @State private var mostrarError = false
    @State private var mensajeError = ""

    @State private var reporteSeleccionado: Reporte?

    @State private var mostrandoConfigurar = false
    @State private var mostrandoGenerado = false

    @State private var tipoElegido = "Ingresos"
    @State private var formatoElegido = "PDF"

    @State private var periodo = "Mes"

    var body: some View {
        ZStack {
            Palette.fondo
                .ignoresSafeArea()

            VStack(spacing: 0) {
                barraSuperior

                Divider()

                HStack(spacing: 0) {
                    bibliotecaIzquierda
                        .frame(width: 340)

                    Divider()

                    panelDerecho
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task {
            do {
                listaReportes = try await obtenerReportes()
            } catch {
                mensajeError = "No se pudo cargar la biblioteca de reportes. Revisa que estés conectado a la red de la universidad."
                mostrarError.toggle()
            }
        }
        .alert(mensajeError, isPresented: $mostrarError) {
            Button("OK") {}
        }
    }

    var barraSuperior: some View {
        HStack {
            Text("Reportes")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Spacer()

            Picker(selection: $periodo, label: Text("Periodo")) {
                Text("Día").tag("Día")
                Text("Semana").tag("Semana")
                Text("Mes").tag("Mes")
                Text("Trimestre").tag("Trimestre")
                Text("Año").tag("Año")
            }
            .pickerStyle(.segmented)
            .frame(width: 440)

            Spacer()

            AvatarUsuario()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Palette.superficie)
    }

    var bibliotecaIzquierda: some View {
        VStack(spacing: 14) {
            Button {
                reporteSeleccionado = nil
                mostrandoGenerado = false
                mostrandoConfigurar = true
            } label: {
                Label("Generar reporte", systemImage: "plus")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.turquesa)
            .controlSize(.large)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    grupoDeReportes(titulo: "Semanales", periodicidad: "Semanal")
                    grupoDeReportes(titulo: "Mensuales", periodicidad: "Mensual")
                }
                .padding(.bottom, 16)
            }
        }
        .padding(16)
    }

    func grupoDeReportes(titulo: String, periodicidad: String) -> some View {
        let reportesDelGrupo = listaReportes.filter { $0.periodicidad == periodicidad }

        return VStack(alignment: .leading, spacing: 10) {
            Text(titulo)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 6)

            ForEach(reportesDelGrupo) { reporte in
                Button {
                    reporteSeleccionado = reporte
                    mostrandoConfigurar = false
                    mostrandoGenerado = false
                } label: {
                    ReporteRow(reporte: reporte,
                               seleccionado: reporteSeleccionado?.id == reporte.id)
                }
                .buttonStyle(.plain)
            }
        }
    }

    var panelDerecho: some View {
        VStack {
            if mostrandoGenerado {
                ReporteGeneradoView(tipo: tipoElegido,
                                    periodo: periodo,
                                    formato: formatoElegido,
                                    mostrandoConfigurar: $mostrandoConfigurar,
                                    mostrandoGenerado: $mostrandoGenerado)

            } else if mostrandoConfigurar {
                ConfigurarReporteView(mostrandoConfigurar: $mostrandoConfigurar,
                                      mostrandoGenerado: $mostrandoGenerado,
                                      tipoElegido: $tipoElegido,
                                      formatoElegido: $formatoElegido,
                                      listaReportes: $listaReportes)

            } else if let reporte = reporteSeleccionado {
                DetalleReporteView(reporte: reporte)

            } else {
                estadoVacio
            }
        }
    }

    var estadoVacio: some View {
        VStack(spacing: 14) {
            Image(systemName: "folder")
                .font(.system(size: 54))
                .foregroundColor(.gray)

            Text("Ningún reporte seleccionado")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("Elige un reporte de la biblioteca para ver su contenido, o genera uno nuevo.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ReportesView()
        .environmentObject(SesionService())
}
