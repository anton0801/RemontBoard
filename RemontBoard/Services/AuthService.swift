import SwiftUI
import Combine

// MARK: - User Model
struct AppUser: Codable, Equatable {
    var uid         : String
    var email       : String?
    var displayName : String?
    var photoURL    : String?
    var isGuest     : Bool
    var createdAt   : Date

    var initials: String {
        let name = displayName ?? email ?? "?"
        let parts = name.split(separator: " ").map { String($0) }
        if parts.count >= 2 {
            return String((parts[0].first ?? "?")).uppercased() +
                   String((parts[1].first ?? "?")).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var avatarColor: Color {
        // deterministic color from uid
        let colors: [Color] = [
            Color(hex: "#4A90D9"), Color(hex: "#F5C842"),
            Color(hex: "#5BC8A3"), Color(hex: "#E87D5A"),
            Color(hex: "#A78BFA"), Color(hex: "#FF6B9D")
        ]
        let idx = abs(uid.hashValue) % colors.count
        return colors[idx]
    }
}

// MARK: - Auth State
enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated(AppUser)
    case guest
}

// MARK: - AuthError
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailInUse
    case wrongPassword
    case userNotFound
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:   return "Please enter a valid email address."
        case .weakPassword:   return "Password must be at least 6 characters."
        case .emailInUse:     return "This email is already registered."
        case .wrongPassword:  return "Incorrect password. Please try again."
        case .userNotFound:   return "No account found with this email."
        case .networkError:   return "Network error. Check your connection."
        case .unknown(let m): return m
        }
    }
}

// MARK: - AuthService
// NOTE: This service is designed to plug directly into Firebase Auth.
// Replace the TODO blocks with real Firebase SDK calls after adding
// Firebase via Swift Package Manager (see README for setup instructions).
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var authState: AuthState = .loading
    @Published var currentUser: AppUser?

    private let userKey     = "rb_current_user"
    private let guestKey    = "rb_is_guest"

    init() {
        restoreSession()
    }

    // MARK: - Session restore
    private func restoreSession() {
        // TODO: Replace with Firebase Auth.auth().currentUser check
        // For now we use local persistence simulation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            if UserDefaults.standard.bool(forKey: self.guestKey) {
                let guest = AppUser(uid: "guest_local", email: nil,
                                    displayName: "Guest", photoURL: nil,
                                    isGuest: true, createdAt: Date())
                self.currentUser  = guest
                self.authState    = .guest
            } else if let data = UserDefaults.standard.data(forKey: self.userKey),
                      let user = try? JSONDecoder().decode(AppUser.self, from: data) {
                self.currentUser = user
                self.authState   = .authenticated(user)
            } else {
                self.authState = .unauthenticated
            }
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, name: String,
                completion: @escaping (Result<AppUser, AuthError>) -> Void) {
        // TODO: Auth.auth().createUser(withEmail: email, password: password)
        // Simulate async network call
        guard email.contains("@") else { completion(.failure(.invalidEmail)); return }
        guard password.count >= 6  else { completion(.failure(.weakPassword)); return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            // TODO: use result.user.uid from Firebase
            let uid  = UUID().uuidString
            let user = AppUser(uid: uid, email: email, displayName: name,
                               photoURL: nil, isGuest: false, createdAt: Date())
            self.persistUser(user)
            completion(.success(user))
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String,
                completion: @escaping (Result<AppUser, AuthError>) -> Void) {
        // TODO: Auth.auth().signIn(withEmail: email, password: password)
        guard email.contains("@") else { completion(.failure(.invalidEmail)); return }
        guard password.count >= 6  else { completion(.failure(.wrongPassword)); return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            if let data = UserDefaults.standard.data(forKey: self.userKey),
               let saved = try? JSONDecoder().decode(AppUser.self, from: data),
               saved.email == email {
                self.persistUser(saved)
                completion(.success(saved))
            } else {
                // Simulate first sign-in (new user)
                let uid  = UUID().uuidString
                let name = String(email.split(separator: "@").first ?? "User")
                let user = AppUser(uid: uid, email: email, displayName: name,
                                   photoURL: nil, isGuest: false, createdAt: Date())
                self.persistUser(user)
                completion(.success(user))
            }
        }
    }

    // MARK: - Guest Mode
    func continueAsGuest() {
        let guest = AppUser(uid: "guest_\(UUID().uuidString.prefix(8))",
                             email: nil, displayName: "Guest",
                             photoURL: nil, isGuest: true, createdAt: Date())
        UserDefaults.standard.set(true, forKey: guestKey)
        currentUser = guest
        authState   = .guest
    }

    // MARK: - Sign Out
    func signOut() {
        // TODO: try? Auth.auth().signOut()
        clearSession()
    }

    // MARK: - Delete Account
    func deleteAccount(completion: @escaping (Result<Void, AuthError>) -> Void) {
        // TODO: Auth.auth().currentUser?.delete { ... }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }
            // Wipe all app data
            PersistenceManager.shared.wipeAll()
            self.clearSession()
            completion(.success(()))
        }
    }

    // MARK: - Update Profile
    func updateProfile(name: String, completion: @escaping (Bool) -> Void) {
        guard var user = currentUser else { completion(false); return }
        // TODO: Auth.auth().currentUser?.displayName update via UserProfileChangeRequest
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            user.displayName = name
            self?.persistUser(user)
            completion(true)
        }
    }

    // MARK: - Reset Password
    func resetPassword(email: String, completion: @escaping (Bool) -> Void) {
        // TODO: Auth.auth().sendPasswordReset(withEmail: email)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { 
            completion(true)
        }
    }

    // MARK: - Helpers
    private func persistUser(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
        UserDefaults.standard.removeObject(forKey: guestKey)
        currentUser = user
        authState   = .authenticated(user)
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: guestKey)
        currentUser = nil
        authState   = .unauthenticated
    }

    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        if case .guest         = authState { return true }
        return false
    }
}

// MARK: - PersistenceManager wipeAll
extension PersistenceManager {
    func wipeAll() {
        let keys = ["remontboard_rooms_v2", "remontboard_budget_v2", "remontboard_schedule_v2"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}
