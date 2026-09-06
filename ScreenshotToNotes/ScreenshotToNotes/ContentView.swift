import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var captureManager: CaptureManager
    @State private var selectedTab = 0
    @State private var showingImagePicker = false
    @State private var showingFilterSheet = false
    @State private var currentContent: ExtractedContent?
    @AppStorage("hasEnabledAutomation") private var hasEnabledAutomation = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RecentView(showingFilterSheet: $showingFilterSheet, currentContent: $currentContent)
                .tabItem {
                    Label(L10n.recentTitle, systemImage: "clock.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label(L10n.historyTitle, systemImage: "list.bullet")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label(L10n.settingsTitle, systemImage: "gear")
                }
                .tag(2)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                Task {
                    await processImage(image)
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            if let content = currentContent {
                FilterSheetView(content: content) { selectedCategory in
                    if let category = selectedCategory {
                        await saveToNotes(content: content, category: category)
                    }
                    showingFilterSheet = false
                    currentContent = nil
                }
            }
        }
        .onOpenURL { url in
            handleOpenURL(url)
        }
    }
    
    private func handleOpenURL(_ url: URL) {
        guard url.scheme == "screenshottone" else { return }
        
        if url.host == "process-latest" {
            Task {
                await processLatestScreenshot()
            }
        }
    }
    
    private func processLatestScreenshot() async {
        guard let image = await captureManager.getLatestScreenshot() else {
            return
        }
        await processImage(image)
    }
    
    private func processImage(_ image: UIImage) async {
        do {
            let content = try await captureManager.processScreenshot(image)
            
            await MainActor.run {
                currentContent = content
                
                if captureManager.settings.showPreviewBeforeSaving {
                    showingFilterSheet = true
                } else if captureManager.settings.autoSaveEnabled {
                    Task {
                        await saveToNotes(content: content, category: content.category)
                    }
                } else {
                    showingFilterSheet = true
                }
            }
        } catch {
            print("处理失败: \(error.localizedDescription)")
        }
    }
    
    private func saveToNotes(content: ExtractedContent, category: NoteCategory) async {
        var updatedContent = content
        updatedContent.category = category
        
        do {
            try await NotesWriter.shared.writeNote(content: updatedContent)
            await captureManager.recordSuccess(content: updatedContent)
        } catch {
            await captureManager.recordFailure(error: error)
        }
    }
}

struct RecentView: View {
    @EnvironmentObject var captureManager: CaptureManager
    @Binding var showingFilterSheet: Bool
    @Binding var currentContent: ExtractedContent?
    @State private var showingImagePicker = false
    @AppStorage("hasEnabledAutomation") private var hasEnabledAutomation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !hasEnabledAutomation {
                    AutomationBanner()
                }
                
                if captureManager.recentRecords.isEmpty {
                    emptyStateView
                } else {
                    recordsList
                }
            }
            .navigationTitle(L10n.recentTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingImagePicker = true
                    } label: {
                        Image(systemName: "photo.on.rectangle.angled")
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { image in
                    Task {
                        await processManualImage(image)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(L10n.noRecentItems)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(L10n.pickFromPhotos) {
                showingImagePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var recordsList: some View {
        List(captureManager.recentRecords) { record in
            RecordRowView(record: record)
        }
    }
    
    private func processManualImage(_ image: UIImage) async {
        do {
            let content = try await captureManager.processScreenshot(image)
            await MainActor.run {
                currentContent = content
                showingFilterSheet = true
            }
        } catch {
            print("处理失败: \(error.localizedDescription)")
        }
    }
}

struct RecordRowView: View {
    let record: ProcessingRecord
    
    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            
            VStack(alignment: .leading, spacing: 4) {
                if let content = record.content {
                    Text(content.title.isEmpty ? "无标题" : content.title)
                        .font(.headline)
                    
                    Text(content.category.rawValue)
                        .font(.caption)
                        .foregroundColor(content.category.color)
                } else {
                    Text(record.status.rawValue)
                        .font(.headline)
                }
                
                Text(record.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if record.status == .success, let content = record.content {
                Image(systemName: content.category.icon)
                    .foregroundColor(content.category.color)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: some View {
        Group {
            switch record.status {
            case .pending:
                ProgressView()
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .cancelled:
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.gray)
            }
        }
    }
}

struct AutomationBanner: View {
    @AppStorage("hasEnabledAutomation") private var hasEnabledAutomation = false
    @AppStorage("hasDismissedBanner") private var hasDismissedBanner = false
    
    var body: some View {
        if !hasDismissedBanner {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.shortcutNotEnabledBanner)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Button(L10n.setupAutomation) {
                        if let url = URL(string: "shortcuts://") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                }
                
                Spacer()
                
                Button {
                    hasDismissedBanner = true
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, error in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.onImagePicked(image)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CaptureManager.shared)
        .environmentObject(PhotoKitMonitor.shared)
}
