import Foundation

func appReducer(state: AppState, action: AppAction) -> AppState {
    var newState = state
    
    switch action {
    case .initialize:
        newState.phase = .loading
        
    case .timeout:
        newState.phase = .failed
        newState.ui.navigateToMain = true
        
    case .trackingReceived(let data):
        let converted = convertToStringDict(data)
        newState.config.tracking = AppState.Config.TrackingData(data: converted)
        
    case .navigationReceived(let data):
        let converted = convertToStringDict(data)
        newState.config.navigation = AppState.Config.NavigationData(data: converted)
        
    case .networkOnline:
        newState.ui.showOfflineView = false
        
    case .networkOffline:
        newState.ui.showOfflineView = true
        
    case .validationStarted:
        newState.phase = .validating
        
    case .validationSucceeded:
        newState.phase = .validated
        
    case .validationFailed:
        newState.phase = .failed
        newState.ui.navigateToMain = true
        
    case .fetchAttributionStarted:
        newState.phase = .processing
        
    case .fetchAttributionSucceeded(let data):
        let converted = convertToStringDict(data)
        newState.config.tracking = AppState.Config.TrackingData(data: converted)
        
    case .fetchAttributionFailed:
        newState.phase = .failed
        newState.ui.navigateToMain = true
        
    case .fetchEndpointStarted:
        newState.phase = .processing
        
    case .fetchEndpointSucceeded(let endpoint):
        newState.config.mode = "Active"
        newState.config.firstLaunch = false
        newState.phase = .ready(endpoint)
        
        // ✅ КРИТИЧНО: Проверяем permissions и устанавливаем navigation
        if newState.config.permissions.canAsk {
            newState.ui.showPermissionPrompt = true
        } else {
            newState.ui.navigateToWeb = true
        }
        
    case .fetchEndpointFailed:
        newState.phase = .failed
        newState.ui.navigateToMain = true
        
    case .permissionRequested:
        // Actual request happens in Store side effect
        break
        
    case .permissionGranted:
        newState.config.permissions = AppState.Config.PermissionData(
            approved: true,
            declined: false,
            lastAsked: Date()
        )
        newState.ui.showPermissionPrompt = false
        newState.ui.navigateToWeb = true
        
    case .permissionDenied:
        newState.config.permissions = AppState.Config.PermissionData(
            approved: false,
            declined: true,
            lastAsked: Date()
        )
        newState.ui.showPermissionPrompt = false
        newState.ui.navigateToWeb = true
        
    case .permissionDeferred:
        newState.config.permissions = AppState.Config.PermissionData(
            approved: false,
            declined: false,
            lastAsked: Date()
        )
        newState.ui.showPermissionPrompt = false
        newState.ui.navigateToWeb = true  // ✅ ОБЯЗАТЕЛЬНО!
        
    case .navigateToMain:
        newState.ui.navigateToMain = true
        
    case .navigateToWeb:
        newState.ui.navigateToWeb = true
        
    case .configLoaded(let config):
        newState.config.mode = config.mode
        newState.config.firstLaunch = config.firstLaunch
        newState.config.tracking = AppState.Config.TrackingData(data: config.tracking)
        newState.config.navigation = AppState.Config.NavigationData(data: config.navigation)
        newState.config.permissions = AppState.Config.PermissionData(
            approved: config.permissions.approved,
            declined: config.permissions.declined,
            lastAsked: config.permissions.lastAsked
        )
        
        // ✅ КРИТИЧНО: НЕ проверяем endpoint здесь!
        // Endpoint НИКОГДА не загружается в config
        // Бизнес-логика запускается через side effects в Store
    }
    
    return newState
}

private func convertToStringDict(_ dict: [String: Any]) -> [String: String] {
    var result: [String: String] = [:]
    for (key, value) in dict {
        result[key] = "\(value)"
    }
    return result
}
