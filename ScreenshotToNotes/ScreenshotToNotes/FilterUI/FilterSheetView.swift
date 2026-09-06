import SwiftUI

struct FilterSheetView: View {
    let content: ExtractedContent
    let onSelection: (NoteCategory?) async -> Void
    
    @State private var selectedCategory: NoteCategory
    @State private var remainingTime: TimeInterval
    @State private var timer: Timer?
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var captureManager: CaptureManager
    
    init(content: ExtractedContent, onSelection: @escaping (NoteCategory?) async -> Void) {
        self.content = content
        self.onSelection = onSelection
        _selectedCategory = State(initialValue: content.category)
        _remainingTime = State(initialValue: CaptureManager.shared.settings.autoSaveTimeout)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let imageData = content.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(12)
                        .padding(.top)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(content.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(content.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                Divider()
                
                VStack(spacing: 16) {
                    HStack {
                        Text(L10n.selectCategory)
                            .font(.headline)
                        
                        Spacer()
                        
                        if captureManager.settings.autoSaveEnabled && !isSaving {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                Text("\(Int(remainingTime))\(L10n.autoSavingIn)")
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal)
                    
                    if content.categoryConfidence > 0.6 {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("\(L10n.recommendedCategory)：\(content.category.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(NoteCategory.allCases.filter { $0 != .other && $0 != .inbox }, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category,
                                isRecommended: category == content.category && content.categoryConfidence > 0.6
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        cancelSave()
                    } label: {
                        Text(L10n.doNotSave)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        Task {
                            await saveNow()
                        }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isSaving ? L10n.savingToNotes : L10n.save)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedCategory.color)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle(L10n.selectCategory)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        cancelSave()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        guard captureManager.settings.autoSaveEnabled else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                Task {
                    await saveNow()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func saveNow() async {
        guard !isSaving else { return }
        
        isSaving = true
        stopTimer()
        
        await onSelection(selectedCategory)
        
        dismiss()
    }
    
    private func cancelSave() {
        stopTimer()
        
        Task {
            await onSelection(nil)
        }
        
        dismiss()
    }
}

struct CategoryChip: View {
    let category: NoteCategory
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : category.color)
                    
                    if isRecommended {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                            .offset(x: 8, y: -8)
                    }
                }
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? category.color : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isRecommended && !isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterSheetView(
        content: ExtractedContent(
            title: "测试标题",
            summary: "这是一个测试摘要",
            category: .insight,
            categoryConfidence: 0.8,
            body: "测试内容"
        )
    ) { _ in }
    .environmentObject(CaptureManager.shared)
}
