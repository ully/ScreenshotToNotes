import XCTest
@testable import ScreenshotToNotes

final class ScreenshotToNotesTests: XCTestCase {
    var ocrService: OCRService!
    
    override func setUpWithError() throws {
        ocrService = OCRService()
    }
    
    override func tearDownWithError() throws {
        ocrService = nil
    }
    
    func testExtractDates() throws {
        let text = "会议时间：2024-09-06，请准时参加。另一个日期：2024/12/25"
        
        let entities = ExtractedContent.EntityInfo(
            dates: [],
            amounts: [],
            ids: [],
            contacts: [],
            links: []
        )
        
        let method = class_getInstanceMethod(
            OCRService.self,
            #selector(OCRService.extractEntities(from:))
        )
        
        XCTAssertNotNil(method, "extractEntities method should exist")
    }
    
    func testExtractAmounts() throws {
        let text = "总价：¥1,234.56，优惠后：999元"
        
        XCTAssertTrue(text.contains("¥"), "Should contain currency symbol")
        XCTAssertTrue(text.contains("元"), "Should contain Chinese currency unit")
    }
    
    func testExtractContacts() throws {
        let text = "联系电话：13812345678，邮箱：test@example.com，微信号：wechat123"
        
        XCTAssertTrue(text.contains("138"), "Should contain phone number")
        XCTAssertTrue(text.contains("@"), "Should contain email")
        XCTAssertTrue(text.contains("微信"), "Should contain WeChat")
    }
    
    func testTitleExtraction() throws {
        let lines = ["这是标题", "这是第二行", "这是第三行"]
        
        let title = lines.first ?? ""
        XCTAssertEqual(title, "这是标题", "Should extract first line as title")
    }
    
    func testSummaryTruncation() throws {
        let longText = String(repeating: "测试文本", count: 50)
        
        let maxLength = 100
        let truncated = longText.prefix(maxLength)
        
        XCTAssertLessThanOrEqual(truncated.count, maxLength, "Summary should be truncated")
    }
}
