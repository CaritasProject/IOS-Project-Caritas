import SwiftUI

struct ConfigurarReporteView: View {
    @Binding var mostrandoConfigurar: Bool
    @Binding var mostrandoGenerado: Bool

    @Binding var tipoElegido: String
    @Binding var formatoElegido: String
    @Binding var listaReportes: [Reporte]

    @State private var fechaDesde = Date()
    @State private var fechaHasta = Date()
    @State private var lineaEstrategica = "Todas"
    @State private var campania = "Todas"
    @State private var generando = false

    @State private var mostrarAlerta = false
    @State private var mensajeAlerta = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Configurar reporte")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Tipo de reporte")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Picker(selection: $tipoElegido, label: Text("Tipo de reporte")) {
                        Text("Ingresos").tag("Ingresos")
                        Text("Cobranza").tag("Cobranza")
                        Text("Telemarketing").tag("Telemarketing")
                        Text("Metas").tag("Metas")
                    }
                    .pickerStyle(.segmented)
                }

                // DatePicker no se vio en clase: es el control nativo de calendario.
                VStack(alignment: .leading, spacing: 10) {
                    Text("Rango de fechas")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 0) {
                        DatePicker(selection: $fechaDesde, displayedComponents: .date) {
                            Text("Desde")
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider()

                        DatePicker(selection: $fechaHasta, displayedComponents: .date) {
                            Text("Hasta")
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Palette.superficie)
                    .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Alcance")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 0) {
                        Picker(selection: $lineaEstrategica, label: Text("Línea estratégica")) {
                            Text("Todas").tag("Todas")
                            Text("Telemarketing").tag("Telemarketing")
                            Text("Eventos").tag("Eventos")
                            Text("Fundaciones").tag("Fundaciones")
                            Text("Medios de comunicación").tag("Medios de comunicación")
                            Text("Colecta ánforas").tag("Colecta ánforas")
                            Text("Donativos por área").tag("Donativos por área")
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)

                        Divider()

                        Picker(selection: $campania, label: Text("Campaña")) {
                            Text("Todas").tag("Todas")
                            Text("Correo directo").tag("Correo directo")
                            Text("Tu ayuda mi única esperanza").tag("Tu ayuda mi única esperanza")
                            Text("Estímulos públicos").tag("Estímulos públicos")
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                    .background(Palette.superficie)
                    .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Formato de salida")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Picker(selection: $formatoElegido, label: Text("Formato de salida")) {
                        Text("PDF").tag("PDF")
                        Text("Excel").tag("Excel")
                        Text("CSV").tag("CSV")
                    }
                    .pickerStyle(.segmented)

                    Text("El reporte queda disponible en la biblioteca durante 90 días.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 14) {
                    Button {
                        generar()
                    } label: {
                        Text(generando ? "Generando…" : "Generar reporte")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.turquesa)
                    .controlSize(.large)

                    Button {
                        mostrandoConfigurar = false
                    } label: {
                        Text("Cancelar")
                            .font(.title3)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Spacer()
            }
            .padding(28)
        }
        .alert(mensajeAlerta, isPresented: $mostrarAlerta) {
            Button("OK") {}
        }
    }

    func generar() {
        if fechaHasta < fechaDesde {
            mensajeAlerta = "La fecha Hasta no puede ser anterior a la fecha Desde."
            mostrarAlerta.toggle()
            return
        }

        if tipoElegido.isEmpty {
            mensajeAlerta = "Elige el tipo de reporte que quieres generar."
            mostrarAlerta.toggle()
            return
        }

        if generando {
            return
        }
        generando = true

        let configuracion = ConfiguracionReporte(tipo: tipoElegido,
                                                 desde: fechaParaAPI(fechaDesde),
                                                 hasta: fechaParaAPI(fechaHasta),
                                                 lineaEstrategica: lineaEstrategica,
                                                 campania: campania,
                                                 formato: formatoElegido)
        Task {
            do {
                let nuevo = try await generarReporte(configuracion: configuracion)
                listaReportes.insert(nuevo, at: 0)
                mostrandoConfigurar = false
                mostrandoGenerado = true
            } catch {
                mensajeAlerta = "No se pudo generar el reporte. Revisa tu conexión e intenta de nuevo."
                mostrarAlerta.toggle()
            }
            generando = false
        }
    }

    func fechaParaAPI(_ fecha: Date) -> String {
        let formato = DateFormatter()
        formato.dateFormat = "yyyy-MM-dd"
        formato.locale = Locale(identifier: "es_MX")
        return formato.string(from: fecha)
    }
}

#Preview {
    ConfigurarReporteView(mostrandoConfigurar: .constant(true),
                          mostrandoGenerado: .constant(false),
                          tipoElegido: .constant("Ingresos"),
                          formatoElegido: .constant("PDF"),
                          listaReportes: .constant([]))
        .background(Palette.fondo)
}
