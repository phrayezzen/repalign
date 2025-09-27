import SwiftUI

struct MessagesView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "message")
                    .font(.system(size: 80))
                    .foregroundColor(.secondary)

                Text("Messages")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Connect directly with citizens and legislators through private messaging.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 60)
            .navigationTitle("Messages")
        }
    }
}

#Preview {
    MessagesView()
}