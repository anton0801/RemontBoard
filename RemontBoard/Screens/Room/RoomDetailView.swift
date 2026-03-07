import SwiftUI
import WebKit

struct RoomDetailView: View {
    let room: Room
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var showAddTask     = false
    @State private var showAddMaterial = false
    @State private var showAddDefect   = false
    @State private var showImagePicker = false
    @State private var showEditRoom    = false
    @State private var activeTab       = 0

    var currentRoom: Room {
        appVM.rooms.first { $0.id == room.id } ?? room
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                BlueprintGridView().opacity(0.18)

                VStack(spacing: 0) {
                    RoomHeaderCard(room: currentRoom)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    RoomTabBar(selectedTab: $activeTab)
                        .padding(.top, 14)

                    TabView(selection: $activeTab) {
                        RoomOverviewTab(room: currentRoom)
                            .environmentObject(appVM)
                            .tag(0)
                        TasksTab(room: currentRoom, showAdd: $showAddTask)
                            .environmentObject(appVM)
                            .tag(1)
                        MaterialsTab(room: currentRoom, showAdd: $showAddMaterial)
                            .environmentObject(appVM)
                            .tag(2)
                        DefectsTab(room: currentRoom, showAdd: $showAddDefect)
                            .environmentObject(appVM)
                            .tag(3)
                        PhotosTab(room: currentRoom, showPicker: $showImagePicker)
                            .environmentObject(appVM)
                            .tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.22), value: activeTab)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("\(currentRoom.emoji)  \(currentRoom.name)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(AppColors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showEditRoom = true } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAddTask)     { AddTaskView(roomId: room.id).environmentObject(appVM) }
        .sheet(isPresented: $showAddMaterial) { AddMaterialView(roomId: room.id).environmentObject(appVM) }
        .sheet(isPresented: $showAddDefect)   { AddDefectView(roomId: room.id).environmentObject(appVM) }
        .sheet(isPresented: $showEditRoom)    { EditRoomView(room: currentRoom).environmentObject(appVM) }
        .sheet(isPresented: $showImagePicker) { ImagePickerView(roomId: room.id).environmentObject(appVM) }
    }
}

// MARK: - Header Card
struct RoomHeaderCard: View {
    let room: Room
    var body: some View {
        HStack(spacing: 16) {
            Text(room.emoji).font(.system(size: 44))

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text("\(String(format: "%.1f", room.area)) m²")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                    RenovationTypeBadge(type: room.renovationType)
                }
                HStack(spacing: 8) {
                    ProgressBar(value: room.completionPercentage / 100)
                    Text("\(Int(room.completionPercentage))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.accent)
                        .frame(width: 36)
                }
                Label("$\(Int(room.totalMaterialCost + room.totalTaskCost))",
                      systemImage: "banknote")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.success)
            }
            Spacer()
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(AppColors.accentBlue.opacity(0.28), lineWidth: 1))
    }
}

// MARK: - Tab Bar
struct RoomTabBar: View {
    @Binding var selectedTab: Int
    let tabs  = ["Overview","Tasks","Materials","Defects","Photos"]
    let icons = ["square.grid.2x2","checkmark.square","shippingbox","exclamationmark.triangle","photo"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { i in
                    Button { withAnimation(.spring()) { selectedTab = i } } label: {
                        VStack(spacing: 4) {
                            Image(systemName: icons[i]).font(.system(size: 14))
                            Text(tabs[i]).font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(selectedTab == i ? AppColors.background : Color.white.opacity(0.45))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedTab == i ? AppColors.accent : Color.clear)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding(.horizontal, 14)
        }
    }
}

// MARK: - Overview Tab
struct RoomOverviewTab: View {
    let room: Room
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                InfoGrid(room: room)
                HStack(spacing: 12) {
                    MiniStat(label: "Tasks",   value: "\(room.tasks.count)",
                             icon: "checkmark.square.fill", color: AppColors.accentBlue)
                    MiniStat(label: "Done",    value: "\(room.tasks.filter{$0.status == .done}.count)",
                             icon: "checkmark.circle.fill",  color: AppColors.success)
                    MiniStat(label: "Defects", value: "\(room.defects.count)",
                             icon: "exclamationmark.triangle.fill", color: AppColors.warning)
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
    }
}

struct InfoGrid: View {
    let room: Room
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "Room Specifications").padding(.bottom, 10)
            VStack(spacing: 1) {
                InfoRow(label: "Floor",     value: room.floorType.rawValue,      icon: "square.fill")
                InfoRow(label: "Walls",     value: room.wallType.rawValue,       icon: "rectangle.portrait.fill")
                InfoRow(label: "Ceiling",   value: room.ceilingType.rawValue,    icon: "rectangle.fill")
                InfoRow(label: "Electrical",value: room.hasElectricalWork ? "Yes" : "No", icon: "bolt.fill")
                InfoRow(label: "Area",      value: "\(String(format: "%.1f", room.area)) m²", icon: "ruler.fill")
            }
            .cornerRadius(12)
            if !room.notes.isEmpty {
                Text(room.notes)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.secondaryText)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .padding(.top, 8)
            }
        }
    }
}

struct InfoRow: View {
    let label: String; let value: String; let icon: String
    var body: some View {
        HStack {
            Image(systemName: icon).font(.system(size: 12))
                .foregroundColor(AppColors.accentBlue).frame(width: 20)
            Text(label).font(.system(size: 13)).foregroundColor(AppColors.secondaryText)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(AppColors.cardBackground)
    }
}

struct MiniStat: View {
    let label: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(label).font(.system(size: 10)).foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(AppColors.cardBackground).cornerRadius(12)
    }
}

struct RemontWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "rb_endpoint_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "remont_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("🔨 [Remont] Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [Remont] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        webView.addSubview(popup)
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: webView.topAnchor),
            popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(closePopup(_:)))
        gesture.edges = .left; popup.addGestureRecognizer(gesture)
        popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    
    @objc private func closePopup(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        if let last = popups.last { last.removeFromSuperview(); popups.removeLast() } else { webView?.goBack() }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}
