import Foundation
import CoreData

// 预设提示词模型
class PresetPrompt: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var content: String
    @NSManaged public var title: String
    @NSManaged public var order: Int16
    @NSManaged public var createdAt: Date
    
    // 用于预览的示例数据
    static var preview: PresetPrompt {
        let context = PersistenceController.preview.container.viewContext
        let prompt = PresetPrompt(context: context)
        prompt.id = UUID()
        prompt.title = "全文总结"
        prompt.content = "请对这篇文章进行全面总结，包括主要内容、核心观点和关键细节。"
        prompt.order = 0
        return prompt
    }
}

extension PresetPrompt {
    var titleString: String {
        title ?? ""
    }
    
    var contentString: String {
        content ?? ""
    }
    
    // 创建新的预设提示词的静态方法
    static func createPresetPrompt(title: String, content: String, context: NSManagedObjectContext) -> PresetPrompt {
        let prompt = PresetPrompt(context: context)
        prompt.id = UUID()
        prompt.title = title
        prompt.content = content
        return prompt
    }
}
