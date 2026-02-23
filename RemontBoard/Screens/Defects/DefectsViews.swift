import SwiftUI

// MARK: - DefectsTab
struct DefectsTab: View {
    let room     : Room
    @Binding var showAdd: Bool
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                Button { showAdd = true } label: {
                    Label("Report Defect", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.background)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(AppColors.warning).cornerRadius(12)
                }
                .scaleButtonStyle()

                if room.defects.isEmpty {
                    EmptyStateView(icon: "checkmark.shield.fill",
                                   message: "No defects reported.\nGreat condition! 👍")
                } else {
                    let open   = room.defects.filter { !$0.isResolved }
                    let closed = room.defects.filter {  $0.isResolved }

                    if !open.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Open Issues (\(open.count))", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 12, weight: .bold)).foregroundColor(AppColors.warning)
                            ForEach(open) { d in
                                DefectCard(defect: d, roomId: room.id).environmentObject(appVM)
                            }
                        }
                    }
                    if !closed.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Resolved (\(closed.count))", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .bold)).foregroundColor(AppColors.success)
                            ForEach(closed) { d in
                                DefectCard(defect: d, roomId: room.id).environmentObject(appVM)
                            }
                        }
                    }
                }
            }
            .padding().padding(.bottom, 80)
        }
    }
}

// MARK: - DefectCard
struct DefectCard: View {
    let defect: Defect; let roomId: UUID
    @EnvironmentObject var appVM: AppViewModel
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Image(systemName: defect.type.icon)
                    .font(.system(size: 22))
                    .foregroundColor(defect.isResolved ? AppColors.success : defect.type.color)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(defect.type.rawValue)
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    if defect.isResolved {
                        Text("FIXED")
                            .font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(AppColors.success).cornerRadius(4)
                    }
                }
                if !defect.description.isEmpty {
                    Text(defect.description)
                        .font(.system(size: 11)).foregroundColor(AppColors.secondaryText).lineLimit(2)
                }
                if !defect.location.isEmpty {
                    Label(defect.location, systemImage: "mappin")
                        .font(.system(size: 10)).foregroundColor(AppColors.secondaryText)
                }
                Text(defect.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 9)).foregroundColor(AppColors.secondaryText.opacity(0.6))
            }
            Spacer()
            if let data = defect.photoData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable().scaledToFill()
                    .frame(width: 52, height: 52).cornerRadius(8).clipped()
            }
        }
        .padding(12)
        .background(AppColors.cardBackground).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(defect.isResolved ? AppColors.success.opacity(0.28) : defect.type.color.opacity(0.28), lineWidth: 1))
        .onTapGesture { toggleResolved() }
    }

    private func toggleResolved() {
        var u = defect; u.isResolved.toggle()
        withAnimation { appVM.updateDefect(u, in: roomId) }
    }
}

