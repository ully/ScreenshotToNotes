import Foundation

struct ClassificationResult {
    let category: NoteCategory
    let confidence: Double
    let tags: [String]
    let sourceGuess: SourceGuess
}

protocol CategoryClassifierProtocol {
    func classify(text: String) -> ClassificationResult
}

class CategoryClassifier: CategoryClassifierProtocol {
    func classify(text: String) -> ClassificationResult {
        let lowercasedText = text.lowercased()
        
        let sourceGuess = guessSource(from: text)
        
        let category = determineCategory(from: lowercasedText)
        
        let confidence = calculateConfidence(for: category, text: lowercasedText)
        
        let tags = extractTags(from: text, category: category)
        
        return ClassificationResult(
            category: category,
            confidence: confidence,
            tags: tags,
            sourceGuess: sourceGuess
        )
    }
    
    private func guessSource(from text: String) -> SourceGuess {
        let indicators: [(SourceGuess, [String])] = [
            (.douyin, ["抖音", "douyin", "点赞", "关注", "粉丝", "直播间"]),
            (.twitter, ["twitter", "tweet", "retweet", "@", "转推"]),
            (.wechat, ["微信", "wechat", "公众号", "阅读原文", "点击查看"]),
            (.xiaohongshu, ["小红书", "redbook", "种草", "笔记", "薯条"]),
            (.chat, ["聊天记录", "微信", "qq", "telegram", "whatsapp"]),
            (.web, ["http://", "https://", "www.", ".com", ".cn"])
        ]
        
        let lowercasedText = text.lowercased()
        
        for (source, keywords) in indicators {
            for keyword in keywords {
                if lowercasedText.contains(keyword.lowercased()) {
                    return source
                }
            }
        }
        
        return .unknown
    }
    
    private func determineCategory(from text: String) -> NoteCategory {
        let categories: [(NoteCategory, [String], Double)] = [
            (.task, ["待办", "todo", "任务", "需要", "记得", "提醒", "ddl", "deadline", "完成", "□", "☐"], 2.0),
            (.receipt, ["订单", "支付", "金额", "¥", "$", "元", "发票", "收据", "单号", "快递", "物流"], 2.0),
            (.contact, ["电话", "手机", "微信", "邮箱", "@", "联系", "地址", "qq"], 2.0),
            (.howto, ["教程", "步骤", "方法", "如何", "怎么", "攻略", "指南", "教学", "技巧"], 1.5),
            (.insight, ["名言", "金句", "观点", "想法", "灵感", "感悟", "思考", "quote"], 1.2),
            (.product, ["价格", "购买", "商品", "产品", "型号", "参数", "配置", "规格"], 1.5)
        ]
        
        var scores: [NoteCategory: Double] = [:]
        
        for (category, keywords, weight) in categories {
            var score: Double = 0
            for keyword in keywords {
                let count = text.components(separatedBy: keyword).count - 1
                score += Double(count) * weight
            }
            scores[category] = score
        }
        
        if let bestMatch = scores.max(by: { $0.value < $1.value }),
           bestMatch.value > 0 {
            return bestMatch.key
        }
        
        return .inbox
    }
    
    private func calculateConfidence(for category: NoteCategory, text: String) -> Double {
        let categoryKeywords: [NoteCategory: [String]] = [
            .task: ["待办", "todo", "任务", "需要", "记得"],
            .receipt: ["订单", "支付", "金额", "¥", "$", "元"],
            .contact: ["电话", "手机", "微信", "邮箱"],
            .howto: ["教程", "步骤", "方法", "如何"],
            .insight: ["名言", "金句", "观点", "想法"],
            .product: ["价格", "购买", "商品", "产品"]
        ]
        
        guard let keywords = categoryKeywords[category] else {
            return 0.3
        }
        
        var matchCount = 0
        for keyword in keywords {
            if text.contains(keyword) {
                matchCount += 1
            }
        }
        
        let confidence = min(0.5 + Double(matchCount) * 0.15, 0.95)
        return confidence
    }
    
    private func extractTags(from text: String, category: NoteCategory) -> [String] {
        var tags: [String] = []
        
        let hashtagPattern = "#[\\w\\u4e00-\\u9fa5]+"
        if let regex = try? NSRegularExpression(pattern: hashtagPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let tag = String(text[range]).replacingOccurrences(of: "#", with: "")
                    tags.append(tag)
                }
            }
        }
        
        let topicKeywords: [String: [String]] = [
            "技术": ["代码", "编程", "开发", "算法", "api"],
            "健康": ["运动", "健身", "饮食", "营养", "睡眠"],
            "学习": ["课程", "笔记", "复习", "考试", "知识"],
            "生活": ["日常", "美食", "旅行", "购物"],
            "工作": ["会议", "项目", "报告", "汇报", "总结"]
        ]
        
        let lowercasedText = text.lowercased()
        for (tag, keywords) in topicKeywords {
            for keyword in keywords {
                if lowercasedText.contains(keyword) {
                    tags.append(tag)
                    break
                }
            }
        }
        
        return Array(Set(tags))
    }
}
