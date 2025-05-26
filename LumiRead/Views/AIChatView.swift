import SwiftUI

struct AIChatView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AIChatViewModel()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PresetPrompt.title, ascending: true)],
        animation: .default)
    private var presetPrompts: FetchedResults<PresetPrompt>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let article = appState.currentArticleForChat {
                    // 聊天界面
                    ChatView(
                        article: article,
                        viewModel: viewModel,
                        presetPrompts: presetPrompts
                    )
                } else {
                    // 空状态
                    EmptyChatView()
                }
            }
            .navigationTitle(appState.currentArticleForChat != nil ? "对话: \(appState.currentArticleForChat!.titleString.prefix(20))..." : "AI对话")
            .onAppear {
                if let article = appState.currentArticleForChat {
                    viewModel.loadChatHistory(for: article)
                }
            }
        }
    }
}

struct ChatView: View {
    let article: Article
    @ObservedObject var viewModel: AIChatViewModel
    let presetPrompts: FetchedResults<PresetPrompt>
    
    @State private var userInput = ""
    @State private var selectedPromptIDs: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 聊天消息列表
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty {
                        // 初始欢迎消息
                        AIMessageBubble(message: "你好！关于"\(article.titleString)"这篇文章，你有什么具体