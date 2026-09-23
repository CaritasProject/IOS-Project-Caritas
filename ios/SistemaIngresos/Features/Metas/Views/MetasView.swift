//
//  MetasView.swift
//  Features / Metas — Dueño: Persona 5.
//

import SwiftUI
import Charts

// Modelo local de la pantalla de Metas.
// Nota: se llama MetaAvance para no chocar con el modelo compartido Core/Model/Meta.swift.
struct MetaAvance: Identifiable {
    let id: Int
    let nombre: String
    let linea: String
    let cobrado: Double
    let objetivo: Double
    let comprometido: Double
    let color: Color
    let donantes: Int
    let mensual: [MesAvance]
}

struct MesAvance: Identifiable {
    let id: Int
    let mes: String
    let monto: Double
}

struct Rebanada: Identifiable {
    let id: Int
    let categoria: String
    let valor: Double
}

struct MetasView: View {

    @State var periodo = "Mes"
    @State var metaSeleccionada = 0

    let periodos = ["Día", "Semana", "Mes", "Trimestre", "Año"]

    let azulCaritas = Palette.turquesa
    let azulClaro = Palette.turquesa.opacity(0.15)
    let fondo = Palette.fondo

    let metas: [MetaAvance] = [
        MetaAvance(id: 0, nombre: "Banco de Alimentos", linea: "Alimentación",
             cobrado: 664200, objetivo: 820000, comprometido: 742000,
             color: .green, donantes: 1240,
             mensual: [
                MesAvance(id: 1, mes: "Junio", monto: 208400),
                MesAvance(id: 2, mes: "Julio", monto: 221600),
                MesAvance(id: 3, mes: "Agosto", monto: 234200)
             ]),
        MetaAvance(id: 1, nombre: "Dispensarios Médicos", linea: "Salud",
             cobrado: 273000, objetivo: 420000, comprometido: 338000,
             color: .orange, donantes: 612,
             mensual: [
                MesAvance(id: 1, mes: "Junio", monto: 84300),
                MesAvance(id: 2, mes: "Julio", monto: 91200),
                MesAvance(id: 3, mes: "Agosto", monto: 97500)
             ]),
        MetaAvance(id: 2, nombre: "Posada del Peregrino", linea: "Albergue",
             cobrado: 239200, objetivo: 260000, comprometido: 251000,
             color: .green, donantes: 184,
             mensual: [
                MesAvance(id: 1, mes: "Junio", monto: 76100),
                MesAvance(id: 2, mes: "Julio", monto: 79400),
                MesAvance(id: 3, mes: "Agosto", monto: 83700)
             ]),
        MetaAvance(id: 3, nombre: "Promoción Humana", linea: "Educación",
             cobrado: 164300, objetivo: 310000, comprometido: 212400,
             color: .red, donantes: 498,
             mensual: [
                MesAvance(id: 1, mes: "Junio", monto: 52800),
                MesAvance(id: 2, mes: "Julio", monto: 54100),
                MesAvance(id: 3, mes: "Agosto", monto: 57400)
             ]),
        MetaAvance(id: 4, nombre: "Banco de Medicamentos", linea: "Salud",
             cobrado: 471700, objetivo: 590000, comprometido: 538600,
             color: .green, donantes: 906,
             mensual: [
                MesAvance(id: 1, mes: "Junio", monto: 148900),
                MesAvance(id: 2, mes: "Julio", monto: 156200),
                MesAvance(id: 3, mes: "Agosto", monto: 166600)
             ])
    ]

    var datosPastel: [Rebanada] {
        let meta = metas[metaSeleccionada]
        return [
            Rebanada(id: 1, categoria: "Cobrado", valor: meta.cobrado),
            Rebanada(id: 2, categoria: "Faltante", valor: meta.objetivo - meta.cobrado)
        ]
    }

    func porcentaje(_ meta: MetaAvance) -> Int {
        return Int(meta.cobrado / meta.objetivo * 100)
    }

    func dinero(_ cantidad: Double) -> String {
        return "$" + Int(cantidad).formatted()
    }

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Text("Metas")
                    .font(.title2)
                    .bold()

