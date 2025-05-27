import Foundation
import CoreData

// 批量总结模型
class BatchSummary: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var content: String
    @NSManaged public var createdAt: Date
    @NSManaged public var articles: NSSet?
    
    // 用于预览的示例数据
    static var preview: BatchSummary {
        let context = PersistenceController.preview.container.viewContext
        let summary = BatchSummary(context: context)
        summary.id = UUID()
        summary.content = "这是一个批量总结的内容..."
        summary.createdAt = Date()
        return summary
    }
}

// 扩展用于获取关联的文章
extension BatchSummary {
    var contentString: String {
        content ?? ""
    }
    
    var creationDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: creationDate ?? Date())
    }
    
    var articleCountString: String {
        "针对\(articleIDs?.count ?? 0)篇文章的批量总结"
    }
    
    // 创建新的批量总结的静态方法
    static func createBatchSummary(content: String, articleIDs: [UUID], context: NSManagedObjectContext) -> BatchSummary {
        let summary = BatchSummary(context: context)
        summary.id = UUID()
        summary.content = content
        summary.creationDate = Date()
        summary.articleIDs = articleIDs
        return summary
    }
    
    var articleArray: [Article] {
        let set = articles as? Set<Article> ?? []
        return set.sorted { $0.importDate > $1.importDate }
    }
}