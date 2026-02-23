import SwiftUI

struct EditRoomView: View {
    let room: Room
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var name          : String
    @State private var area          : String
    @State private var emoji         : String
    @State private var renovationType: RenovationType
    @State private var floorType     : FloorType
    @State private var wallType      : WallType
    @State private var ceilingType   : CeilingType
    @State private var hasElectrical : Bool
    @State private var notes         : String
    @State private var showDeleteAlert = false

    let emojiOptions = ["🏠","🍳","🛋️","🛏️","🚿","🌿","🖥️","📚","👗","🎮","🏋️","🍽️"]

    init(room: Room) {
        self.room = room
        _name           = State(initialValue: room.name)
        _area           = State(initialValue: room.area > 0 ? String(format: "%.1f", room.area) : "")
        _emoji          = State(initialValue: room.emoji)
        _renovationType = State(initialValue: room.renovationType)
        _floorType      = State(initialValue: room.floorType)
        _wallType       = State(initialValue: room.wallType)
        _ceilingType    = State(initialValue: room.ceilingType)
        _hasElectrical  = State(initialValue: room.hasElectricalWork)
        _notes          = State(initialValue: room.notes)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)

                ScrollView {
                    VStack(spacing: 18) {
                        // Emoji picker
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "Icon").padding(.leading, 16)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(emojiOptions, id: \.self) { e in
                                        Text(e).font(.system(size: 28))
                                            .padding(10)
                                            .background(emoji == e ? AppColors.accent.opacity(0.2) : AppColors.cardBackground)
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12)
                                                .stroke(emoji == e ? AppColors.accent : Color.clear, lineWidth: 2))
                                            .onTapGesture { emoji = e }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        FormField(label: "Room Name",  placeholder: "Name",  text: $name)
                        FormField(label: "Area (m²)",  placeholder: "0",     text: $area)
                        FormField(label: "Notes",      placeholder: "Any notes…", text: $notes)

                        PickerField(label: "Renovation Type", selection: $renovationType, options: RenovationType.allCases)
                        PickerField(label: "Floor Type",      selection: $floorType,      options: FloorType.allCases)
                        PickerField(label: "Wall Coverage",   selection: $wallType,       options: WallType.allCases)
                        PickerField(label: "Ceiling Type",    selection: $ceilingType,    options: CeilingType.allCases)

                        HStack {
                            SectionLabel(text: "Electrical Work")
                            Spacer()
                            Toggle("", isOn: $hasElectrical).tint(AppColors.accent)
                        }
                        .padding(.horizontal)

                        HStack(spacing: 12) {
                            YellowButton(title: "Save Changes", disabled: name.isEmpty) { save() }
                            Button { showDeleteAlert = true } label: {
                                Image(systemName: "trash").foregroundColor(AppColors.warning)
                                    .padding(16)
                                    .background(AppColors.warning.opacity(0.14))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Edit Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
                }
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete \(room.name)?"),
                    message: Text("All tasks, materials and defects will be removed."),
                    primaryButton: .destructive(Text("Delete")) { deleteRoom() },
                    secondaryButton: .cancel()
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        var updated = room
        updated.name              = name
        updated.emoji             = emoji
        updated.area              = Double(area) ?? 0
        updated.renovationType    = renovationType
        updated.floorType         = floorType
        updated.wallType          = wallType
        updated.ceilingType       = ceilingType
        updated.hasElectricalWork = hasElectrical
        updated.notes             = notes
        appVM.updateRoom(updated)
        dismiss.wrappedValue.dismiss()
    }

    private func deleteRoom() {
        appVM.deleteRoom(room)
        dismiss.wrappedValue.dismiss()
    }
}
