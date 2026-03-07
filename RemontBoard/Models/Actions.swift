import Foundation

enum AppAction {
    // Lifecycle
    case initialize
    case timeout
    
    // Configuration
    case configLoaded(ConfigData)
    
    // Data received
    case trackingReceived([String: Any])
    case navigationReceived([String: Any])
    
    // Network
    case networkOnline
    case networkOffline
    
    // Validation
    case validationStarted
    case validationSucceeded
    case validationFailed
    
    // Attribution fetch (organic flow)
    case fetchAttributionStarted
    case fetchAttributionSucceeded([String: Any])
    case fetchAttributionFailed
    
    // Endpoint fetch
    case fetchEndpointStarted
    case fetchEndpointSucceeded(String)
    case fetchEndpointFailed
    
    // Permissions
    case permissionRequested
    case permissionGranted
    case permissionDenied
    case permissionDeferred
    
    // Navigation
    case navigateToMain
    case navigateToWeb
    
    struct ConfigData {
        var mode: String?
        var firstLaunch: Bool
        var tracking: [String: String]
        var navigation: [String: String]
        var permissions: PermissionData
        
        struct PermissionData {
            var approved: Bool
            var declined: Bool
            var lastAsked: Date?
        }
    }
}
