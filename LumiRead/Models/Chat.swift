import Foundation
import CoreData

// 聊天模型
class Chat: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var createdAt: Date
    @NSManaged public var article: Article?
    @NSManaged public var messages: NSSet?
    
    // 用于预览的示例数据
    static var preview: Chat {
        let context = PersistenceController.preview.container.viewContext
        let chat = Chat(context: context)
        chat.id = UUID()
        chat.createdAt = Date()
        chat.article = Article.preview
        return chat
    }
}

// 扩展用于获取关联的消息
extension Chat {
    var messageArray: [Message] {
        let set = messages as? Set<Message> ?? []
        return set.sorted { $0.timestamp < $1.timestamp }
    }
}