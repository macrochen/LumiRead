import Foundation

class AIService {
    private var apiKey: String = ""
    
    func setApiKey(_ key: String) {
        self.apiKey = key
    }
    
    func generateBatchSummary(articles: [Article], prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        // 构建请求内容
        var articlesText = ""
        for (index, article) in articles.enumerated() {
            articlesText += "\n\n文章\(index + 1): \(article.title)\n\n\(article.content)"
        }
        
        let requestContent = prompt + articlesText
        
        // 创建API请求
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "你是一个专业的文章分析助手，擅长总结和提取文章的核心内容。"],
                ["role": "user", "content": requestContent]
            ],
            "temperature": 0.7
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))) // 移除多余的右括号
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有返回数据"]))) // 移除多余的右括号
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析API响应"]))) // 移除多余的右括号
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func chatWithArticle(article: Article, messages: [Message], selectedPrompts: [PresetPrompt], userInput: String, completion: @escaping (Result<String, Error>) -> Void) {
        // 构建系统提示词
        let systemPrompt = "你是一个专业的文章分析助手，正在分析以下文章：\n\n标题：\(article.title)\n\n内容：\(article.content)\n\n请根据用户的问题，提供准确、有见地的回答。"
        
        // 构建用户提示词
        var userPrompt = userInput
        if !selectedPrompts.isEmpty {
            let promptTexts = selectedPrompts.map { $0.content }
            userPrompt = promptTexts.joined(separator: "\n") + "\n" + userInput
        }
        
        // 构建历史消息
        var apiMessages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        for message in messages {
            let role = message.role == .user ? "user" : "assistant"
            apiMessages.append(["role": role, "content": message.content])
        }
        
        // 添加当前用户消息
        apiMessages.append(["role": "user", "content": userPrompt])
        
        // 创建API请求
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": apiMessages,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))) // 移除多余的右括号
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有返回数据"]))) // 移除多余的右括号
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析API响应"]))) // 移除多余的右括号
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}