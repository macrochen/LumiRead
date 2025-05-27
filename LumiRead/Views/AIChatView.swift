import SwiftUI
import CoreData

// --- Start Placeholder Models (Assume these are defined elsewhere globally) ---
struct Message: Identifiable, Equatable {
    let id: UUID
    var content: String
    let role: MessageRole
    let createdAt: Date
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}
// --- End Placeholder Models ---

struct AIChatView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AIChatViewModel()
    @Binding var activeChat: Chat?

    let article: Article

    @State private var userInput: String = ""
    @State private var showPresetPrompts: Bool = true
    @State private var selectedPromptIDs: Set<UUID> = []

    @FetchRequest(entity: PresetPrompt.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \PresetPrompt.createdAt, ascending: true)])
    private var presetPrompts: FetchedResults<PresetPrompt>

    init(article: Article, activeChat: Binding<Chat?>) {
        self.article = article
        self._activeChat = activeChat
    }

    private var isSendButtonDisabled: Bool {
        viewModel.isLoading ||
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
                                if message.role == MessageRole.user.rawValue {
                                    UserMessageBubble(message: message)
                                } else if message.role == MessageRole.assistant.rawValue {
                                    AIMessageBubble(message: message)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .onChange(of: viewModel.messages.count) { _ in // Updated onChange syntax
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
                                    Text(prompt.title ?? "Prompt") // Changed prompt.prompt to prompt.title
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
        .onChange(of: activeChat) { newChat in // Updated onChange syntax
            if let chat = newChat {
                viewModel.loadChatHistory(for: chat)
            } else {
                viewModel.messages = [] // Clear messages if no active chat
            }
        }
    }

    private func sendMessageAction() {
        guard !isSendButtonDisabled else { return }

        viewModel.sendMessage(
            article: article,
            userInput: userInput,
            selectedPromptIDs: Array(selectedPromptIDs),
            viewContext: viewContext  // 修改参数名为 viewContext
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
        // 修改 mockArticle 的创建
        mockArticle.createdAt = Date()  // 使用新添加的属性
        mockArticle.summary = "这是文章的摘要..."
        
        // 修改 prompt1 和 prompt2 的创建
        prompt1.prompt = "请总结一下这篇文章的主要观点。"  // 使用 prompt 而不是 content
        prompt1.createdAt = Date()
        
        prompt2.prompt = "这篇文章的主要论点是什么？"  // 使用 prompt 而不是 content
        prompt2.createdAt = Date()
        
        return Group {
            NavigationView { // Embed in NavigationView for preview
                AIChatView(article: mockArticle, activeChat: .constant(nil))
            }
            .environmentObject(appState)
            .environment(\.managedObjectContext, viewContext)
            .previewDisplayName("AIChatView (No Article)")
            
            NavigationView { // Embed in NavigationView for preview
                AIChatView(article: mockArticle, activeChat: .constant(nil))
                    .onAppear {
                        // Add some mock messages for preview if needed
                        let msg1 = Message(context: viewContext)
                        msg1.id = UUID()
                        msg1.content = "用户：你好，能帮我分析一下这篇文章吗？"
                        msg1.role = MessageRole.user.rawValue
                        msg1.createdAt = Date()

                        let msg2 = Message(context: viewContext)
                        msg2.id = UUID()
                        msg2.content = "AI：当然，这篇文章主要讨论了..."
                        msg2.role = MessageRole.assistant.rawValue
                        msg2.createdAt = Date()
                        
                        // In a real scenario, you'd add these to a chat object and load via viewModel.loadChatHistory
                        // For preview, we might directly manipulate viewModel.messages if it's a @StateObject
                        // However, for a proper preview, it's better to simulate the data flow.
                    }
            }
            .environmentObject(appState)
            .environment(\.managedObjectContext, viewContext)
            .previewDisplayName("AIChatView (With Article)")
        }
    }
}
#endif