import Foundation
import UIKit

class AnthropicService {
    static let shared = AnthropicService()
    private let apiKey = "YOUR_ANTHROPIC_API_KEY" // 请在 Info.plist 或安全位置配置
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-opus-4-20250514" // 使用 Claude 4 最新模型
    
    func describeImage(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("[AnthropicService] 图片转码失败")
            completion(nil)
            return
        }
        
        // 构造 multipart/form-data
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 构造 JSON body
        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 256,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "image", "source": ["type": "base64", "media_type": "image/jpeg", "data": base64Image]],
                        ["type": "text", "text": "Describe this image in English in one sentence."]
                    ]
                ]
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            print("[AnthropicService] JSON序列化失败")
            completion(nil)
            return
        }
        request.httpBody = httpBody
        
        // 发送请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[AnthropicService] 网络错误：", error)
                completion(nil)
                return
            }
            if let data = data {
                print("[AnthropicService] Claude返回原始内容：", String(data: data, encoding: .utf8) ?? "<无法解码>")
            }
            // 解析返回
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let contentArr = (json["content"] as? [[String: Any]]),
               let textObj = contentArr.first(where: { $0["type"] as? String == "text" }),
               let description = textObj["text"] as? String {
                completion(description)
            } else {
                print("[AnthropicService] 解析失败或无有效内容")
                completion(nil)
            }
        }
        task.resume()
    }
} 