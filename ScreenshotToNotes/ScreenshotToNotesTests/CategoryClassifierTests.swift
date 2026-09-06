import XCTest
@testable import ScreenshotToNotes

final class CategoryClassifierTests: XCTestCase {
    var classifier: CategoryClassifier!
    
    override func setUpWithError() throws {
        classifier = CategoryClassifier()
    }
    
    override func tearDownWithError() throws {
        classifier = nil
    }
    
    func testClassifyTask() throws {
        let text = "记得明天交报告，截止时间DDL是下午5点"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.category, .task, "Should classify as task")
        XCTAssertGreaterThan(result.confidence, 0.5, "Confidence should be reasonable")
    }
    
    func testClassifyReceipt() throws {
        let text = "订单号：123456789，支付金额：¥299.00，请保存好收据"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.category, .receipt, "Should classify as receipt")
    }
    
    func testClassifyContact() throws {
        let text = "我的联系方式：手机13812345678，微信号：test123，邮箱：test@example.com"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.category, .contact, "Should classify as contact")
    }
    
    func testClassifyHowTo() throws {
        let text = "这是一个教程：第一步，打开应用；第二步，选择功能；第三步，完成设置"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.category, .howto, "Should classify as how-to")
    }
    
    func testClassifyInsight() throws {
        let text = "今天看到一句金句：成功不是终点，失败也不是末日，重要的是继续前进的勇气"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.category, .insight, "Should classify as insight")
    }
    
    func testGuessSourceDouyin() throws {
        let text = "抖音热门 #点赞关注 这个视频太有意思了"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .douyin, "Should guess source as Douyin")
    }
    
    func testGuessSourceTwitter() throws {
        let text = "@username just tweeted something interesting"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .twitter, "Should guess source as Twitter")
    }
    
    func testGuessSourceWechat() throws {
        let text = "微信公众号文章：点击阅读原文查看更多"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.sourceGuess, .wechat, "Should guess source as WeChat")
    }
    
    func testExtractTags() throws {
        let text = "这是一个关于#编程的文章，包含#技术和#学习的内容"
        let result = classifier.classify(text: text)
        
        XCTAssertTrue(result.tags.contains("编程") || result.tags.contains("技术"), 
                     "Should extract hashtags")
    }
    
    func testLowConfidenceDefaultsToInbox() throws {
        let text = "一些随机的文字，没有明确的分类特征"
        let result = classifier.classify(text: text)
        
        XCTAssertEqual(result.category, .inbox, "Low confidence should default to inbox")
    }
    
    func testConfidenceCalculation() throws {
        let textWithManyKeywords = "这是一个待办任务，需要完成的任务列表，记得做完"
        let result = classifier.classify(text: textWithManyKeywords)
        
        XCTAssertGreaterThan(result.confidence, 0.5, "Multiple keywords should increase confidence")
        XCTAssertLessThanOrEqual(result.confidence, 1.0, "Confidence should not exceed 1.0")
    }
}
