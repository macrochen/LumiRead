import Foundation
import CoreData

// 消息类型枚举
enum MessageRole: String, Codable {
    case user
    case assistant
}

// 消息模型
class Message: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var content: String
    @NSManaged public var roleValue: String
    @NSManaged public var timestamp: Date
    @NSManaged public var chat: Chat?
    
    var role: MessageRole {
        get {
            return MessageRole(rawValue: roleValue) ?? .user
        }
        set {
            roleValue = newValue.rawValue
        }
    }
    
    // 用于预览的示例数据
    static var previewUser: Message {
        let context = PersistenceController.preview.container.viewContext
        let message = Message(context: context)
        message.id = UUID()
        message.content = "这篇文章的主要论点是什么？请用一句话概括。"
        message.roleValue = MessageRole.user.rawValue
        message.timestamp = Date()
        return message
    }
    
    static var previewAssistant: Message {
        let context = PersistenceController.preview.container.viewContext
        let message = Message(context: context)
        message.id = UUID()
        message.content = "这篇文章的主要论点是：在产品设计中，清新主义美学不仅仅是视觉上的追求，更是实现功能易用性和提升用户体验的关键途径。"
        message.roleValue = MessageRole.assistant.rawValue
        message.timestamp = Date().addingTimeInterval(10)
        return message
    }
}