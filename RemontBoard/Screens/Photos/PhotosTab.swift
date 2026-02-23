import SwiftUI

// MARK: - PhotosTab
struct PhotosTab: View {
    let room      : Room
    @Binding var showPicker: Bool
    @EnvironmentObject var appVM: AppViewModel

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Button { showPicker = true } label: {
                    Label("Add Photo", systemImage: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.background)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(AppColors.accent).cornerRadius(12)
                }
                .scaleButtonStyle()

                if room.photoDataList.isEmpty {
                    EmptyStateView(icon: "photo.on.rectangle",
                                   message: "No photos yet.\nDocument your renovation progress!")
                } else {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(Array(room.photoDataList.enumerated()), id: \.offset) { _, data in
                            if let ui = UIImage(data: data) {
                                Image(uiImage: ui)
                                    .resizable().scaledToFill()
                                    .frame(height: 110).clipped().cornerRadius(8)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
            }
            .padding().padding(.bottom, 80)
        }
    }
}

// MARK: - ImagePickerView
struct ImagePickerView: UIViewControllerRepresentable {
    let roomId: UUID
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        init(_ p: ImagePickerView) { parent = p }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data  = image.jpegData(compressionQuality: 0.72) {
                parent.appVM.addPhoto(data, to: parent.roomId)
            }
            parent.dismiss.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
}