                Spacer()

                Picker("Periodo", selection: $periodo) {
                    ForEach(periodos, id: \.self) { p in
                        Text(p)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 450)

                Spacer()

                Text("MG")
                    .bold()
                    .foregroundColor(.white)
                    .frame(width: 45, height: 45)
                    .background(azulCaritas)
                    .clipShape(Circle())
            }
            .padding()
            .background(Palette.superficie)

            Divider()

            HStack(spacing: 0) {

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Metas del periodo")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()

                        ForEach(metas) { meta in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(meta.color)
                                        .frame(width: 10, height: 10)
                                    Text(meta.nombre)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(porcentaje(meta))%")
                                        .font(.headline)
                                        .foregroundColor(azulCaritas)
                                }

                                ProgressView(value: meta.cobrado, total: meta.objetivo)
                                    .tint(azulCaritas)
                                    .scaleEffect(x: 1, y: 2)
                                    .padding(.vertical, 4)

                                Text("\(dinero(meta.cobrado)) de \(dinero(meta.objetivo))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(metaSeleccionada == meta.id ? azulClaro : Palette.superficie)
                            .onTapGesture {
                                metaSeleccionada = meta.id
                            }

                            Divider()
                        }
                    }
                }
                .frame(width: 380)
                .background(Palette.superficie)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        Text("\(metas[metaSeleccionada].linea) · Procuración de Fondos")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Text(metas[metaSeleccionada].nombre)
                            .font(.largeTitle)
                            .bold()

                        HStack(spacing: 30) {

                            ZStack {
                                Chart(datosPastel) { item in
                                    SectorMark(
                                        angle: .value("Valor", item.valor),
                                        innerRadius: .ratio(0.7)
                                    )
                                    .foregroundStyle(by: .value("Categoría", item.categoria))
                                }
                                .chartForegroundStyleScale([
                                    "Cobrado": azulCaritas,
                                    "Faltante": Color.gray.opacity(0.3)
                                ])
                                .chartLegend(.hidden)

                                Text("\(porcentaje(metas[metaSeleccionada]))%")
                                    .font(.system(size: 36))
                                    .bold()
                                    .foregroundColor(azulCaritas)
                            }
                            .frame(width: 180, height: 180)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Avance del periodo")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Text("\(dinero(metas[metaSeleccionada].cobrado)) de \(dinero(metas[metaSeleccionada].objetivo))")
                                    .font(.title2)
                                    .bold()

                                HStack {
                                    Circle()
                                        .fill(azulCaritas)
                                        .frame(width: 10, height: 10)
                                    Text("Cobrado")
                                }

                                HStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 10, height: 10)
                                    Text("Faltante")
                                }
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Palette.superficie)
                        .cornerRadius(15)

                        HStack(spacing: 15) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Comprometido")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(dinero(metas[metaSeleccionada].comprometido))
                                    .font(.title2)
                                    .bold()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Palette.superficie)
                            .cornerRadius(15)

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Cobrado")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(dinero(metas[metaSeleccionada].cobrado))
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(azulCaritas)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Palette.superficie)
                            .cornerRadius(15)

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Faltante")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(dinero(metas[metaSeleccionada].objetivo - metas[metaSeleccionada].cobrado))
                                    .font(.title2)
                                    .bold()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Palette.superficie)
                            .cornerRadius(15)
                        }

                        VStack(alignment: .leading) {
                            Text("Avance mensual")
                                .font(.headline)

                            Chart(metas[metaSeleccionada].mensual) { item in
                                BarMark(
                                    x: .value("Mes", item.mes),
                                    y: .value("Monto", item.monto)
                                )
                                .foregroundStyle(azulCaritas)
                            }
                            .frame(height: 220)
                        }
                        .padding()
                        .background(Palette.superficie)
                        .cornerRadius(15)

                        Text("\(metas[metaSeleccionada].donantes.formatted()) donantes activos")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(25)
                }
                .background(fondo)
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    MetasView()
}
