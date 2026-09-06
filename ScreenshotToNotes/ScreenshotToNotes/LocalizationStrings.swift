import Foundation

struct L10n {
    // MARK: - 通用
    static let appName = "截图笔记"
    static let cancel = "取消"
    static let confirm = "确认"
    static let save = "保存"
    static let delete = "删除"
    static let settings = "设置"
    static let done = "完成"
    static let error = "错误"
    
    // MARK: - 欢迎 & 引导
    static let welcomeTitle = "欢迎使用截图笔记"
    static let welcomeSubtitle = "截图后自动提取文字，分类保存到备忘录"
    static let getStarted = "开始使用"
    static let skipOnboarding = "跳过引导"
    
    static let onboardingStep1Title = "添加快捷指令"
    static let onboardingStep1Description = "点击下方按钮，导入官方快捷指令到「快捷指令」App"
    static let onboardingStep2Title = "设置自动化"
    static let onboardingStep2Description = """
    1. 打开「快捷指令」App → 自动化 → 创建个人自动化
    2. 选择「截取屏幕时」
    3. 选择刚导入的「截图存到备忘录」指令
    4. **重要**：关闭「运行前询问」开关
    """
    static let onboardingStep3Title = "试试看"
    static let onboardingStep3Description = "现在去截一张图试试，应该会弹出分类选择框"
    
    static let importShortcut = "导入快捷指令"
    static let openShortcutsApp = "打开快捷指令 App"
    static let setupComplete = "设置完成"
    
    static let shortcutNotEnabledBanner = "⚠️ 未开启截图自动保存"
    static let setupAutomation = "去设置自动化"
    
    // MARK: - 权限
    static let photoPermissionTitle = "需要照片权限"
    static let photoPermissionMessage = "用于检测并读取你的新截图"
    static let grantPermission = "授予权限"
    
    // MARK: - 主界面
    static let recentTitle = "最近处理"
    static let historyTitle = "历史记录"
    static let pickFromPhotos = "从相册选择"
    static let processing = "处理中..."
    static let noRecentItems = "暂无记录\n截图后将自动处理"
    
    // MARK: - 筛选框
    static let selectCategory = "选择分类"
    static let recommendedCategory = "推荐"
    static let doNotSave = "不存"
    static let autoSavingIn = "秒后自动保存"
    static let savingToNotes = "正在保存到备忘录..."
    static let savedToNotes = "已保存到备忘录"
    static let saveFailed = "保存失败"
    
    // MARK: - 设置
    static let settingsTitle = "设置"
    static let generalSection = "通用"
    static let autoSaveSection = "自动保存"
    static let categorySection = "分类设置"
    static let aboutSection = "关于"
    
    static let autoSaveEnabledLabel = "启用自动保存"
    static let autoSaveTimeoutLabel = "超时时间"
    static let showPreviewLabel = "保存前预览"
    static let includeImageLabel = "笔记中包含图片"
    static let photoMonitoringLabel = "启用相册监控（后备）"
    
    static let categoryMappingsTitle = "文件夹映射"
    static let categoryMappingsDescription = "设置每个分类对应的备忘录文件夹名称"
    
    static let aboutVersion = "版本"
    static let aboutHelp = "使用帮助"
    static let aboutFeedback = "反馈建议"
    
    // MARK: - 历史
    static let filterAll = "全部"
    static let filterSuccess = "成功"
    static let filterFailed = "失败"
    static let clearHistory = "清空历史"
    static let retryProcessing = "重新处理"
    
    // MARK: - 错误信息
    static let errorGeneric = "处理失败，请重试"
    static let errorOCRFailed = "文字识别失败"
    static let errorNoTextFound = "未识别到文字"
    static let errorNotesWriteFailed = "写入备忘录失败"
    static let errorPhotoAccessDenied = "未授权访问相册"
    static let errorImageLoadFailed = "图片加载失败"
    
    // MARK: - Notes 模板
    static func noteBodyTemplate(content: ExtractedContent) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        var body = """
        # \(content.title)
        
        > \(content.summary)
        
        **类别：** \(content.category.rawValue)
        **标签：** #截图收藏 #\(content.category.rawValue) \(content.tags.map { "#\($0)" }.joined(separator: " "))
        **截取时间：** \(dateFormatter.string(from: content.screenshotTime))
        **保存时间：** \(dateFormatter.string(from: content.processedTime))
        
        ---
        
        \(content.body)
        
        """
        
        if !content.entities.dates.isEmpty || !content.entities.amounts.isEmpty ||
           !content.entities.ids.isEmpty || !content.entities.contacts.isEmpty ||
           !content.entities.links.isEmpty {
            body += """
            
            ---
            
            **结构化信息**
            """
            
            if !content.entities.dates.isEmpty {
                body += "\n- 日期：\(content.entities.dates.joined(separator: ", "))"
            }
            if !content.entities.amounts.isEmpty {
                body += "\n- 金额：\(content.entities.amounts.joined(separator: ", "))"
            }
            if !content.entities.contacts.isEmpty {
                body += "\n- 联系方式：\(content.entities.contacts.joined(separator: ", "))"
            }
            if !content.entities.ids.isEmpty {
                body += "\n- 编号：\(content.entities.ids.joined(separator: ", "))"
            }
            if !content.entities.links.isEmpty {
                body += "\n- 链接：\(content.entities.links.joined(separator: ", "))"
            }
        }
        
        body += """
        
        
        ---
        
        **来源：** 用户截图（疑似\(content.sourceGuess.rawValue)）
        """
        
        return body
    }
}
