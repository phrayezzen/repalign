import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var eventType: EventType = .townHall
    @State private var eventDate = Date()
    @State private var eventEndDate = Date()
    @State private var location = ""
    @State private var address = ""
    @State private var isVirtual = false
    @State private var virtualLink = ""
    @State private var maxAttendees = ""
    @State private var note = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero Image Section
                    heroImageSection

                    // Basic Info Section
                    basicInfoSection

                    // Date & Time Section
                    dateTimeSection

                    // Location Section
                    locationSection

                    // Additional Details Section
                    additionalDetailsSection

                    // Create Button
                    createEventButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }

    private var heroImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Image")
                .font(.headline)
                .fontWeight(.semibold)

            Button(action: { showingImagePicker = true }) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                                Text("Add Photo")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Event Title")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Enter event title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Event Type")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Menu {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                eventType = type
                            }
                        }
                    } label: {
                        HStack {
                            Text(eventType.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Describe your event", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(4...8)
                }
            }
        }
    }

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date & Time")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Date & Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    DatePicker("", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("End Date & Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    DatePicker("", selection: $eventEndDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                }
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Virtual Event", isOn: $isVirtual)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))

                if isVirtual {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Virtual Link")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("https://", text: $virtualLink)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.URL)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Venue Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("e.g., Community Center", text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Address")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Full address", text: $address)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
            }
        }
    }

    private var additionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Details")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max Attendees")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Optional", text: $maxAttendees)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Additional Notes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., Doors open at 6:30 PM", text: $note)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }

    private var createEventButton: some View {
        Button(action: createEvent) {
            Text("Create Event")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isFormValid ? Color.red : Color.gray)
                .cornerRadius(25)
        }
        .disabled(!isFormValid)
    }

    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && (!location.isEmpty || isVirtual)
    }

    private func createEvent() {
        // TODO: Implement event creation logic
        // For now, just dismiss the view
        dismiss()
    }
}

// Use the existing EventType from Event model

// Simple image picker wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    CreateEventView()
}