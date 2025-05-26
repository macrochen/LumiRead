import SwiftUI
import CoreData

// Enum for Tab Items
enum TabItem: CaseIterable { // Added CaseIterable
    case articleList
    case contentSummary
    case aiChat
    case settings

    var title: String {
        switch self {
        case .articleList:
            return "文章列表"
        case .contentSummary:
            return "内容总结"
        case .aiChat:
            return "AI对话"
        case .settings:
            return "系统设置"
        }
    }

    var iconName: String {
        switch self {
        case .articleList:
            return "list.bullet.rectangle"
        case .contentSummary:
            return "doc.text"
        case .aiChat:
            return "bubble.left.and.bubble.right"
        case .settings:
            return "gearshape"
        }
    }
}

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext // Added CoreData context
    @State private var selectedTab: TabItem = .articleList
    @State private var activeChat: Chat? // Kept as Chat? = nil is implicit

    var body: some View {
        TabView(selection: $selectedTab) {
            ArticleListView(onStartChat: { article in
                // Logic to create or get chat and switch tab
                if let chat = createOrGetChat(for: article) { // Conditional assignment
                    self.activeChat = chat
                    self.selectedTab = .aiChat
                }
            })
            .tabItem {
                Label(TabItem.articleList.title, systemImage: TabItem.articleList.iconName)
            }
            .tag(TabItem.articleList)

            ContentSummaryView(onStartChat: { article in
                // Logic to create or get chat and switch tab
                if let chat = createOrGetChat(for: article) { // Conditional assignment
                    self.activeChat = chat
                    self.selectedTab = .aiChat
                }
            })
            .tabItem {
                Label(TabItem.contentSummary.title, systemImage: TabItem.contentSummary.iconName)
            }
            .tag(TabItem.contentSummary)

            AIChatView(activeChat: $activeChat)
                .tabItem {
                    Label(TabItem.aiChat.title, systemImage: TabItem.aiChat.iconName)
                }
                .tag(TabItem.aiChat)

            SettingsView() // Replaced placeholder with actual SettingsView
                .tabItem {
                    Label(TabItem.settings.title, systemImage: TabItem.settings.iconName)
                }
                .tag(TabItem.settings)
        }
    }

    // Helper function to create or get a chat for an article
    private func createOrGetChat(for article: Article) -> Chat? { // Return type Chat?
        let fetchRequest: NSFetchRequest<Chat> = Chat.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "article == %@", article)
        // Optional: Add sort descriptors if needed.
        // fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Chat.createdAt, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let existingChats = try viewContext.fetch(fetchRequest) // Use environment viewContext
            if let chat = existingChats.first {
                return chat
            } else {
                // Create new chat if none exists
                let newChat = Chat(context: viewContext)
                newChat.article = article
                // IMPORTANT: Set non-optional attributes.
                // Assuming Chat entity has 'id' (UUID) and 'createdAt' (Date) as non-optional.
                newChat.id = UUID()
                newChat.createdAt = Date()
                
                try viewContext.save()
                return newChat
            }
        } catch {
            // Log the error for debugging purposes
            print("Error fetching or creating chat: \(error.localizedDescription)")
            return nil // Return nil on error
        }
    }
}

// Preview (Optional, but good for development)
#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif