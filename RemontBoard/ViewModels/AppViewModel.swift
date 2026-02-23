import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var rooms             : [Room]            = []
    @Published var budgetCategories  : [BudgetCategory]  = []
    @Published var scheduleEvents    : [ScheduleEvent]   = []

    private let persistence = PersistenceManager.shared

    init() { load() }

    // MARK: - Load / Save
    func load() {
        rooms            = persistence.loadRooms()
        budgetCategories = persistence.loadBudgetCategories()
        scheduleEvents   = persistence.loadScheduleEvents()
        if rooms.isEmpty { seedDefaultRooms() }
    }

    private func save() {
        persistence.saveRooms(rooms)
        persistence.saveBudgetCategories(budgetCategories)
        persistence.saveScheduleEvents(scheduleEvents)
    }

    private func seedDefaultRooms() {
        rooms = [
            Room(name: "Kitchen",     emoji: "🍳", area: 12),
            Room(name: "Living Room", emoji: "🛋️", area: 20),
            Room(name: "Bedroom",     emoji: "🛏️", area: 16),
            Room(name: "Bathroom",    emoji: "🚿", area: 6),
            Room(name: "Balcony",     emoji: "🌿", area: 4)
        ]
        save()
    }

    // MARK: - Rooms
    func addRoom(_ room: Room) {
        rooms.append(room)
        save()
    }

    func updateRoom(_ room: Room) {
        guard let idx = rooms.firstIndex(where: { $0.id == room.id }) else { return }
        rooms[idx] = room
        save()
    }

    func deleteRoom(_ room: Room) {
        rooms.removeAll { $0.id == room.id }
        save()
    }

    // MARK: - Tasks
    func addTask(_ task: RenovationTask, to roomId: UUID) {
        guard let idx = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        rooms[idx].tasks.append(task)
        save()
    }

    func updateTask(_ task: RenovationTask, in roomId: UUID) {
        guard let rIdx = rooms.firstIndex(where: { $0.id == roomId }),
              let tIdx = rooms[rIdx].tasks.firstIndex(where: { $0.id == task.id })
        else { return }
        rooms[rIdx].tasks[tIdx] = task
        save()
    }

    func deleteTask(_ task: RenovationTask, from roomId: UUID) {
        guard let idx = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        rooms[idx].tasks.removeAll { $0.id == task.id }
        save()
    }

    // MARK: - Materials
    func addMaterial(_ material: Material, to roomId: UUID) {
        guard let idx = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        rooms[idx].materials.append(material)
        save()
    }

    func updateMaterial(_ material: Material, in roomId: UUID) {
        guard let rIdx = rooms.firstIndex(where: { $0.id == roomId }),
              let mIdx = rooms[rIdx].materials.firstIndex(where: { $0.id == material.id })
        else { return }
        rooms[rIdx].materials[mIdx] = material
        save()
    }

    func deleteMaterial(_ material: Material, from roomId: UUID) {
        guard let idx = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        rooms[idx].materials.removeAll { $0.id == material.id }
        save()
    }

    // MARK: - Defects
    func addDefect(_ defect: Defect, to roomId: UUID) {
        guard let idx = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        rooms[idx].defects.append(defect)
        save()
    }

    func updateDefect(_ defect: Defect, in roomId: UUID) {
        guard let rIdx = rooms.firstIndex(where: { $0.id == roomId }),
              let dIdx = rooms[rIdx].defects.firstIndex(where: { $0.id == defect.id })
        else { return }
        rooms[rIdx].defects[dIdx] = defect
        save()
    }

    func deleteDefect(_ defect: Defect, from roomId: UUID) {
        guard let idx = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        rooms[idx].defects.removeAll { $0.id == defect.id }
        save()
    }

    // MARK: - Photos
    func addPhoto(_ data: Data, to roomId: UUID) {
        guard let idx = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        rooms[idx].photoDataList.append(data)
        save()
    }

    // MARK: - Budget
    func updateBudgetCategory(_ cat: BudgetCategory) {
        guard let idx = budgetCategories.firstIndex(where: { $0.id == cat.id }) else { return }
        budgetCategories[idx] = cat
        save()
    }

    var totalPlanned       : Double { budgetCategories.reduce(0) { $0 + $1.planned } }
    var totalActual        : Double { budgetCategories.reduce(0) { $0 + $1.actual } }
    var totalMaterialsActual: Double { rooms.reduce(0) { $0 + $1.totalMaterialCost } }
    var totalLaborActual   : Double { rooms.reduce(0) { $0 + $1.totalTaskCost } }

    // MARK: - Schedule
    func addScheduleEvent(_ event: ScheduleEvent) {
        scheduleEvents.append(event)
        save()
    }

    func updateScheduleEvent(_ event: ScheduleEvent) {
        guard let idx = scheduleEvents.firstIndex(where: { $0.id == event.id }) else { return }
        scheduleEvents[idx] = event
        save()
    }

    func deleteScheduleEvent(_ event: ScheduleEvent) {
        scheduleEvents.removeAll { $0.id == event.id }
        save()
    }

    func eventsForDate(_ date: Date) -> [ScheduleEvent] {
        let cal = Calendar.current
        return scheduleEvents.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Stats
    var overallCompletion: Double {
        guard !rooms.isEmpty else { return 0 }
        let totalTasks = rooms.reduce(0) { $0 + $1.tasks.count }
        guard totalTasks > 0 else { return 0 }
        let done = rooms.reduce(0) { $0 + $1.tasks.filter { $0.status == .done }.count }
        return Double(done) / Double(totalTasks) * 100
    }

    var totalDefects : Int { rooms.reduce(0) { $0 + $1.defects.count } }
    var openDefects  : Int { rooms.reduce(0) { $0 + $1.defects.filter { !$0.isResolved }.count } }
}
