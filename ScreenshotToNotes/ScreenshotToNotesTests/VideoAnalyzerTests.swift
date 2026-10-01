import XCTest
@testable import ScreenshotToNotes

final class VideoAnalyzerTests: XCTestCase {
    var analyzer: VideoScreenshotAnalyzer!
    var classifier: CategoryClassifier!
    
    override func setUpWithError() throws {
        analyzer = VideoScreenshotAnalyzer()
        classifier = CategoryClassifier()
    }
    
    override func tearDownWithError() throws {
        analyzer = nil
        classifier = nil
    }
    
    // MARK: - 平台识别测试（国内）
    
    func testClassifyDouyinVideo() throws {
        let text = "@美食博主 教你做麻辣香锅 #美食教程 #做菜 点赞关注"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .douyin, "应该识别为抖音")
        XCTAssertTrue([.videoTutorial, .videoCollection].contains(result.category), "应该分类为视频相关")
    }
    
    func testClassifyKuaishouVideo() throws {
        let text = "快手号：foodlover 老铁双击666 #搞笑段子"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .kuaishou, "应该识别为快手")
    }
    
    func testClassifyBilibiliVideo() throws {
        let text = "UP主：技术分享 一键三连！BV1234567 投币支持"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .bilibili, "应该识别为B站")
    }
    
    func testClassifyXiaoHongShuVideo() throws {
        let text = "小红薯分享 #种草 #小红书笔记 薯条加热中"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .xiaohongshu, "应该识别为小红书")
    }
    
    // MARK: - 平台识别测试（国际）
    
    func testClassifyYouTubeVideo() throws {
        let text = "Subscribe to @TechReviewer youtube.com notification bell"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .youtube, "应该识别为YouTube")
    }
    
    func testClassifyTikTokVideo() throws {
        let text = "@creator.name For You Page #fyp tiktok.com"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .tiktok, "应该识别为TikTok")
    }
    
    func testClassifyInstagramReels() throws {
        let text = "@fashion.blogger instagram Reels #ootd ig"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .instagram, "应该识别为Instagram")
    }
    
    func testClassifyTwitchStream() throws {
        let text = "@streamer is streaming live on twitch.tv 1.2K watching"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .twitch, "应该识别为Twitch")
    }
    
    func testClassifyRedditVideo() throws {
        let text = "Posted by u/username on r/videos reddit.com upvote"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .reddit, "应该识别为Reddit")
    }
    
    // MARK: - 视频类型检测测试
    
    func testDetectTutorialVideo() throws {
        let text = "教你做红烧肉的详细步骤 #美食教程 第一步：准备材料"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.category, .videoTutorial, "应该分类为教程视频")
    }
    
    func testDetectEntertainmentVideo() throws {
        let text = "搞笑段子：这也太有趣了哈哈哈 #娱乐 #笑话"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.category, .videoEntertainment, "应该分类为娱乐视频")
    }
    
    // MARK: - 作者提取测试
    
    func testExtractAuthorFromDouyin() throws {
        let text = "@美食博主 今天教大家做宫保鸡丁"
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .douyin)
        
        XCTAssertNotNil(videoResult.author, "应该提取到作者")
        XCTAssertEqual(videoResult.author, "美食博主")
    }
    
    func testExtractAuthorFromBilibili() throws {
        let text = "UP主：科技评测君 给大家带来最新的手机测评"
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .bilibili)
        
        XCTAssertNotNil(videoResult.author, "应该提取到UP主")
        XCTAssertEqual(videoResult.author, "科技评测君")
    }
    
    // MARK: - 时长提取测试
    
    func testExtractVideoDuration() throws {
        let text = "精彩视频 3:45 不容错过"
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .douyin)
        
        XCTAssertNotNil(videoResult.duration, "应该提取到时长")
        XCTAssertEqual(videoResult.duration, "3:45")
    }
    
    func testExtractShortVideoDuration() throws {
        let text = "短视频 0:15 秒"
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .douyin)
        
        XCTAssertNotNil(videoResult.duration, "应该提取到短视频时长")
    }
    
    // MARK: - 视频数据提取测试（中文）
    
    func testExtractVideoStatsChinese() throws {
        let text = """
        精彩视频
        12.5万 赞
        8888 评论
        3.2万 分享
        285万 播放
        """
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .douyin)
        
        XCTAssertNotNil(videoResult.stats, "应该提取到视频数据")
        XCTAssertNotNil(videoResult.stats?.likes, "应该提取到点赞数")
        XCTAssertNotNil(videoResult.stats?.comments, "应该提取到评论数")
        XCTAssertNotNil(videoResult.stats?.shares, "应该提取到分享数")
        XCTAssertNotNil(videoResult.stats?.views, "应该提取到播放数")
    }
    
    // MARK: - 视频数据提取测试（英文）
    
    func testExtractVideoStatsEnglish() throws {
        let text = """
        Amazing video
        125K Likes
        8.8K Comments
        32K Shares
        2.8M Views
        """
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .youtube)
        
        XCTAssertNotNil(videoResult.stats, "应该提取到视频数据")
        XCTAssertNotNil(videoResult.stats?.likes, "应该提取到点赞数")
        XCTAssertNotNil(videoResult.stats?.comments, "应该提取到评论数")
        XCTAssertNotNil(videoResult.stats?.shares, "应该提取到分享数")
        XCTAssertNotNil(videoResult.stats?.views, "应该提取到播放数")
    }
    
    // MARK: - 作者提取测试（国际平台）
    
    func testExtractAuthorFromYouTube() throws {
        let text = "@TechChannel Subscribe for more tech reviews"
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .youtube)
        
        XCTAssertNotNil(videoResult.author, "应该提取到YouTube频道")
        XCTAssertEqual(videoResult.author, "TechChannel")
    }
    
    func testExtractAuthorFromTikTok() throws {
        let text = "@creator.official New video on TikTok"
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .tiktok)
        
        XCTAssertNotNil(videoResult.author, "应该提取到TikTok创作者")
        XCTAssertTrue(videoResult.author?.contains("creator") ?? false)
    }
    
    func testExtractAuthorFromReddit() throws {
        let text = "Posted by u/cooluser on r/videos"
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .reddit)
        
        XCTAssertNotNil(videoResult.author, "应该提取到Reddit用户")
        XCTAssertEqual(videoResult.author, "cooluser")
    }
    
    // MARK: - 话题标签提取测试
    
    func testExtractVideoTopics() throws {
        let text = "分享美食制作 #美食教程 #做菜技巧 #家常菜"
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .douyin)
        
        XCTAssertFalse(videoResult.topics.isEmpty, "应该提取到话题标签")
        XCTAssertTrue(videoResult.topics.contains("美食教程"), "应该包含美食教程标签")
        XCTAssertTrue(videoResult.topics.contains("做菜技巧"), "应该包含做菜技巧标签")
    }
    
    // MARK: - 视频类型判断测试
    
    func testDetectFoodVideo() throws {
        let text = "教你做美食 烹饪技巧 食谱分享"
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .douyin)
        
        XCTAssertEqual(videoResult.videoType, .food, "应该识别为美食视频")
    }
    
    func testDetectFitnessVideo() throws {
        let text = "健身教程 减肥训练 锻炼身体"
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .douyin)
        
        XCTAssertEqual(videoResult.videoType, .fitness, "应该识别为健身视频")
    }
    
    func testDetectTechVideo() throws {
        let text = "手机测评 科技数码 软件教程"
        let videoResult = analyzer.analyzeVideoScreenshot(text: text, sourceGuess: .douyin)
        
        XCTAssertEqual(videoResult.videoType, .tech, "应该识别为科技视频")
    }
    
    // MARK: - 分类建议测试
    
    func testTutorialVideoCategorySuggestion() throws {
        let videoType = VideoType.tutorial
        XCTAssertEqual(videoType.suggestedCategory, .videoTutorial, "教程视频应该建议分类为教程视频")
    }
    
    func testEntertainmentVideoCategorySuggestion() throws {
        let videoType = VideoType.entertainment
        XCTAssertEqual(videoType.suggestedCategory, .videoEntertainment, "娱乐视频应该建议分类为娱乐视频")
    }
    
    func testDefaultVideoCategorySuggestion() throws {
        let videoType = VideoType.food
        XCTAssertEqual(videoType.suggestedCategory, .videoCollection, "其他类型视频应该建议分类为视频收藏")
    }
}
