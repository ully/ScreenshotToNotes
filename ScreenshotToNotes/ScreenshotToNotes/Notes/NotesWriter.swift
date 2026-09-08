import Foundation
import UIKit
import EventKit

class NotesWriter {
    static let shared = NotesWriter()
    
    private init() {}
    
    func writeNote(content: ExtractedContent) async throws {
        let noteBody = L10n.noteBodyTemplate(content: content)
        
        let folderName = CaptureManager.shared.settings.categoryMappings[content.category] ?? content.category.folderName
        
        try await writeToNotesApp(title: content.title, body: noteBody, folderName: folderName)
        
        postSuccessNotification(title: content.title, category: content.category)
    }
    
    private func writeToNotesApp(title: String, body: String, folderName: String) async throws {
        guard let urlString = createNotesURL(title: title, body: body),
              let url = URL(string: urlString) else {
            throw NotesWriterError.urlCreationFailed
        }
        
        await MainActor.run {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    private func createNotesURL(title: String, body: String) -> String? {
        let fullText = """
        \(title)
        
        \(body)
        """
        
        guard let encoded = fullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return "mobilenotes://action=append&note=\(encoded)"
    }
    
    private func postSuccessNotification(title: String, category: NoteCategory) {
        let content = UNMutableNotificationContent()
        content.title = L10n.savedToNotes
        content.body = "\(title) → \(category.rawValue)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知发送失败: \(error.localizedDescription)")
            }
        }
    }
}

enum NotesWriterError: LocalizedError {
    case urlCreationFailed
    case notesAppNotAvailable
    case writeFailed
    
    var errorDescription: String? {
        switch self {
        case .urlCreationFailed:
            return "创建 Notes URL 失败"
        case .notesAppNotAvailable:
            return "备忘录 App 不可用"
        case .writeFailed:
            return L10n.errorNotesWriteFailed
        }
    }
}
