import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentStep = 0
    @State private var showingShortcutImport = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TabView(selection: $currentStep) {
                    WelcomeStepView()
                        .tag(0)
                    
                    ShortcutImportStepView(showingShortcutImport: $showingShortcutImport)
                        .tag(1)
                    
                    AutomationSetupStepView()
                        .tag(2)
                    
                    PermissionsStepView()
                        .tag(3)
                    
                    TestStepView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                navigationButtons
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.skipOnboarding) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                    Text("上一步")
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            if currentStep < 4 {
                Button {
                    withAnimation {
                        currentStep += 1
                    }
                } label: {
                    Text("下一步")
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "doc.text.image")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(L10n.welcomeTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(L10n.welcomeSubtitle)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "bolt.fill", title: "自动触发", description: "截图后自动处理，无需手动分享")
                FeatureRow(icon: "doc.text.magnifyingglass", title: "智能提取", description: "OCR + 分类，提取关键信息")
                FeatureRow(icon: "folder.fill", title: "自动归类", description: "按类别保存到备忘录文件夹")
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ShortcutImportStepView: View {
    @Binding var showingShortcutImport: Bool
    @State private var hasImported = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(L10n.onboardingStep1Title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(L10n.onboardingStep1Description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            VStack(spacing: 16) {
                Button {
                    importShortcut()
                } label: {
                    Label(L10n.importShortcut, systemImage: "square.and.arrow.down.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                if hasImported {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已导入快捷指令")
                            .foregroundColor(.green)
                    }
                }
            }
            
            Divider()
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("快捷指令功能：")
                    .font(.headline)
                
                InstructionRow(text: "获取最新截图")
                InstructionRow(text: "调用本 App 的 App Intent")
                InstructionRow(text: "显示分类选择界面")
                InstructionRow(text: "保存到备忘录")
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 40)
    }
    
    private func importShortcut() {
        if let url = URL(string: "shortcuts://import-shortcut?url=https://www.icloud.com/shortcuts/placeholder") {
            UIApplication.shared.open(url)
            hasImported = true
        }
    }
}

struct InstructionRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.blue)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct AutomationSetupStepView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text(L10n.onboardingStep2Title)
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 20) {
                    StepCard(
                        number: "1",
                        title: "打开快捷指令 App",
                        description: "进入「自动化」标签页"
                    )
                    
                    StepCard(
                        number: "2",
                        title: "创建个人自动化",
                        description: "点击右上角 + 号，选择「创建个人自动化」"
                    )
                    
                    StepCard(
                        number: "3",
                        title: "选择「截取屏幕时」",
                        description: "在触发条件列表中找到并选择"
                    )
                    
                    StepCard(
                        number: "4",
                        title: "添加操作",
                        description: "搜索并选择刚导入的「截图存到备忘录」快捷指令"
                    )
                    
                    StepCard(
                        number: "5",
                        title: "关闭「运行前询问」",
                        description: "⚠️ 重要：关闭此开关才能实现自动触发",
                        important: true
                    )
                }
                .padding(.horizontal, 20)
                
                Button {
                    if let url = URL(string: "shortcuts://") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label(L10n.openShortcutsApp, systemImage: "arrow.up.right.square.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
        }
    }
}

struct StepCard: View {
    let number: String
    let title: String
    let description: String
    var important: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(important ? Color.orange : Color.blue)
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(important ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PermissionsStepView: View {
    @State private var photoAuthStatus: String = "未授权"
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("权限设置")
                .font(.title)
                .fontWeight(.bold)
            
            Text("为了正常工作，需要以下权限")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            VStack(spacing: 16) {
                PermissionCard(
                    icon: "photo.fill",
                    title: "照片",
                    description: L10n.photoPermissionMessage,
                    status: photoAuthStatus
                )
                
                PermissionCard(
                    icon: "bell.fill",
                    title: "通知",
                    description: "用于「已保存到备忘录」回执",
                    status: "可选"
                )
            }
            .padding(.horizontal, 20)
            
            Button {
                requestPhotoPermission()
            } label: {
                Label(L10n.grantPermission, systemImage: "hand.raised.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
        .onAppear {
            checkPhotoPermission()
        }
    }
    
    private func checkPhotoPermission() {
        let status = PhotoKitMonitor.shared.checkAuthorization()
        switch status {
        case .authorized, .limited:
            photoAuthStatus = "已授权"
        case .denied, .restricted:
            photoAuthStatus = "已拒绝"
        case .notDetermined:
            photoAuthStatus = "未授权"
        @unknown default:
            photoAuthStatus = "未知"
        }
    }
    
    private func requestPhotoPermission() {
        PhotoKitMonitor.shared.requestAuthorization { granted in
            DispatchQueue.main.async {
                photoAuthStatus = granted ? "已授权" : "已拒绝"
            }
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let status: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(status)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case "已授权": return .green
        case "已拒绝": return .red
        case "可选": return .orange
        default: return .gray
        }
    }
}

struct TestStepView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text(L10n.onboardingStep3Title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(L10n.onboardingStep3Description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            VStack(spacing: 20) {
                TestInstructionCard(
                    icon: "camera.fill",
                    title: "方法 1：系统截图",
                    description: "按音量+ 和电源键截图，应该自动弹出分类选择"
                )
                
                TestInstructionCard(
                    icon: "hand.tap.fill",
                    title: "方法 2：辅助触控（可选）",
                    description: "如已设置辅助触控或背面轻点，也可触发"
                )
                
                TestInstructionCard(
                    icon: "photo.fill",
                    title: "方法 3：手动选择",
                    description: "进入 App 后从相册选择截图手动处理"
                )
            }
            .padding(.horizontal, 20)
            
            Button {
                completeOnboarding()
            } label: {
                Label(L10n.setupComplete, systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        PhotoKitMonitor.shared.startMonitoring()
    }
}

struct TestInstructionCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
