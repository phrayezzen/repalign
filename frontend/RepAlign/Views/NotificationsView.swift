import SwiftUI

struct NotificationsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "bell")
                    .font(.system(size: 80))
                    .foregroundColor(.secondary)

                Text("Notifications")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Stay updated with likes, comments, and follows from your network.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 60)
            .navigationTitle("Notifications")
        }
    }
}

#Preview {
    NotificationsView()
}