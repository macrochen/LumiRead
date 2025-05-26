import Foundation
import CoreData

// 文章模型
class Article: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var link: String
    @NSManaged public var content: String
    @NSManaged public var importDate: Date
    @NSManaged public var chats: NSSet?
    @NSManaged public var summaries: NSSet?
    
    // 用于预览的示例数据
    static var preview: Article {
        let context = PersistenceController.preview.container.viewContext
        let article = Article(context: context)
        article.id = UUID()
        article.title = "优雅的清新主义美学与功能的完美平衡探索"
        article.link = "https://example.com/article1"
        article.content = "这是文章的详细内容..."
        article.importDate = Date()
        return article
    }
}

// 扩展用于获取关联的聊天和总结
extension Article {
    var chatArray: [Chat] {
        let set = chats as? Set<Chat> ?? []
        return set.sorted { $0.createdAt > $1.createdAt }
    }
    
    var summaryArray: [BatchSummary] {
        let set = summaries as? Set<BatchSummary> ?? []
        return set.sorted { $0.createdAt > $1.createdAt }
    }
    
    // 便捷属性和方法
    var titleString: String {
        title ?? "未知标题"
    }
    
    var linkString: String {
        link ?? ""
    }
    
    var contentString: String {
        content ?? ""
    }
    
    var importDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: importDate ?? Date())
    }
    
    // 创建新文章的静态方法
    static func createArticle(title: String, link: String, content: String, context: NSManagedObjectContext) -> Article {
        let article = Article(context: context)
        article.id = UUID()
        article.title = title
        article.link = link
        article.content = content
        article.importDate = Date()
        return article
    }
}