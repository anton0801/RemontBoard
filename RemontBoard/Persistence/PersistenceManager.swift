import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()

    private let roomsKey    = "remontboard_rooms_v2"
    private let budgetKey   = "remontboard_budget_v2"
    private let scheduleKey = "remontboard_schedule_v2"

    // MARK: - Rooms
    func saveRooms(_ rooms: [Room]) {
        if let data = try? JSONEncoder().encode(rooms) {
            UserDefaults.standard.set(data, forKey: roomsKey)
        }
    }

    func loadRooms() -> [Room] {
        guard let data = UserDefaults.standard.data(forKey: roomsKey),
              let rooms = try? JSONDecoder().decode([Room].self, from: data)
        else { return [] }
        return rooms
    }

    // MARK: - Budget
    func saveBudgetCategories(_ cats: [BudgetCategory]) {
        if let data = try? JSONEncoder().encode(cats) {
            UserDefaults.standard.set(data, forKey: budgetKey)
        }
    }

    func loadBudgetCategories() -> [BudgetCategory] {
        guard let data = UserDefaults.standard.data(forKey: budgetKey),
              let cats = try? JSONDecoder().decode([BudgetCategory].self, from: data)
        else { return Self.defaultBudgetCategories() }
        return cats
    }

    static func defaultBudgetCategories() -> [BudgetCategory] {
        [
            BudgetCategory(name: "Materials",   planned: 0, actual: 0, icon: "shippingbox.fill",           color: "#4A90D9"),
            BudgetCategory(name: "Labor",       planned: 0, actual: 0, icon: "person.fill",                color: "#F5C842"),
            BudgetCategory(name: "Delivery",    planned: 0, actual: 0, icon: "truck.box.fill",             color: "#5BC8A3"),
            BudgetCategory(name: "Unexpected",  planned: 0, actual: 0, icon: "exclamationmark.triangle.fill", color: "#E87D5A")
        ]
    }

    // MARK: - Schedule
    func saveScheduleEvents(_ events: [ScheduleEvent]) {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: scheduleKey)
        }
    }

    func loadScheduleEvents() -> [ScheduleEvent] {
        guard let data = UserDefaults.standard.data(forKey: scheduleKey),
              let events = try? JSONDecoder().decode([ScheduleEvent].self, from: data)
        else { return [] }
        return events
    }
}
