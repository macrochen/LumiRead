import SwiftUI

enum TabItem {
    case articleList
    case contentSummary
    case aiChat
    case settings
    
    var title: String {
        switch self {
        case .articleList: return "文章列表"
        case .contentSummary: return "内容总结"
        case .aiChat: return "AI对话"
        case .settings: return "系统设置"
        }
    }
    
    var iconName: String {
        switch self {
        case .articleList: return "list.bullet.rectangle"
        case .contentSummary: return "doc.text"
        case .aiChat: return "bubble.left.and.bubble.right"
        case .settings: return "gearshape"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: TabItem = .articleList
    @State private var activeChat: Chat? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ArticleListView(onStartChat: { article in
                // 创建新的聊天或获取现有聊天
                let chat = createOrGetChat(for: article)
                self.activeChat = chat
                self.selectedTab = .aiChat
            })
            .tabItem {
                Label(TabItem.articleList.title, systemImage: TabItem.articleList.iconName)
            }
            .tag(TabItem.articleList)
            
            ContentSummaryView(onStartChat: { article in
                // 创建新的聊天或获取现有聊天
                let chat = createOrGetChat(for: article)
                self.activeChat = chat
                self.selectedTab = .aiChat
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
            
            SettingsView()
            .tabItem {
                Label(TabItem.settings.title, systemImage: TabItem.settings.iconName)
            }
            .tag(TabItem.settings)
        }
    }
    
    private func createOrGetChat(for article: Article) -> Chat {
        let context = PersistenceController.shared.container.viewContext
        
        // 检查是否已有该文章的聊天
        let fetchRequest: NSFetchRequest<Chat> = Chat.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "article == %@", article)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let existingChat = results.first {
                return existingChat
            }
        } catch {
            print("获