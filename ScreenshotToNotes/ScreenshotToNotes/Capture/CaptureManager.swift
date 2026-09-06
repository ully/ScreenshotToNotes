import Foundation
import UIKit
import Photos

@MainActor
class CaptureManager: ObservableObject {
    static let shared = CaptureManager()
    
    @Published var recentRecords: [ProcessingRecord] = []
    @Published var isProcessing = false
    @Published var settings = AppSettings()
    
    private let ocrService = OCRService()
    private let classifier = CategoryClassifier()
    private let maxRecentRecords = 20
    
    private init() {
        loadRecords()
    }
    
    func getLatestScreenshot() async -> UIImage? {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            return nil
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
        fetchOptions.fetchLimit = 1
        
        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard let asset = results.firstObject else {
            return nil
        }
        
        return await loadImage(from: asset)
    }
    
    private func loadImage(from asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    func processScreenshot(_ image: UIImage) async throws -> ExtractedContent {
        isProcessing = true
        defer { isProcessing = false }
        
        let screenshotId = UUID().uuidString
        var record = ProcessingRecord(screenshotId: screenshotId, status: .pending)
        await addRecord(record)
        
        do {
            let ocrResult = try await ocrService.recognizeText(in: image)
            
            let classification = classifier.classify(text: ocrResult.fullText)
            
            let imageData = settings.includeImageInNote ? image.jpegData(compressionQuality: 0.8) : nil
            
            var content = ExtractedContent(
                title: ocrResult.title,
                summary: ocrResult.summary,
                category: classification.category,
                categoryConfidence: classification.confidence,
                tags: classification.tags,
                body: ocrResult.fullText,
                entities: ocrResult.entities,
                sourceGuess: classification.sourceGuess,
                screenshotTime: Date(),
                processedTime: Date(),
                imageData: imageData
            )
            
            record.status = .success
            record.content = content
            await updateRecord(record)
            
            return content
        } catch {
            record.status = .failed
            record.errorMessage = error.localizedDescription
            await updateRecord(record)
            throw error
        }
    }
    
    func recordSuccess(content: ExtractedContent) async {
        if let index = recentRecords.firstIndex(where: { $0.content?.id == content.id }) {
            recentRecords[index].status = .success
            saveRecords()
        }
    }
    
    func recordFailure(error: Error) async {
        let record = ProcessingRecord(
            screenshotId: UUID().uuidString,
            status: .failed,
            errorMessage: error.localizedDescription
        )
        await addRecord(record)
    }
    
    private func addRecord(_ record: ProcessingRecord) async {
        recentRecords.insert(record, at: 0)
        if recentRecords.count > maxRecentRecords {
            recentRecords = Array(recentRecords.prefix(maxRecentRecords))
        }
        saveRecords()
    }
    
    private func updateRecord(_ record: ProcessingRecord) async {
        if let index = recentRecords.firstIndex(where: { $0.id == record.id }) {
            recentRecords[index] = record
            saveRecords()
        }
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "appSettings")
        }
    }
    
    private func saveRecords() {
        if let data = try? JSONEncoder().encode(recentRecords) {
            UserDefaults.standard.set(data, forKey: "recentRecords")
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: "recentRecords"),
           let records = try? JSONDecoder().decode([ProcessingRecord].self, from: data) {
            recentRecords = records
        }
    }
}
