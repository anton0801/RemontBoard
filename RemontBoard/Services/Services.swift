import Foundation
import FirebaseDatabase
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

// MARK: - Services

// UNIQUE: Persistence
protocol PersistenceLayer {
    func saveTracking(_ data: [String: String])
    func loadAll() -> LoadedConfig
    func saveNavigation(_ data: [String: String])
    func saveEndpoint(_ url: String)
    func saveMode(_ mode: String)
    func markFirstLaunchDone()
    func savePermissions(_ permissions: AppState.Config.PermissionData)
    
    
}

struct LoadedConfig {
    var mode: String?
    var isFirstLaunch: Bool
    var tracking: [String: String]
    var navigation: [String: String]
    var permissions: PermissionData
    
    struct PermissionData {
        var approved: Bool
        var declined: Bool
        var lastAsked: Date?
    }
}

final class DiskPersistence: PersistenceLayer {
    
    private let store = UserDefaults(suiteName: "group.remont.storage")!
    private let cache = UserDefaults.standard
    private var memory: [String: Any] = [:]
    
    // UNIQUE: rb_ prefix
    private enum Key {
        static let tracking = "rb_tracking_payload"
        static let navigation = "rb_navigation_payload"
        static let endpoint = "rb_endpoint_target"
        static let mode = "rb_mode_active"
        static let firstLaunch = "rb_first_launch_flag"
        static let permApproved = "rb_perm_approved"
        static let permDeclined = "rb_perm_declined"
        static let permDate = "rb_perm_date"
    }
    
    init() {
        preload()
    }
    
    func saveTracking(_ data: [String: String]) {
        if let json = toJSON(data) {
            store.set(json, forKey: Key.tracking)
            memory[Key.tracking] = json
        }
    }
    
    func saveNavigation(_ data: [String: String]) {
        if let json = toJSON(data) {
            let encoded = encode(json)
            store.set(encoded, forKey: Key.navigation)
        }
    }
    
    func saveEndpoint(_ url: String) {
        store.set(url, forKey: Key.endpoint)
        cache.set(url, forKey: Key.endpoint)
        memory[Key.endpoint] = url
    }
    
    func saveMode(_ mode: String) {
        store.set(mode, forKey: Key.mode)
    }
    
    func markFirstLaunchDone() {
        store.set(true, forKey: Key.firstLaunch)
    }
    
    func savePermissions(_ permissions: AppState.Config.PermissionData) {
        store.set(permissions.approved, forKey: Key.permApproved)
        store.set(permissions.declined, forKey: Key.permDeclined)
        if let date = permissions.lastAsked {
            store.set(date.timeIntervalSince1970 * 1000, forKey: Key.permDate)
        }
    }
    
    func loadAll() -> LoadedConfig {
        // ✅ КРИТИЧНО: НЕ загружаем endpoint!
        
        let mode = store.string(forKey: Key.mode)
        let isFirstLaunch = !store.bool(forKey: Key.firstLaunch)
        
        var tracking: [String: String] = [:]
        if let json = memory[Key.tracking] as? String ?? store.string(forKey: Key.tracking),
           let dict = fromJSON(json) {
            tracking = dict
        }
        
        var navigation: [String: String] = [:]
        if let encoded = store.string(forKey: Key.navigation),
           let json = decode(encoded),
           let dict = fromJSON(json) {
            navigation = dict
        }
        
        let approved = store.bool(forKey: Key.permApproved)
        let declined = store.bool(forKey: Key.permDeclined)
        let ts = store.double(forKey: Key.permDate)
        let date = ts > 0 ? Date(timeIntervalSince1970: ts / 1000) : nil
        
        let permissions = LoadedConfig.PermissionData(
            approved: approved,
            declined: declined,
            lastAsked: date
        )
        
        return LoadedConfig(
            mode: mode,
            isFirstLaunch: isFirstLaunch,
            tracking: tracking,
            navigation: navigation,
            permissions: permissions
        )
    }
    
    private func preload() {
        if let endpoint = store.string(forKey: Key.endpoint) {
            memory[Key.endpoint] = endpoint
        }
    }
    
    private func toJSON(_ dict: [String: String]) -> String? {
        let anyDict = dict.mapValues { $0 as Any }
        guard let data = try? JSONSerialization.data(withJSONObject: anyDict),
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }
    
    private func fromJSON(_ string: String) -> [String: String]? {
        guard let data = string.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        
        var result: [String: String] = [:]
        for (key, value) in dict {
            result[key] = "\(value)"
        }
        return result
    }
    
    // UNIQUE encoding: $ and !
    private func encode(_ string: String) -> String {
        Data(string.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "$")
            .replacingOccurrences(of: "+", with: "!")
    }
    
    private func decode(_ string: String) -> String? {
        let base64 = string
            .replacingOccurrences(of: "$", with: "=")
            .replacingOccurrences(of: "!", with: "+")
        
        guard let data = Data(base64Encoded: base64),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}

// UNIQUE: Validator
protocol Validator {
    func validate() async throws -> Bool
}

final class FirebaseValidator: Validator {
    func validate() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            Database.database().reference().child("users/log/data")
                .observeSingleEvent(of: .value) { snapshot in
                    if let url = snapshot.value as? String,
                       !url.isEmpty,
                       URL(string: url) != nil {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
}

// UNIQUE: Backend
protocol Backend {
    func fetchAttribution(deviceID: String) async throws -> [String: Any]
    func fetchEndpoint(tracking: [String: Any]) async throws -> String
}

final class HTTPBackend: Backend {
    
    private let client: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.client = URLSession(configuration: config)
    }
    
    func fetchAttribution(deviceID: String) async throws -> [String: Any] {
        let base = "https://gcdsdk.appsflyer.com/install_data/v4.0"
        let app = "id\(RemontConfig.appID)"
        
        var builder = URLComponents(string: "\(base)/\(app)")
        builder?.queryItems = [
            URLQueryItem(name: "devkey", value: RemontConfig.devKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = builder?.url else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await client.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BackendError.requestFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BackendError.decodingFailed
        }
        
        return json
    }
    
    private var userAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func fetchEndpoint(tracking: [String: Any]) async throws -> String {
        guard let url = URL(string: "https://remonttboard.com/config.php") else {
            throw BackendError.invalidURL
        }
        
        var payload: [String: Any] = tracking
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(RemontConfig.appID)"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        var lastError: Error?
        let retries: [Double] = [15.0, 30.0, 60.0]  // UNIQUE retry delays
        
        for (index, delay) in retries.enumerated() {
            do {
                let (data, response) = try await client.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw BackendError.requestFailed
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let success = json["ok"] as? Bool,
                          success,
                          let endpoint = json["url"] as? String else {
                        throw BackendError.decodingFailed
                    }
                    return endpoint
                } else if httpResponse.statusCode == 429 {
                    let backoff = delay * Double(index + 1)
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    continue
                } else {
                    throw BackendError.requestFailed
                }
            } catch {
                lastError = error
                if index < retries.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? BackendError.requestFailed
    }
}

enum BackendError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
}
