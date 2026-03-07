import Foundation

struct AppState: Equatable {
    var phase: Phase
    var config: Config
    var ui: UIFlags
    
    enum Phase: Equatable {
        case idle
        case loading
        case validating
        case validated
        case processing
        case ready(String)
        case failed
        case offline
    }
    
    struct Config: Equatable {
        var mode: String?
        var firstLaunch: Bool
        var tracking: TrackingData
        var navigation: NavigationData
        var permissions: PermissionData
        
        struct TrackingData: Equatable {
            let data: [String: String]
            
            var isEmpty: Bool { data.isEmpty }
            var isOrganic: Bool { data["af_status"] == "Organic" }
            
            static var empty: TrackingData {
                TrackingData(data: [:])
            }
        }
        
        struct NavigationData: Equatable {
            let data: [String: String]
            
            var isEmpty: Bool { data.isEmpty }
            
            static var empty: NavigationData {
                NavigationData(data: [:])
            }
        }
        
        struct PermissionData: Equatable {
            var approved: Bool
            var declined: Bool
            var lastAsked: Date?
            
            var canAsk: Bool {
                guard !approved && !declined else { return false }
                if let date = lastAsked {
                    return Date().timeIntervalSince(date) / 86400 >= 3
                }
                return true
            }
            
            static var initial: PermissionData {
                PermissionData(approved: false, declined: false, lastAsked: nil)
            }
        }
        
        static var initial: Config {
            Config(
                mode: nil,
                firstLaunch: true,
                tracking: .empty,
                navigation: .empty,
                permissions: .initial
            )
        }
    }
    
    struct UIFlags: Equatable {
        var showPermissionPrompt: Bool
        var showOfflineView: Bool
        var navigateToMain: Bool
        var navigateToWeb: Bool
        
        static var initial: UIFlags {
            UIFlags(
                showPermissionPrompt: false,
                showOfflineView: false,
                navigateToMain: false,
                navigateToWeb: false
            )
        }
    }
    
    static var initial: AppState {
        AppState(
            phase: .idle,
            config: .initial,
            ui: .initial
        )
    }
}
