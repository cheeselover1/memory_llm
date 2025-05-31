import Foundation
import UIKit

class GeminiService {
    static let shared = GeminiService()
    private let apiKey = "YOUR_GEMINI_API_KEY" // 请在 Info.plist 或安全位置配置
    private let apiURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key=YOUR_GEMINI_API_KEY")!
    
    func compressImage(_ image: UIImage, maxSizeMB: Double = 4.5) -> Data? {
        var compression: CGFloat = 0.8
        let maxBytes = Int(maxSizeMB * 1024 * 1024)
        var imageData = image.jpegData(compressionQuality: compression)
        while let data = imageData, data.count > maxBytes, compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        return imageData
    }
    
    func askGemini(image: UIImage, question: String, completion: @escaping (String?) -> Void) {
        guard let imageData = compressImage(image) else {
            print("图片压缩失败")
            completion(nil)
            return
        }
        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "text": question
                        ]
                    ]
                ]
            ]
        ]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            print("[GeminiService] JSON序列化失败")
            completion(nil)
            return
        }
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[GeminiService] 网络错误：", error)
                completion(nil)
                return
            }
            if let data = data {
                print("[GeminiService] Gemini返回原始内容：", String(data: data, encoding: .utf8) ?? "<无法解码>")
            }
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let first = candidates.first,
               let content = first["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                completion(text)
            } else {
                print("[GeminiService] 解析失败或无有效内容")
                completion(nil)
            }
        }
        task.resume()
    }
} 