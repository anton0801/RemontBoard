// MARK: ─────────────────────────────────────────────────────────────────
// FIREBASE SETUP GUIDE FOR REMONT BOARD
// ─────────────────────────────────────────────────────────────────────
//
// The AuthService is pre-wired. To connect real Firebase Auth:
//
// STEP 1 — Add Firebase via Swift Package Manager
//   Xcode → File → Add Packages...
//   URL: https://github.com/firebase/firebase-ios-sdk
//   Products to add: FirebaseAuth, FirebaseFirestore (optional)
//
// STEP 2 — Add GoogleService-Info.plist
//   • Go to console.firebase.google.com
//   • Create project → Add iOS app → bundle ID: com.remontboard.app
//   • Download GoogleService-Info.plist
//   • Drag it into Xcode project root (check "Copy items if needed")
//
// STEP 3 — Initialize in RemontBoardApp.swift
//   Add at top:  import FirebaseCore
//   Add in init: FirebaseApp.configure()
//
// STEP 4 — Replace TODO blocks in AuthService.swift
//
//   signUp:   Auth.auth().createUser(withEmail:password:) { result, error in ... }
//   signIn:   Auth.auth().signIn(withEmail:password:) { result, error in ... }
//   signOut:  try? Auth.auth().signOut()
//   delete:   Auth.auth().currentUser?.delete { error in ... }
//   restore:  if let user = Auth.auth().currentUser { ... }
//   reset:    Auth.auth().sendPasswordReset(withEmail:) { error in ... }
//
// STEP 5 — Map Firebase User to AppUser
//   let u = Auth.auth().currentUser!
//   let appUser = AppUser(uid: u.uid, email: u.email,
//                         displayName: u.displayName,
//                         isGuest: false, createdAt: Date())
//
// STEP 6 — Enable Email/Password in Firebase Console
//   Authentication → Sign-in methods → Email/Password → Enable
//
// ─────────────────────────────────────────────────────────────────────
// That's it! Everything else (UI, state management, error handling)
// is already implemented in AuthService.swift and AuthViews.swift.
// ─────────────────────────────────────────────────────────────────────

import Foundation

// This file is documentation only — no code needed here.
