import SwiftUI

struct PerfilView: View {
    @EnvironmentObject private var sesion: SesionService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let usuario = sesion.usuario {
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(Palette.turquesa)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(usuario.nombre)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text(usuario.correo)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Section {
                        renglon(titulo: "Rol", valor: usuario.rol.capitalized)
                        renglon(titulo: "Área", valor: usuario.area)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        dismiss()
                        sesion.cerrarSesion()
                    } label: {
                        Text("Cerrar sesión")
                    }
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }

    func renglon(titulo: String, valor: String) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    PerfilView()
        .environmentObject(SesionService())
}
