import SwiftUI

@main
struct ScreenshotToNotesApp: App {
    @StateObject private var captureManager = CaptureManager.shared
    @StateObject private var photoMonitor = PhotoKitMonitor.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .environmentObject(captureManager)
            .environmentObject(photoMonitor)
            .onAppear {
                setupApp()
            }
        }
    }
    
    private func setupApp() {
        loadSettings()
        
        if hasCompletedOnboarding {
            photoMonitor.startMonitoring()
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "appSettings"),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            captureManager.settings = settings
        }
    }
}