// MARK: - AddDefectView
struct AddDefectView: View {
    let roomId: UUID
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var defectType    : DefectType = .crack
    @State private var description   = ""
    @State private var location      = ""
    @State private var showPicker    = false
    @State private var selectedImage : UIImage?

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)
                ScrollView {
                    VStack(spacing: 16) {
                        // Type grid
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Defect Type").padding(.leading, 16)
                            LazyVGrid(columns: [GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible())], spacing: 10) {
                                ForEach(DefectType.allCases, id: \.self) { type in
                                    Button { defectType = type } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: type.icon).font(.system(size: 22))
                                                .foregroundColor(defectType == type ? .white : type.color)
                                            Text(type.rawValue).font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(defectType == type ? .white : .white.opacity(0.7))
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(defectType == type ? type.color : type.color.opacity(0.14))
                                        .cornerRadius(12)
                                    }
                                    .scaleButtonStyle()
                                }
                            }
                            .padding(.horizontal)
                        }

                        FormField(label: "Description", placeholder: "Describe the defect…", text: $description)
                        FormField(label: "Location",    placeholder: "e.g. North wall, near window", text: $location)

                        // Photo
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Photo Evidence").padding(.leading, 16)
                            if let img = selectedImage {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(height: 150).cornerRadius(12).clipped()
                                    .padding(.horizontal)
                                    .onTapGesture { showPicker = true }
                            } else {
                                Button { showPicker = true } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill").font(.system(size: 26))
                                            .foregroundColor(AppColors.accentBlue)
                                        Text("Add Photo").font(.system(size: 13))
                                            .foregroundColor(AppColors.accentBlue)
                                    }
                                    .frame(maxWidth: .infinity).frame(height: 80)
                                    .background(AppColors.accentBlue.opacity(0.08))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.accentBlue.opacity(0.3),
                                                style: StrokeStyle(lineWidth: 1.5, dash: [6])))
                                }
                                .padding(.horizontal)
                            }
                        }

                        YellowButton(title: "Report Defect", disabled: false) { save() }
                            .padding(.horizontal).padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Report Defect").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
            }}
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPicker) { DefectImagePicker(image: $selectedImage) }
    }

    private func save() {
        let data = selectedImage?.jpegData(compressionQuality: 0.7)
        let defect = Defect(type: defectType, description: description, location: location, photoData: data)
        appVM.addDefect(defect, to: roomId)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - DefectsOverviewView (global tab)
struct DefectsOverviewView: View {
    @EnvironmentObject var appVM: AppViewModel

    var allDefects: [(room: Room, defect: Defect)] {
        appVM.rooms.flatMap { r in r.defects.map { (r, $0) } }
    }
    var openCount: Int { allDefects.filter { !$0.defect.isResolved }.count }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.22)

                ScrollView {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            StatChip(icon: "exclamationmark.triangle.fill",
                                     value: "\(allDefects.count)", label: "Total",   color: AppColors.warning)
                            StatChip(icon: "xmark.circle.fill",
                                     value: "\(openCount)",          label: "Open",    color: .red)
                            StatChip(icon: "checkmark.circle.fill",
                                     value: "\(allDefects.count - openCount)", label: "Fixed", color: AppColors.success)
                        }
                        .padding(.horizontal)

                        if allDefects.isEmpty {
                            EmptyStateView(icon: "checkmark.shield.fill",
                                           message: "No defects recorded.\nYour apartment is in great shape! 🏠")
                                .padding(.top, 40)
                        } else {
                            ForEach(DefectType.allCases, id: \.self) { type in
                                let filtered = allDefects.filter { $0.defect.type == type }
                                if !filtered.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: type.icon).foregroundColor(type.color)
                                            Text(type.rawValue)
                                                .font(.system(size: 13, weight: .bold)).foregroundColor(type.color)
                                            Text("(\(filtered.count))")
                                                .font(.system(size: 11)).foregroundColor(AppColors.secondaryText)
                                        }
                                        .padding(.horizontal)
                                        ForEach(filtered, id: \.defect.id) { item in
                                            OverviewDefectRow(room: item.room, defect: item.defect)
                                                .environmentObject(appVM)
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 8).padding(.bottom, 100)
                }
            }
            .navigationTitle("Defect Journal")
            .preferredColorScheme(.dark)
        }
        .navigationViewStyle(.stack)
    }
}

struct OverviewDefectRow: View {
    let room  : Room
    let defect: Defect
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        HStack(spacing: 12) {
            Text(room.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(room.name).font(.system(size: 11)).foregroundColor(AppColors.secondaryText)
                if !defect.description.isEmpty {
                    Text(defect.description).font(.system(size: 13)).foregroundColor(.white).lineLimit(1)
                }
                if !defect.location.isEmpty {
                    Text(defect.location).font(.system(size: 10)).foregroundColor(AppColors.secondaryText)
                }
            }
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: defect.isResolved ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(defect.isResolved ? AppColors.success : AppColors.warning)
                Text(defect.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 8)).foregroundColor(AppColors.secondaryText)
            }
            if let data = defect.photoData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
                    .frame(width: 40, height: 40).cornerRadius(6).clipped()
            }
        }
        .padding(12)
        .background(AppColors.cardBackground).cornerRadius(12)
        .onTapGesture {
            var u = defect; u.isResolved.toggle()
            withAnimation { appVM.updateDefect(u, in: room.id) }
        }
    }
}

// MARK: - DefectImagePicker
struct DefectImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var dismiss

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: DefectImagePicker
        init(_ p: DefectImagePicker) { parent = p }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss.wrappedValue.dismiss()
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.delegate = context.coordinator
        p.sourceType = .photoLibrary
        return p
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
}
