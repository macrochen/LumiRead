//
//  LumiReadApp.swift
//  LumiRead
//
//  Created by jolin on 2025/5/26.
//

import SwiftUI
import GoogleSignIn

@main
struct LumiReadApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
                .onOpenURL { url in
                    // 处理Google Drive认证回调
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

// 全局应用状态
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var currentArticleForChat: Article?
    @Published var isGoogleDriveConnected: Bool = false
    @Published var googleDriveUserEmail: String?
    
    // 当用户从文章列表或内容总结页选择一篇文章进行对话时调用
    func startChatWithArticle(_ article: Article) {
        currentArticleForChat = article
        selectedTab = 2 // 切换到AI对话标签页
    }
}
