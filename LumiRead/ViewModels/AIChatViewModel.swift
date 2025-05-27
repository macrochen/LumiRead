import SwiftUI
import CoreData

class AIChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    
    func loadChatHistory(for article: Article, context: NSManagedObjectContext) {
        // TODO: 从 CoreData 加载与文章相关的聊天历史
        messages = []
    }
    
    func sendMessage(
        article: Article,
        userInput: String,
        selectedPromptIDs: [UUID],
        viewContext: NSManagedObjectContext
    ) {
        isLoading = true
        // Create user message
        let userMessage = Message(context: viewContext)
        userMessage.id = UUID()
        userMessage.content = userInput
        userMessage.role = MessageRole.user.rawValue
        userMessage.createdAt = Date()
        messages.append(userMessage)

        // Fetch selected prompts
        var prompts: [PresetPrompt] = []
        if !selectedPromptIDs.isEmpty {
            let fetchRequest: NSFetchRequest<PresetPrompt> = PresetPrompt.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", selectedPromptIDs)
            do {
                prompts = try viewContext.fetch(fetchRequest)
            } catch {
                print("Error fetching preset prompts: \(error)")
            }
        }

        // Call AI service
        AIService.shared.chatWithArticle(
            article: article,
            userMessage: userInput,
            selectedPrompts: prompts,
            context: viewContext
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let aiMessage):
                    let assistantMessage = Message(context: viewContext)
                    assistantMessage.id = UUID()
                    assistantMessage.content = aiMessage
                    assistantMessage.role = MessageRole.assistant.rawValue
                    assistantMessage.createdAt = Date()
                    self?.messages.append(assistantMessage)
                    do {
                        try viewContext.save()
                    } catch {
                        print("Error saving message: \(error)")
                    }
                case .failure(let error):
                    print("Error chatting with AI: \(error)")
                    // Optionally add an error message to the chat
                    let errorMessage = Message(context: viewContext)
                    errorMessage.id = UUID()
                    errorMessage.content = "Error: \(error.localizedDescription)"
                    errorMessage.role = MessageRole.assistant.rawValue // Or a new error role
                    errorMessage.createdAt = Date()
                    self?.messages.append(errorMessage)
                }
            }
        }
    }
}