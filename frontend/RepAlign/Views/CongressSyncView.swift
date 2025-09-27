import SwiftUI

struct CongressSyncView: View {
    @State private var viewModel = LegislatorListViewModel()
    @State private var showingAPIKeyAlert = false

    var body: some View {
        NavigationView {
            List {
                syncSection
                statusSection
                statisticsSection
                configurationSection
            }
            .navigationTitle("Congress Data")
            .alert("API Key Required", isPresented: $showingAPIKeyAlert) {
                Button("OK") { }
            } message: {
                Text("Please add your Congress.gov API key in AppConfig.swift to sync real data.")
            }
        }
    }

    private var syncSection: some View {
        Section("Data Sync") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sync Congress Members")
                            .font(.headline)

                        Text("Fetch all 535 current Congress members from Congress.gov API")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                HStack(spacing: 12) {
                    Button(action: {
                        Task {
                            if AppConfig.congressAPIKey == "YOUR_API_KEY_HERE" {
                                showingAPIKeyAlert = true
                            } else {
                                await viewModel.refreshLegislators()
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync Now")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isLoading)

                    Button(action: {
                        Task {
                            await viewModel.loadLegislators()
                        }
                    }) {
                        HStack {
                            Image(systemName: "tray.and.arrow.down")
                            Text("Load Cache")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isLoading)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var statusSection: some View {
        Section("Status") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Data Source:")
                    Spacer()
                    Text(dataSourceName)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Cache Status:")
                    Spacer()
                    HStack {
                        Circle()
                            .fill(cacheStatusColor)
                            .frame(width: 8, height: 8)
                        Text(cacheStatusText)
                            .foregroundColor(.secondary)
                    }
                }

                if let lastSync = getLastSyncDate() {
                    HStack {
                        Text("Last Sync:")
                        Spacer()
                        Text(RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var statisticsSection: some View {
        Section("Statistics") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Members:")
                    Spacer()
                    Text("\(viewModel.legislators.count)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Senators:")
                    Spacer()
                    Text("\(viewModel.senatorCount)")
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("Representatives:")
                    Spacer()
                    Text("\(viewModel.representativeCount)")
                        .foregroundColor(.green)
                }

                Divider()

                HStack {
                    Text("Democrats:")
                    Spacer()
                    Text("\(viewModel.democratCount)")
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("Republicans:")
                    Spacer()
                    Text("\(viewModel.republicanCount)")
                        .foregroundColor(.red)
                }

                HStack {
                    Text("Independents:")
                    Spacer()
                    Text("\(viewModel.independentCount)")
                        .foregroundColor(.purple)
                }
            }
        }
    }

    private var configurationSection: some View {
        Section("Configuration") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("API Key Status:")
                    Spacer()
                    HStack {
                        Circle()
                            .fill(apiKeyStatusColor)
                            .frame(width: 8, height: 8)
                        Text(apiKeyStatusText)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("Congress:")
                    Spacer()
                    Text("\(AppConfig.currentCongress)th Congress")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Rate Limit:")
                    Spacer()
                    Text("\(AppConfig.apiRateLimit) req/hour")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var dataSourceName: String {
        switch AppConfig.dataSource {
        case .congressAPI:
            return "Congress.gov API"
        case .customBackend:
            return "RepAlign Backend"
        case .mockData:
            return "Mock Data"
        }
    }

    private var cacheStatusColor: Color {
        if viewModel.legislators.isEmpty {
            return .red
        } else if viewModel.shouldShowRefreshButton {
            return .orange
        } else {
            return .green
        }
    }

    private var cacheStatusText: String {
        if viewModel.legislators.isEmpty {
            return "No Data"
        } else if viewModel.shouldShowRefreshButton {
            return "Needs Refresh"
        } else {
            return "Up to Date"
        }
    }

    private var apiKeyStatusColor: Color {
        return AppConfig.congressAPIKey == "YOUR_API_KEY_HERE" ? .red : .green
    }

    private var apiKeyStatusText: String {
        return AppConfig.congressAPIKey == "YOUR_API_KEY_HERE" ? "Not Configured" : "Configured"
    }

    private func getLastSyncDate() -> Date? {
        // This would need to be implemented to get the actual last sync date
        // For now, return a placeholder
        return nil
    }
}

#Preview {
    CongressSyncView()
}