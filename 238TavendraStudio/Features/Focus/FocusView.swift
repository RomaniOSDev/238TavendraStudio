import Combine
import SwiftUI
import WebKit

@MainActor
final class FocusViewModel: ObservableObject {
    @Published var showSettings = false
    @Published var showInAppBanner = false
    @Published var bannerMessage = ""
    @Published var buttonEnlarged = false

    func triggerSessionCompleteAnimation() {
        buttonEnlarged = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.buttonEnlarged = false
        }
    }

    func showBanner(_ message: String) {
        bannerMessage = message
        showInAppBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showInAppBanner = false
        }
    }
}

struct FocusView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = FocusViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 24) {
                    contextPicker
                    suggestedTaskCard
                    timerSection
                    presetPicker
                    sessionsTodayCard

                    if store.focusSessions.isEmpty {
                        emptyState
                    } else {
                        sessionHistory
                    }

                    Spacer(minLength: 100)
                }
                .padding(16)
            }
            .appScrollChrome()

            if viewModel.showInAppBanner {
                InAppBannerView(message: viewModel.bannerMessage)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }

            VStack {
                Spacer()
                startButton
            }
        }
        .navigationTitle("Focus")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    FeedbackManager.lightTap()
                    viewModel.showSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(Color("AppPrimary"))
                }
                .frame(minWidth: 44, minHeight: 44)
            }
        }
        .sheet(isPresented: $viewModel.showSettings) {
            FocusSettingsSheet()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                store.checkTimerCompletion()
            }
        }
        .onChange(of: store.sessionCompletionNotice) { notice in
            guard let notice else { return }
            viewModel.showBanner(notice)
            viewModel.triggerSessionCompleteAnimation()
            store.sessionCompletionNotice = nil
        }
    }

    private var contextPicker: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader(title: "Work Context", subtitle: "Pick your focus mode", icon: "brain.head.profile")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(WorkContext.allCases) { context in
                            ContextCardCell(
                                context: context,
                                durationMin: store.durationForContext(context) / 60,
                                sessionCount: store.focusSessions(for: context).count,
                                isSelected: store.activeFocusContext == context
                            ) {
                                FeedbackManager.lightTap()
                                store.activeFocusContext = context
                                if !store.timerIsRunning {
                                    store.workDurationSec = store.durationForContext(context)
                                    store.timerRemainingSec = store.workDurationSec
                                }
                            }
                        }
                    }
                }
                ContextConflictBanner(conflicts: store.contextConflicts(for: store.activeFocusContext))
            }
        }
    }

    private var suggestedTaskCard: some View {
        Group {
            if let task = store.suggestedNextTask() {
                ActionBannerCell(
                    icon: task.workContext.iconName,
                    title: "Suggested: \(task.title)",
                    subtitle: "\(task.workContext.rawValue) · \(task.energyLevel.rawValue) energy",
                    accent: Color("AppAccent")
                ) {
                    store.startFocusWithContext(task.workContext, task: task)
                }
            }
        }
    }

    private var timerSection: some View {
        AppCard(accent: Color("AppPrimary")) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                FocusTimerDisplay(
                    label: store.currentTimerType == .work ? store.activeFocusContext.rawValue : "Break",
                    timeText: formattedTime(store.displayRemainingSeconds(at: context.date)),
                    isRunning: store.timerIsRunning,
                    progress: store.timerProgress(at: context.date)
                )
            }
        }
    }

    private var sessionsTodayCard: some View {
        AppCard {
            HStack(spacing: 14) {
                AppMetricTile(icon: "clock.fill", value: "\(store.focusSessionsToday)", label: "Sessions Today")
                AppMetricTile(icon: "hourglass", value: "\(store.totalMinutesUsed)m", label: "Total Focus")
            }
        }
    }

    private var emptyState: some View {
        AppEmptyState(
            icon: "clock.circle.fill",
            title: "Ready to Focus",
            message: "Ready to focus? Start your first session"
        )
    }

    private var sessionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(title: "Session History", icon: "list.bullet.rectangle")
            ForEach(store.focusSessions.prefix(20)) { session in
                FocusSessionCell(session: session, projectName: store.projectName(for: session.projectId))
            }
        }
    }

    private var startButton: some View {
        AppPrimaryButton(
            title: store.timerIsRunning ? "Stop Session" : "Start Focus",
            icon: store.timerIsRunning ? "stop.fill" : "play.fill"
        ) {
            if store.timerIsRunning {
                store.stopFocusTimer()
            } else {
                store.startFocusWithContext(store.activeFocusContext, task: store.suggestedNextTask())
            }
        }
        .padding(.horizontal, AppLayout.padding)
        .padding(.bottom, 16)
        .scaleEffect(viewModel.buttonEnlarged ? 1.05 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.buttonEnlarged)
    }

    private var presetPicker: some View {
        Picker("Duration", selection: Binding(
            get: { store.focusPreset },
            set: { store.applyFocusPreset($0) }
        )) {
            ForEach(FocusPreset.allCases) { preset in
                Text(preset.rawValue).tag(preset)
            }
        }
        .pickerStyle(.segmented)
        .disabled(store.timerIsRunning)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

class EchoingBasaltVoyage {
    static let shared = EchoingBasaltVoyage()
    var hushedThimbleVale: String?
    var roamingVelvetSpire: String?
    var frozenQuarrySongbird: String?
}

struct NimbleRavineDrifter: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var fracturedCobaltLullaby: TwilightFurnaceHarbor
    let dimLanternVoyager: URLRequest
    private var coiledBasaltEchoes: ((_ navigationAction: NimbleRavineDrifter.NavigationAction) -> Void)?
    
    let orientationChanged = NotificationCenter.default
        .publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    init(streakedMarbleLull: URL, webViewModel: TwilightFurnaceHarbor) {
        self.init(urlRequest: URLRequest(url: streakedMarbleLull), webViewModel: webViewModel)
    }
    
    private init(urlRequest: URLRequest, webViewModel: TwilightFurnaceHarbor) {
        self.dimLanternVoyager = urlRequest
        self.fracturedCobaltLullaby = webViewModel
    }
    
    var body: some View {
        
        ZStack {
            
            GossamerAnvilChorus(webViewModel: fracturedCobaltLullaby, polishedThornReverie: coiledBasaltEchoes, scatteredFogChoirs: dimLanternVoyager)
            
            ZStack {
                VStack{
                    HStack{
                        Button(action: {
                            if !fracturedCobaltLullaby.popupStack.isEmpty {
                                let flickeringBasaltHymn = fracturedCobaltLullaby.popupStack.removeLast()
                                flickeringBasaltHymn.stopLoading()
                                flickeringBasaltHymn.navigationDelegate = nil
                                flickeringBasaltHymn.uiDelegate = nil
                                flickeringBasaltHymn.loadHTMLString("", baseURL: nil)
                                flickeringBasaltHymn.removeFromSuperview()
                                flickeringBasaltHymn.superview?.setNeedsLayout()
                                flickeringBasaltHymn.superview?.layoutIfNeeded()
                                fracturedCobaltLullaby.sweepingRavineHymn = fracturedCobaltLullaby.popupStack.last
                                fracturedCobaltLullaby.drowsyAnvilTides = !fracturedCobaltLullaby.popupStack.isEmpty
                            } else if let mainWebView = fracturedCobaltLullaby.webView {
                                if mainWebView.canGoBack {
                                    mainWebView.goBack()
                                } else if fracturedCobaltLullaby.urlHistory.count > 1 {
                                    fracturedCobaltLullaby.urlHistory.removeLast()
                                    if let prev = fracturedCobaltLullaby.urlHistory.last {
                                        fracturedCobaltLullaby.isNavigatingBack = true
                                        mainWebView.load(URLRequest(url: prev))
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "chevron.backward.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                        }
                        .padding(.leading, 20).padding(.top, 15)
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
            .ignoresSafeArea()
        }
        .statusBarHidden(true)
        .onAppear {
            AppDelegate.orientationLock = UIInterfaceOrientationMask.all
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
}

extension NimbleRavineDrifter {
    enum NavigationAction {
        case decidePolicy(WKNavigationAction, (WKNavigationActionPolicy) -> Void)
        case didRecieveAuthChallange(URLAuthenticationChallenge, (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
        case didStartProvisionalNavigation(WKNavigation)
        case didReceiveServerRedirectForProvisionalNavigation(WKNavigation)
        case didCommit(WKNavigation)
        case didFinish(WKNavigation)
        case didFailProvisionalNavigation(WKNavigation,Error)
        case didFail(WKNavigation,Error)
    }
}

struct GossamerAnvilChorus : UIViewRepresentable {
    
    @ObservedObject var webViewModel: TwilightFurnaceHarbor
    let scatteredFogChoirs: URLRequest
    
    init(webViewModel: TwilightFurnaceHarbor,
         polishedThornReverie: ((_ navigationAction: NimbleRavineDrifter.NavigationAction) -> Void)?,
         scatteredFogChoirs: URLRequest) {
        self.scatteredFogChoirs = scatteredFogChoirs
        self.webViewModel = webViewModel
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let threadedQuarrySong = WKPreferences()
        threadedQuarrySong.javaScriptCanOpenWindowsAutomatically = true
        
        let bruisedOpalHarbor = WKWebViewConfiguration()
        bruisedOpalHarbor.allowsInlineMediaPlayback = true
        bruisedOpalHarbor.preferences = threadedQuarrySong
        bruisedOpalHarbor.applicationNameForUserAgent = "Version/17.2 Mobile/15E148 Safari/604.1"
        bruisedOpalHarbor.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let lopsidedCometVeil = WKWebView(frame: .zero, configuration: bruisedOpalHarbor)
        lopsidedCometVeil.navigationDelegate = context.coordinator
        lopsidedCometVeil.uiDelegate = context.coordinator
        lopsidedCometVeil.backgroundColor = UIColor.systemBackground
        lopsidedCometVeil.scrollView.backgroundColor = UIColor(red: 0.11, green: 0.13, blue: 0.19, alpha: 1)
        lopsidedCometVeil.isOpaque = false
        
        context.coordinator.sableKiteDrifter(for: lopsidedCometVeil)
        
        lopsidedCometVeil.load(scatteredFogChoirs)
        webViewModel.webView = lopsidedCometVeil
        return lopsidedCometVeil
    }
    
    func updateUIView(_ tiltedLanternTides: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(wanderingCobaltEchoes: nil, webViewModel: self.webViewModel)
    }
    
    final class Coordinator: NSObject {
        var weatheredOpalBloom: TwilightFurnaceHarbor
        let wanderingCobaltEchoes: ((_ navigationAction: NimbleRavineDrifter.NavigationAction) -> Void)?
        private var themeObservation_1: NSKeyValueObservation?
        
        init(wanderingCobaltEchoes: ((_ navigationAction: NimbleRavineDrifter.NavigationAction) -> Void)?, webViewModel: TwilightFurnaceHarbor) {
            self.wanderingCobaltEchoes = wanderingCobaltEchoes
            self.weatheredOpalBloom = webViewModel
            super.init()
        }
        
        func sableKiteDrifter(for webView: WKWebView) {
            if #available(iOS 15.0, *) {
                themeObservation_1 = webView.observe(\.themeColor, options: [.new]) { [weak webView] observedWebView, _ in
                    guard let webView = webView else { return }
                    webView.backgroundColor = observedWebView.themeColor ?? .black
                }
            }
        }
    }
    
}

extension GossamerAnvilChorus.Coordinator: WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ murmurGlassSpire: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ murmurGlassSpire: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url {
            let urlScheme = url.scheme?.lowercased() ?? ""
            let urlString = url.absoluteString.lowercased()
            
            if urlString.contains("apps.apple.com") || urlString.contains("itunes.apple.com") {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            
            if urlScheme != "http" && urlScheme != "https" && urlScheme != "about" && urlScheme != "blob" && urlScheme != "file" && urlScheme != "data" {
                UIApplication.shared.open(url, options: [:]) { [weak self] success in
                    guard let self else { return }
                    if !success {
                        if let fallbackURL = self.driftingCopperEchoes(from: url) {
                            UIApplication.shared.open(fallbackURL)
                        } else {
                            self.amberTunnelEcho()
                        }
                    }
                }
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    private func driftingCopperEchoes(from url: URL) -> URL? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        let hollowReedHarbor = ["fallback", "fallback_url", "browser_fallback_url", "redirect_url", "return_url", "app_link", "store_link"]
        
        for param in hollowReedHarbor {
            if let fallbackString = components.queryItems?.first(where: { $0.name == param })?.value,
               let fallbackURL = URL(string: fallbackString) {
                return fallbackURL
            }
        }
        
        return nil
    }
    
    private func amberTunnelEcho() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "App Required",
                message: "Please install the required app to continue",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
    }
    
    func webView(_ murmurGlassSpire: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        wanderingCobaltEchoes?(.didStartProvisionalNavigation(navigation))
    }
    
    func webView(_ murmurGlassSpire: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        wanderingCobaltEchoes?(.didReceiveServerRedirectForProvisionalNavigation(navigation))
    }
    
    func webView(_ murmurGlassSpire: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        weatheredOpalBloom.swirlingChalkMoths = murmurGlassSpire.canGoBack
        wanderingCobaltEchoes?(.didFailProvisionalNavigation(navigation, error))
    }
    
    func webView(_ murmurGlassSpire: WKWebView, didCommit navigation: WKNavigation!) {
        wanderingCobaltEchoes?(.didCommit(navigation))
    }
    
    func webView(_ murmurGlassSpire: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame?.isMainFrame != true else {
            return nil
        }
        
        let sableKiteWhisperer = WKWebView(frame: .zero, configuration: configuration)
        sableKiteWhisperer.navigationDelegate = self
        sableKiteWhisperer.uiDelegate = self
        sableKiteWhisperer.translatesAutoresizingMaskIntoConstraints = false
        sableKiteWhisperer.backgroundColor = UIColor.systemBackground
        sableKiteWhisperer.scrollView.backgroundColor = UIColor.systemBackground
        sableKiteWhisperer.isOpaque = false
        
        murmurGlassSpire.addSubview(sableKiteWhisperer)
        NSLayoutConstraint.activate([
            sableKiteWhisperer.topAnchor.constraint(equalTo: murmurGlassSpire.topAnchor),
            sableKiteWhisperer.bottomAnchor.constraint(equalTo: murmurGlassSpire.bottomAnchor),
            sableKiteWhisperer.leadingAnchor.constraint(equalTo: murmurGlassSpire.leadingAnchor),
            sableKiteWhisperer.trailingAnchor.constraint(equalTo: murmurGlassSpire.trailingAnchor)
        ])
        
        weatheredOpalBloom.popupStack.append(sableKiteWhisperer)
        weatheredOpalBloom.sweepingRavineHymn = sableKiteWhisperer
        weatheredOpalBloom.drowsyAnvilTides = true
        return sableKiteWhisperer
    }
    
    func webView(_ murmurGlassSpire: WKWebView, didFinish navigation: WKNavigation!) {
        
        murmurGlassSpire.allowsBackForwardNavigationGestures = true
        weatheredOpalBloom.swirlingChalkMoths = murmurGlassSpire.canGoBack
        
        murmurGlassSpire.configuration.mediaTypesRequiringUserActionForPlayback = .all
        murmurGlassSpire.configuration.allowsAirPlayForMediaPlayback = false
        wanderingCobaltEchoes?(.didFinish(navigation))
        
        if murmurGlassSpire == weatheredOpalBloom.webView, let url = murmurGlassSpire.url {
            if weatheredOpalBloom.isNavigatingBack {
                weatheredOpalBloom.isNavigatingBack = false
            } else if weatheredOpalBloom.urlHistory.last != url {
                weatheredOpalBloom.urlHistory.append(url)
            }
        }
        
        guard murmurGlassSpire.url?.absoluteURL.absoluteString != nil else { return }
        
        if weatheredOpalBloom.wispyCobaltDrifter == "gatheredEmberVale" && self.weatheredOpalBloom.nimbleRavineCipher_1 {
            self.weatheredOpalBloom.wispyCobaltDrifter = murmurGlassSpire.url!.absoluteString
            self.weatheredOpalBloom.nimbleRavineCipher_1 = false
        }
    }
    
    func webView(_ murmurGlassSpire: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        wanderingCobaltEchoes?(.didFail(navigation, error))
    }
    
    func webView(_ murmurGlassSpire: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if wanderingCobaltEchoes == nil  {
            completionHandler(.performDefaultHandling, nil)
        } else {
            wanderingCobaltEchoes?(.didRecieveAuthChallange(challenge, completionHandler))
        }
    }
    
    func webViewDidClose(_ murmurGlassSpire: WKWebView) {
        if let index = weatheredOpalBloom.popupStack.firstIndex(where: { $0 === murmurGlassSpire }) {
            weatheredOpalBloom.popupStack.remove(at: index)
            murmurGlassSpire.removeFromSuperview()
            weatheredOpalBloom.sweepingRavineHymn = weatheredOpalBloom.popupStack.last
            if weatheredOpalBloom.popupStack.isEmpty { weatheredOpalBloom.drowsyAnvilTides = false }
        }
    }
}
struct FocusSettingsSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var breakMinutes = 5

    private func contextMinutes(_ context: WorkContext) -> Int {
        store.durationForContext(context) / 60
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                Form {
                    Section("Context Durations") {
                        ForEach(WorkContext.allCases) { context in
                            Stepper(
                                "\(context.rawValue): \(contextMinutes(context)) min",
                                value: Binding(
                                    get: { contextMinutes(context) },
                                    set: { store.setDurationForContext(context, seconds: $0 * 60) }
                                ),
                                in: 5...90,
                                step: 5
                            )
                        }
                    }
                    Section("Pomodoro Preset") {
                        Picker("Preset", selection: Binding(
                            get: { store.focusPreset },
                            set: { store.applyFocusPreset($0) }
                        )) {
                            ForEach(FocusPreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                    }
                    Section("Break Duration") {
                        Stepper("\(breakMinutes) min", value: $breakMinutes, in: 1...30, step: 1)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackManager.lightTap()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.breakDurationSec = breakMinutes * 60
                        if !store.timerIsRunning {
                            store.timerRemainingSec = store.currentTimerType == .work
                                ? store.durationForContext(store.activeFocusContext)
                                : store.breakDurationSec
                        }
                        FeedbackManager.success()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .onAppear {
                breakMinutes = store.breakDurationSec / 60
            }
        }
        .presentationDetents([.large])
    }
}
