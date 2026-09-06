import Foundation
import Photos
import UIKit

@MainActor
class PhotoKitMonitor: NSObject, ObservableObject {
    static let shared = PhotoKitMonitor()
    
    @Published var isMonitoring = false
    private var lastProcessedAssetId: String?
    private var photoLibraryChangeObserver: PHPhotoLibraryChangeObserver?
    
    private override init() {
        super.init()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            return
        }
        
        PHPhotoLibrary.shared().register(self)
        isMonitoring = true
        print("📸 PhotoKit 监控已启动")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        isMonitoring = false
        print("📸 PhotoKit 监控已停止")
    }
    
    func checkAuthorization() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                let granted = status == .authorized || status == .limited
                completion(granted)
            }
        }
    }
    
    private func checkForNewScreenshots() {
        Task {
            await processNewScreenshot()
        }
    }
    
    private func processNewScreenshot() async {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
        fetchOptions.fetchLimit = 1
        
        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard let asset = results.firstObject else {
            return
        }
        
        let assetId = asset.localIdentifier
        guard assetId != lastProcessedAssetId else {
            return
        }
        
        let creationDate = asset.creationDate ?? Date()
        let timeSinceCreation = Date().timeIntervalSince(creationDate)
        
        guard timeSinceCreation < 10 else {
            return
        }
        
        lastProcessedAssetId = assetId
        
        guard let image = await loadImage(from: asset) else {
            return
        }
        
        print("📸 检测到新截图，准备处理")
        
        await notifyNewScreenshot(image)
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
    
    private func notifyNewScreenshot(_ image: UIImage) async {
        NotificationCenter.default.post(
            name: NSNotification.Name("NewScreenshotDetected"),
            object: nil,
            userInfo: ["image": image]
        )
    }
}

extension PhotoKitMonitor: PHPhotoLibraryChangeObserver {
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            checkForNewScreenshots()
        }
    }
}
