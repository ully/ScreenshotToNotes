import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var captureManager: CaptureManager
    @State private var selectedFilter: FilterType = .all
    @State private var showingClearAlert = false
    
    enum FilterType: String, CaseIterable {
        case all = "全部"
        case success = "成功"
        case failed = "失败"
    }
    
    var filteredRecords: [ProcessingRecord] {
        switch selectedFilter {
        case .all:
            return captureManager.recentRecords
        case .success:
            return captureManager.recentRecords.filter { $0.status == .success }
        case .failed:
            return captureManager.recentRecords.filter { $0.status == .failed }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterSegment
                
                if filteredRecords.isEmpty {
                    emptyStateView
                } else {
                    recordsList
                }
            }
            .navigationTitle(L10n.historyTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showingClearAlert = true
                        } label: {
                            Label(L10n.clearHistory, systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("清空历史记录", isPresented: $showingClearAlert) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    clearHistory()
                }
            } message: {
                Text("确定要清空所有历史记录吗？此操作不可恢复。")
            }
        }
    }
    
    private var filterSegment: some View {
        Picker("筛选", selection: $selectedFilter) {
            ForEach(FilterType.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("暂无记录")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var recordsList: some View {
        List {
            ForEach(filteredRecords) { record in
                NavigationLink {
                    RecordDetailView(record: record)
                } label: {
                    RecordRowView(record: record)
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func clearHistory() {
        captureManager.recentRecords.removeAll()
        if let data = try? JSONEncoder().encode(captureManager.recentRecords) {
            UserDefaults.standard.set(data, forKey: "recentRecords")
        }
    }
}

struct RecordDetailView: View {
    let record: ProcessingRecord
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statusSection
                
                if let content = record.content {
                    contentSection(content)
                } else if let errorMessage = record.errorMessage {
                    errorSection(errorMessage)
                }
            }
            .padding()
        }
        .navigationTitle("详细信息")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("状态")
                    .font(.headline)
                
                Spacer()
                
                HStack {
                    statusIcon
                    Text(record.status.rawValue)
                }
                .foregroundColor(statusColor)
            }
            
            Text(record.timestamp, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(record.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusIcon: Image {
        switch record.status {
        case .pending:
            return Image(systemName: "clock.fill")
        case .success:
            return Image(systemName: "checkmark.circle.fill")
        case .failed:
            return Image(systemName: "xmark.circle.fill")
        case .cancelled:
            return Image(systemName: "minus.circle.fill")
        }
    }
    
    private var statusColor: Color {
        switch record.status {
        case .pending: return .orange
        case .success: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
    
    private func contentSection(_ content: ExtractedContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailRow(label: "标题", value: content.title)
            DetailRow(label: "摘要", value: content.summary)
            
            HStack {
                Text("分类")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack {
                    Image(systemName: content.category.icon)
                    Text(content.category.rawValue)
                }
                .foregroundColor(content.category.color)
            }
            
            DetailRow(label: "置信度", value: String(format: "%.0f%%", content.categoryConfidence * 100))
            
            if !content.tags.isEmpty {
                DetailRow(label: "标签", value: content.tags.joined(separator: ", "))
            }
            
            DetailRow(label: "来源", value: content.sourceGuess.rawValue)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("正文")
                    .font(.headline)
                
                Text(content.body)
                    .font(.body)
            }
            
            if hasEntities(content.entities) {
                Divider()
                entitiesSection(content.entities)
            }
        }
    }
    
    private func errorSection(_ errorMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("错误信息")
                .font(.headline)
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func entitiesSection(_ entities: ExtractedContent.EntityInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("结构化信息")
                .font(.headline)
            
            if !entities.dates.isEmpty {
                EntityRow(label: "日期", values: entities.dates)
            }
            
            if !entities.amounts.isEmpty {
                EntityRow(label: "金额", values: entities.amounts)
            }
            
            if !entities.contacts.isEmpty {
                EntityRow(label: "联系方式", values: entities.contacts)
            }
            
            if !entities.ids.isEmpty {
                EntityRow(label: "编号", values: entities.ids)
            }
            
            if !entities.links.isEmpty {
                EntityRow(label: "链接", values: entities.links)
            }
        }
    }
    
    private func hasEntities(_ entities: ExtractedContent.EntityInfo) -> Bool {
        return !entities.dates.isEmpty || !entities.amounts.isEmpty ||
               !entities.contacts.isEmpty || !entities.ids.isEmpty ||
               !entities.links.isEmpty
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
        }
    }
}

struct EntityRow: View {
    let label: String
    let values: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(values, id: \.self) { value in
                Text("• \(value)")
                    .font(.caption)
            }
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(CaptureManager.shared)
}
