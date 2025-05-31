import Foundation
import SwiftUI

struct MemoryImage: Identifiable, Codable {
    let id: UUID
    let imageData: Data
    // 预留 embedding 字段，后续可用
    var embedding: [Double]?
    
    init(image: UIImage) {
        self.id = UUID()
        self.imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
        self.embedding = nil
    }
    
    func uiImage() -> UIImage? {
        UIImage(data: imageData)
    }
} 