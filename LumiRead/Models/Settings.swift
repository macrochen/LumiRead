import Foundation
import CoreData

// 设置模型
class Settings: NSManagedObject {
    @NSManaged public var apiKey: String?
    @NSManaged public var batchSummaryPrompt: String?
    @NSManaged public var googleDriveEmail: String?
    
    // 用于预览的示例数据
    static var preview: Settings {
        let context = PersistenceController.preview.container.viewContext
        let settings = Settings(context: context)
        settings.apiKey = "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        settings.batchSummaryPrompt = "请针对以下多篇文章内容，为每一篇都生成包含"主要内容"、"核心观点"、"关键细节"和"深度解读"的结构化总结报告。将所有文章的总结合并为一个统一的文本块输出。"
        settings.googleDriveEmail = "developer@example.com"
        return settings
    }
    
    // 获取当前设置或创建新设置
    static func getCurrentSettings(context: NSManagedObjectContext) -> Settings {
        let fetchRequest: NSFetchRequest<Settings> = Settings.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let settings = results.first {
                return settings
            } else {
                let settings = Settings(context: context)
                settings.batchSummaryPrompt = "请针对以下多篇文章内容，为每一篇都生成包含"主要内容"、"核心观点"、"关键细节"和"深度解读"的结构化总结报告。将所有文章的总结合并为一个统一的文本块输出。"
                try context.save()
                return settings
            }
        } catch {
            print("获取设置失败: \(error)")
            let settings = Settings(context: context)
            settings.batchSummaryPrompt = "请针对以下多篇文章内容，为每一篇都生成包含"主要内容"、"核心观点"、"关键细节"和"深度解读"的结构化总结报告。将所有文章的总结合并为一个统一的文本块输出。"
            return settings
        }
    }
}