import SwiftUI
import CoreData

class AIChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    
    func loadChatHistory(for article: Article, context: NSManagedObjectContext) {
        // TODO: 从 CoreData 加载与文章相关的聊天历史
        messages = []
    }
}