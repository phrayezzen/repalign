import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Data") {
                    NavigationLink(destination: CongressSyncView()) {
                        HStack {
                            Image(systemName: "building.columns")
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Congress Data")
                                    .font(.headline)

                                Text("Sync real legislators from Congress.gov")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    NavigationLink(destination: CongressDataTestView()) {
                        HStack {
                            Image(systemName: "flask")
                                .foregroundColor(.purple)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Integration Test")
                                    .font(.headline)

                                Text("Test repository pattern and data flow")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Account") {
                    SettingsRow(
                        icon: "person.circle",
                        title: "Profile",
                        subtitle: "Manage your profile information",
                        iconColor: .green
                    )

                    SettingsRow(
                        icon: "bell",
                        title: "Notifications",
                        subtitle: "Configure notification preferences",
                        iconColor: .orange
                    )

                    SettingsRow(
                        icon: "lock",
                        title: "Privacy",
                        subtitle: "Privacy and security settings",
                        iconColor: .red
                    )
                }

                Section("App") {
                    SettingsRow(
                        icon: "questionmark.circle",
                        title: "Help & Support",
                        subtitle: "Get help using RepAlign",
                        iconColor: .blue
                    )

                    SettingsRow(
                        icon: "info.circle",
                        title: "About",
                        subtitle: "Version and app information",
                        iconColor: .gray
                    )
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}