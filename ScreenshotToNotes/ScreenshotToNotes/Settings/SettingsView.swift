import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var captureManager: CaptureManager
    @EnvironmentObject var photoMonitor: PhotoKitMonitor
    @State private var showingCategoryMappings = false
    
    var body: some View {
        NavigationView {
            Form {
                generalSection
                autoSaveSection
                categorySection
                aboutSection
            }
            .navigationTitle(L10n.settingsTitle)
            .sheet(isPresented: $showingCategoryMappings) {
                CategoryMappingsView()
            }
        }
    }
    
    private var generalSection: some View {
        Section(header: Text(L10n.generalSection)) {
            Toggle(isOn: $captureManager.settings.photoMonitoringEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.photoMonitoringLabel)
                    Text("相册监控作为后备触发方式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: captureManager.settings.photoMonitoringEnabled) { oldValue, newValue in
                if newValue {
                    photoMonitor.startMonitoring()
                } else {
                    photoMonitor.stopMonitoring()
                }
                captureManager.saveSettings()
            }
            
            HStack {
                Text("监控状态")
                Spacer()
                Text(photoMonitor.isMonitoring ? "运行中" : "已停止")
                    .foregroundColor(photoMonitor.isMonitoring ? .green : .gray)
            }
        }
    }
    
    private var autoSaveSection: some View {
        Section(header: Text(L10n.autoSaveSection)) {
            Toggle(isOn: $captureManager.settings.autoSaveEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.autoSaveEnabledLabel)
                    Text("筛选框超时后自动按推荐分类保存")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: captureManager.settings.autoSaveEnabled) { _, _ in
                captureManager.saveSettings()
            }
            
            if captureManager.settings.autoSaveEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.autoSaveTimeoutLabel)
                    
                    HStack {
                        Text("\(Int(captureManager.settings.autoSaveTimeout)) 秒")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Slider(
                            value: $captureManager.settings.autoSaveTimeout,
                            in: 3...15,
                            step: 1
                        )
                        .frame(width: 200)
                    }
                }
                .onChange(of: captureManager.settings.autoSaveTimeout) { _, _ in
                    captureManager.saveSettings()
                }
            }
            
            Toggle(isOn: $captureManager.settings.showPreviewBeforeSaving) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.showPreviewLabel)
                    Text("每次都显示筛选框，而不是自动保存")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: captureManager.settings.showPreviewBeforeSaving) { _, _ in
                captureManager.saveSettings()
            }
            
            Toggle(isOn: $captureManager.settings.includeImageInNote) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.includeImageLabel)
                    Text("在笔记中附加截图缩略图")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: captureManager.settings.includeImageInNote) { _, _ in
                captureManager.saveSettings()
            }
        }
    }
    
    private var categorySection: some View {
        Section(header: Text(L10n.categorySection)) {
            Button {
                showingCategoryMappings = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.categoryMappingsTitle)
                        Text(L10n.categoryMappingsDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text(L10n.aboutSection)) {
            HStack {
                Text(L10n.aboutVersion)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://github.com")!) {
                HStack {
                    Text(L10n.aboutHelp)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Link(destination: URL(string: "https://github.com")!) {
                HStack {
                    Text(L10n.aboutFeedback)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct CategoryMappingsView: View {
    @EnvironmentObject var captureManager: CaptureManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("设置每个分类对应的备忘录文件夹名称")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("分类映射")) {
                    ForEach(NoteCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            
                            Text(category.rawValue)
                                .frame(width: 80, alignment: .leading)
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                            
                            TextField("文件夹名称", text: binding(for: category))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Section {
                    Button {
                        resetToDefaults()
                    } label: {
                        HStack {
                            Spacer()
                            Text("恢复默认")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(L10n.categoryMappingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.done) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func binding(for category: NoteCategory) -> Binding<String> {
        Binding(
            get: {
                captureManager.settings.categoryMappings[category] ?? category.folderName
            },
            set: { newValue in
                captureManager.settings.categoryMappings[category] = newValue
                captureManager.saveSettings()
            }
        )
    }
    
    private func resetToDefaults() {
        for category in NoteCategory.allCases {
            captureManager.settings.categoryMappings[category] = category.folderName
        }
        captureManager.saveSettings()
    }
}

#Preview {
    SettingsView()
        .environmentObject(CaptureManager.shared)
        .environmentObject(PhotoKitMonitor.shared)
}
