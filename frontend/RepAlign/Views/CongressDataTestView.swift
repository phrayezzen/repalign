import SwiftUI

struct CongressDataTestView: View {
    @State private var viewModel = LegislatorListViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Congress Data Integration")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Repository Pattern Demo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Status Card
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Data Source")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(dataSourceName)
                                .font(.headline)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Members Loaded")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.legislators.count)")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }

                    Divider()

                    HStack {
                        StatCard(title: "Senators", count: viewModel.senatorCount, color: .blue)
                        StatCard(title: "Representatives", count: viewModel.representativeCount, color: .green)
                    }

                    HStack {
                        StatCard(title: "Democrats", count: viewModel.democratCount, color: .blue)
                        StatCard(title: "Republicans", count: viewModel.republicanCount, color: .red)
                        StatCard(title: "Independents", count: viewModel.independentCount, color: .purple)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await viewModel.loadLegislators()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "tray.and.arrow.down")
                            }
                            Text("Load from Repository")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading)

                    Button(action: {
                        Task {
                            await viewModel.refreshLegislators()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync from API")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer()

                // Bottom info
                VStack(spacing: 4) {
                    Text("🔄 Repository Pattern Active")
                        .font(.caption)
                        .foregroundColor(.green)

                    Text("Switch data sources by changing AppConfig.dataSource")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("Integration Test")
            .task {
                await viewModel.loadLegislators()
            }
        }
    }

    private var dataSourceName: String {
        switch AppConfig.shared.dataSource {
        case .congressAPI:
            return "Congress.gov API"
        case .customBackend:
            return "RepAlign Backend"
        case .mockData:
            return "Mock Data"
        }
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    CongressDataTestView()
}