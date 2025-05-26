import Foundation
import CoreData

struct ArticleData: Codable {
    let title: String
    let link: String
    let content: String
}

class ArticleImportService {
    func importArticlesFromJSON(data: Data, context: NSManagedObjectContext, completion: @escaping (Result<[Article], Error>) -> Void) {
        do {
            let decoder = JSONDecoder()
            let articleDataArray = try decoder.decode([ArticleData].self, from: data)
            
            var importedArticles: [Article] = []
            
            for articleData in articleDataArray {
                let article = Article(context: context)
                article.id = UUID()
                article.title = articleData.title
                article.link = articleData.link
                article.content = articleData.content
                article.importDate = Date()
                
                importedArticles.append(article)
            }
            
            try context.save()
            completion(.success(importedArticles))
            
        } catch {
            completion(.failure(error))
        }
    }
}