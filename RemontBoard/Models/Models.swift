import Foundation
import SwiftUI

// MARK: - Enums

enum RenovationType: String, CaseIterable, Codable {
    case cosmetic = "Cosmetic"
    case major = "Major"
    case designer = "Designer"

    var icon: String {
        switch self {
        case .cosmetic: return "paintbrush.fill"
        case .major:    return "hammer.fill"
        case .designer: return "star.fill"
        }
    }
}

enum FloorType: String, CaseIterable, Codable {
    case laminate = "Laminate"
    case tile     = "Tile"
    case parquet  = "Parquet"
    case linoleum = "Linoleum"
    case carpet   = "Carpet"
}

enum WallType: String, CaseIterable, Codable {
    case paint    = "Paint"
    case wallpaper = "Wallpaper"
    case tile     = "Tile"
    case plaster  = "Decorative Plaster"
}

enum CeilingType: String, CaseIterable, Codable {
    case stretch      = "Stretch"
    case plasterboard = "Plasterboard"
    case paint        = "Paint"
    case suspended    = "Suspended"
}

enum TaskStatus: String, Codable {
    case todo       = "To Do"
    case inProgress = "In Progress"
    case done       = "Done"

    var color: Color {
        switch self {
        case .todo:       return .gray
        case .inProgress: return Color(hex: "#F5C842")
        case .done:       return Color(hex: "#5BC8A3")
        }
    }

    var icon: String {
        switch self {
        case .todo:       return "circle"
        case .inProgress: return "clock.fill"
        case .done:       return "checkmark.circle.fill"
        }
    }
}

enum DefectType: String, CaseIterable, Codable {
    case crack      = "Crack"
    case unevenness = "Unevenness"
    case dampness   = "Dampness"
    case leak       = "Leak"
    case mold       = "Mold"
    case other      = "Other"

    var icon: String {
        switch self {
        case .crack:      return "bolt.fill"
        case .unevenness: return "level.fill"
        case .dampness:   return "drop.fill"
        case .leak:       return "exclamationmark.triangle.fill"
        case .mold:       return "leaf.fill"
        case .other:      return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .crack:      return .orange
        case .unevenness: return .yellow
        case .dampness:   return .blue
        case .leak:       return .red
        case .mold:       return .green
        case .other:      return .gray
        }
    }
}

enum MaterialCategory: String, CaseIterable, Codable {
    case flooring   = "Flooring"
    case walls      = "Walls"
    case ceiling    = "Ceiling"
    case electrical = "Electrical"
    case plumbing   = "Plumbing"
    case other      = "Other"
}

enum MaterialTier: String, CaseIterable, Codable {
    case budget  = "Budget"
    case mid     = "Mid-Range"
    case premium = "Premium"

    var color: Color {
        switch self {
        case .budget:  return .green
        case .mid:     return Color(hex: "#F5C842")
        case .premium: return .purple
        }
    }
}

// MARK: - Models

struct Room: Identifiable, Codable {
    var id             = UUID()
    var name           : String
    var emoji          : String
    var area           : Double
    var renovationType : RenovationType
    var floorType      : FloorType
    var wallType       : WallType
    var ceilingType    : CeilingType
    var hasElectricalWork: Bool
    var tasks          : [RenovationTask]
    var materials      : [Material]
    var defects        : [Defect]
    var photoDataList  : [Data]
    var notes          : String

    var completionPercentage: Double {
        guard !tasks.isEmpty else { return 0 }
        let done = tasks.filter { $0.status == .done }.count
        return Double(done) / Double(tasks.count) * 100
    }

    var totalMaterialCost: Double { materials.reduce(0) { $0 + $1.totalCost } }
    var totalTaskCost: Double     { tasks.reduce(0) { $0 + $1.laborCost } }

    init(name: String, emoji: String,
         area: Double = 0,
         renovationType: RenovationType = .cosmetic,
         floorType: FloorType = .laminate,
         wallType: WallType = .paint,
         ceilingType: CeilingType = .paint,
         hasElectricalWork: Bool = false) {
        self.name              = name
        self.emoji             = emoji
        self.area              = area
        self.renovationType    = renovationType
        self.floorType         = floorType
        self.wallType          = wallType
        self.ceilingType       = ceilingType
        self.hasElectricalWork = hasElectricalWork
        self.tasks             = []
        self.materials         = []
        self.defects           = []
        self.photoDataList     = []
        self.notes             = ""
    }
}

struct RenovationTask: Identifiable, Codable {
    var id         = UUID()
    var title      : String
    var status     : TaskStatus
    var deadline   : Date?
    var laborCost  : Double
    var comment    : String
    var assignee   : String
    var createdAt  : Date

    init(title: String, status: TaskStatus = .todo,
         deadline: Date? = nil, laborCost: Double = 0,
         comment: String = "", assignee: String = "") {
        self.title     = title
        self.status    = status
        self.deadline  = deadline
        self.laborCost = laborCost
        self.comment   = comment
        self.assignee  = assignee
        self.createdAt = Date()
    }
}

struct Material: Identifiable, Codable {
    var id           = UUID()
    var name         : String
    var category     : MaterialCategory
    var quantity     : Double
    var unit         : String
    var pricePerUnit : Double
    var tier         : MaterialTier
    var supplier     : String

    var totalCost: Double { quantity * pricePerUnit }

    init(name: String, category: MaterialCategory = .other,
         quantity: Double = 1, unit: String = "pcs",
         pricePerUnit: Double = 0, tier: MaterialTier = .mid,
         supplier: String = "") {
        self.name         = name
        self.category     = category
        self.quantity     = quantity
        self.unit         = unit
        self.pricePerUnit = pricePerUnit
        self.tier         = tier
        self.supplier     = supplier
    }
}

struct Defect: Identifiable, Codable {
    var id          = UUID()
    var type        : DefectType
    var description : String
    var isResolved  : Bool
    var photoData   : Data?
    var createdAt   : Date
    var location    : String

    init(type: DefectType, description: String = "",
         location: String = "", photoData: Data? = nil) {
        self.type        = type
        self.description = description
        self.isResolved  = false
        self.photoData   = photoData
        self.createdAt   = Date()
        self.location    = location
    }
}

struct BudgetCategory: Identifiable, Codable {
    var id      = UUID()
    var name    : String
    var planned : Double
    var actual  : Double
    var icon    : String
    var color   : String

    var difference:  Double { actual - planned }
    var isOverBudget: Bool  { actual > planned }
}

struct ScheduleEvent: Identifiable, Codable {
    var id          = UUID()
    var title       : String
    var date        : Date
    var endDate     : Date?
    var roomId      : UUID?
    var taskId      : UUID?
    var assignee    : String
    var isCompleted : Bool
    var color       : String

    init(title: String, date: Date, endDate: Date? = nil,
         roomId: UUID? = nil, taskId: UUID? = nil,
         assignee: String = "", color: String = "#F5C842") {
        self.title       = title
        self.date        = date
        self.endDate     = endDate
        self.roomId      = roomId
        self.taskId      = taskId
        self.assignee    = assignee
        self.isCompleted = false
        self.color       = color
    }
}
