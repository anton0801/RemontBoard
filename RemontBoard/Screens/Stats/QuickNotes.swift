import SwiftUI

// MARK: - QuickNote model (new feature)
struct QuickNote: Identifiable, Codable {
    var id        = UUID()
    var text      : String
    var roomId    : UUID?
    var isPinned  : Bool
    var createdAt : Date
    var color     : String

    init(text: String, roomId: UUID? = nil, color: String = "#F5C842") {
        self.text      = text
        self.roomId    = roomId
        self.isPinned  = false
        self.createdAt = Date()
        self.color     = color
    }
}

// MARK: - QuickNoteViewModel
class QuickNoteViewModel: ObservableObject {
    @Published var notes: [QuickNote] = []
    private let key = "rb_quick_notes"

    init() { load() }

    func load() {
        guard let data  = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([QuickNote].self, from: data)
        else { return }
        notes = saved
    }

    func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(_ note: QuickNote) { notes.insert(note, at: 0); save() }
    func delete(_ note: QuickNote) { notes.removeAll { $0.id == note.id }; save() }
    func togglePin(_ note: QuickNote) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx].isPinned.toggle()
            notes.sort { $0.isPinned && !$1.isPinned }
            save()
        }
    }
}

// MARK: - QuickNoteSheet
struct QuickNoteSheet: View {
    @ObservedObject var vm: QuickNoteViewModel
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var text       = ""
    @State private var selectedRoom: UUID? = nil
    @State private var selectedColor = "#F5C842"

    let colors = ["#F5C842","#4A90D9","#5BC8A3","#E87D5A","#A78BFA","#FF6B9D"]

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.15)
                VStack(spacing: 20) {
                    // Text input
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Write a quick note…")
                                .foregroundColor(AppColors.secondaryText)
                                .font(.system(size: 15))
                                .padding(16)
                        }
                        TextEditor(text: $text)
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 100)
                            .padding(12)
                    }
                    .background(AppColors.cardBackground)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: selectedColor).opacity(0.4), lineWidth: 1.5))
                    .padding(.horizontal)

                    // Room tag
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Tag a Room (optional)").padding(.leading, 16)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button {
                                    withAnimation { selectedRoom = nil }
                                } label: {
                                    Text("None")
                                        .font(.system(size: 12, weight: selectedRoom == nil ? .bold : .regular))
                                        .foregroundColor(selectedRoom == nil ? AppColors.background : .white)
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(selectedRoom == nil ? AppColors.accent : AppColors.cardBackground)
                                        .cornerRadius(20)
                                }
                                ForEach(appVM.rooms) { room in
                                    Button {
                                        withAnimation { selectedRoom = room.id }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(room.emoji)
                                            Text(room.name)
                                                .font(.system(size: 12, weight: selectedRoom == room.id ? .bold : .regular))
                                        }
                                        .foregroundColor(selectedRoom == room.id ? AppColors.background : .white)
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(selectedRoom == room.id ? AppColors.accent : AppColors.cardBackground)
                                        .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Color
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Note Color").padding(.leading, 16)
                        HStack(spacing: 10) {
                            ForEach(colors, id: \.self) { c in
                                Circle()
                                    .fill(Color(hex: c))
                                    .frame(width: 28, height: 28)
                                    .overlay(Circle().stroke(.white, lineWidth: selectedColor == c ? 3 : 0))
                                    .scaleEffect(selectedColor == c ? 1.15 : 1)
                                    .animation(.spring(), value: selectedColor)
                                    .onTapGesture { withAnimation { selectedColor = c } }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }

                    YellowButton(title: "Save Note", disabled: text.trimmingCharacters(in: .whitespaces).isEmpty) {
                        let note = QuickNote(text: text.trimmingCharacters(in: .whitespaces),
                                             roomId: selectedRoom, color: selectedColor)
                        vm.add(note)
                        dismiss.wrappedValue.dismiss()
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                .padding(.top, 16)
            }
            .navigationTitle("Quick Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(AppColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - QuickNotesListView
struct QuickNotesListView: View {
    @ObservedObject var vm: QuickNoteViewModel
    @EnvironmentObject var appVM: AppViewModel
    @State private var showAdd = false

    var pinned: [QuickNote] { vm.notes.filter  {  $0.isPinned } }
    var other : [QuickNote] { vm.notes.filter  { !$0.isPinned } }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)

                Group {
                    if vm.notes.isEmpty {
                        EmptyStateView(icon: "note.text", message: "No quick notes.\nTap + to jot something down!")
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                if !pinned.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Label("Pinned", systemImage: "pin.fill")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(AppColors.accent)
                                            .padding(.leading, 4)
                                        ForEach(pinned) { note in
                                            QuickNoteCard(note: note, vm: vm, appVM: appVM)
                                        }
                                    }
                                }
                                if !other.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if !pinned.isEmpty {
                                            Label("Notes", systemImage: "note.text")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(AppColors.secondaryText)
                                                .padding(.leading, 4)
                                        }
                                        ForEach(other) { note in
                                            QuickNoteCard(note: note, vm: vm, appVM: appVM)
                                        }
                                    }
                                }
                            }
                            .padding().padding(.bottom, 80)
                        }
                    }
                }
            }
            .navigationTitle("Quick Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColors.accent).font(.system(size: 22))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAdd) {
            QuickNoteSheet(vm: vm).environmentObject(appVM)
        }
    }
}

struct QuickNoteCard: View {
    let note  : QuickNote
    let vm    : QuickNoteViewModel
    let appVM : AppViewModel

    var roomName: String? {
        guard let id = note.roomId else { return nil }
        return appVM.rooms.first { $0.id == id }.map { "\($0.emoji) \($0.name)" }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: note.color))
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 6) {
                Text(note.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(4)
                HStack(spacing: 10) {
                    if let room = roomName {
                        Label(room, systemImage: "building.2")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.accentBlue)
                    }
                    Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            Spacer()
            VStack(spacing: 8) {
                Button { vm.togglePin(note) } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 13))
                        .foregroundColor(note.isPinned ? AppColors.accent : AppColors.secondaryText)
                }
                Button { vm.delete(note) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.warning.opacity(0.7))
                }
            }
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: note.color).opacity(0.25), lineWidth: 1))
    }
}
