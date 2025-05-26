import SwiftUI
import CoreData


// --- Start Placeholder Models (Assume these are defined elsewhere globally) ---
// struct Message: Identifiable, Equatable {
//     let id: UUID
//     var content: String
//     let role: MessageRole
//     let createdAt: Date
// }

// enum MessageRole: String, Codable {
//     case user
//     case assistant
//     case system
// }
// --- End Placeholder Models ---

struct AIChatView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AIChatViewModel()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PresetPrompt.createdAt, ascending: true)],
        animation: .default)
    private var presetPrompts: FetchedResults<PresetPrompt>

    var body: some View {
        VStack(spacing: 0) {
            if let article = appState.currentArticleForChat {
                ChatView(
                    article: article,
                    viewModel: viewModel,
                    presetPrompts: presetPrompts
                )
            } else {
                EmptyChatView()
            }
        }
        .navigationTitle(appState.currentArticleForChat != nil ? "对话: \(appState.currentArticleForChat!.titleString.prefix(15))..." : "AI对话")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let article = appState.currentArticleForChat {
                viewModel.loadChatHistory(for: article, context: viewContext)
            }
        }
        .onChange(of: appState.currentArticleForChat) { newArticle in
            if let article = newArticle {
                viewModel.loadChatHistory(for: article, context: viewContext)
            } else {
                viewModel.messages = [] 
            }
        }
    }
}

struct EmptyChatView: View {
    var body: some View {
        VStack {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
                .padding(.bottom)
            Text("请从文章列表选择一篇文章开始对话。")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct UserMessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            Spacer() 
            Text(message.content)
                .padding(10)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .padding(.horizontal)
    }
}

struct AIMessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            Text(message.content)
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground)) 
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            Spacer() 
        }
        .padding(.horizontal)
    }
}

struct ChatView: View {
    let article: Article
    @ObservedObject var viewModel: AIChatViewModel
    let presetPrompts: FetchedResults<PresetPrompt>
    @Environment(\.managedObjectContext) private var viewContext

    @State private var userInput: String = ""
    @State private var selectedPromptIDs: Set<UUID> = []
    @State private var showPresetPrompts = true

    private var isSendButtonDisabled: Bool {
        userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedPromptIDs.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if viewModel.messages.isEmpty {
                            AIMessageBubble(message: Message(id: UUID(), content: "你好！关于“\(article.titleString)”这篇文章，你有什么具体问题吗？或者可以点击下方推荐的预设问题。", role: .assistant, createdAt: Date()))
                                .padding(.top)
                        } else {
                            ForEach(viewModel.messages) { message in
                                if message.role == .user {
                                    UserMessageBubble(message: message)
                                } else {
                                    AIMessageBubble(message: message)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessageID = viewModel.messages.last?.id {
                            withAnimation {
                                scrollViewProxy.scrollTo(lastMessageID, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear { 
                         if let lastMessageID = viewModel.messages.last?.id {
                            scrollViewProxy.scrollTo(lastMessageID, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))

            Divider()

            if showPresetPrompts && !presetPrompts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("推荐问题:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presetPrompts) { prompt in
                                Button(action: {
                                    if let id = prompt.id { 
                                        if selectedPromptIDs.contains(id) {
                                            selectedPromptIDs.remove(id)
                                        } else {
                                            selectedPromptIDs.insert(id)
                                        }
                                    }
                                }) {
                                    Text(prompt.title ?? "Prompt")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(selectedPromptIDs.contains(prompt.id ?? UUID()) ? Color.blue.opacity(0.2) : Color(UIColor.secondarySystemFill))
                                        .foregroundColor(selectedPromptIDs.contains(prompt.id ?? UUID()) ? .blue : .primary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(selectedPromptIDs.contains(prompt.id ?? UUID()) ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                    }
                }
                .padding(.top, 8)
                .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.bottom)) 
                Divider()
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                TextEditor(text: $userInput)
                    .frame(minHeight: 30, maxHeight: 120) 
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: sendMessageAction) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(isSendButtonDisabled ? .gray : .blue)
                }
                .disabled(isSendButtonDisabled)
            }
            .padding(.horizontal)
            .padding(.vertical, 8) 
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    private func sendMessageAction() {
        guard !isSendButtonDisabled else { return }

        viewModel.sendMessage(
            article: article,
            userInput: userInput,
            selectedPromptIDs: selectedPromptIDs,
            context: viewContext
        )
        userInput = ""
        selectedPromptIDs = []
    }
}

#if DEBUG
struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        let persistenceController = PersistenceController.preview
        let viewContext = persistenceController.container.viewContext

        let mockArticle = Article(context: viewContext)
        mockArticle.id = UUID()
        mockArticle.title = "这是一个测试文章标题用于预览"
        mockArticle.content = "这是文章的内容..."
        mockArticle.createdAt = Date()
        mockArticle.summary = "这是文章的摘要..."
        
        let prompt1 = PresetPrompt(context: viewContext)
        prompt1.id = UUID()
        prompt1.title = "总结这篇文章"
        prompt1.prompt = "请总结一下这篇文章的主要观点。"
        prompt1.createdAt = Date()
        
        let prompt2 = PresetPrompt(context: viewContext)
        prompt2.id = UUID()
        prompt2.title = "主要论点是什么？"
        prompt2.prompt = "这篇文章的主要论点是什么？"
        prompt2.createdAt = Date()
        
        return Group {
            NavigationView { // Embed in NavigationView for preview
                AIChatView()
            }
            .environmentObject(appState)
            .environment(\.managedObjectContext, viewContext)
            .previewDisplayName("AIChatView (No Article)")
            
            NavigationView { // Embed in NavigationView for preview
                AIChatView()
                    .onAppear {
                        appState.currentArticleForChat = mockArticle
                    }
            }
            .environmentObject(appState)
            .environment(\.managedObjectContext, viewContext)
            .previewDisplayName("AIChatView (With Article)")
        }
    }
}
#endif
