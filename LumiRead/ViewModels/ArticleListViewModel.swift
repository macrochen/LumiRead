import SwiftUI
import CoreData
import GoogleSignIn
import GoogleAPIClientForREST_Drive

class ArticleListViewModel: ObservableObject {
    @Published var selectedArticleIDs: Set<UUID> = []
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isLoading = false
    
    // 选择/取消选择文章
    func toggleArticleSelection(articleID: UUID) {
        if selectedArticleIDs.contains(articleID) {
            selectedArticleIDs.remove(articleID)
        } else {
            selectedArticleIDs.insert(articleID)
        }
    }
    
    // 全选文章
    func selectAllArticles() {
        // 实际实现需要获取所有文章ID
    }
    
    // 选择5篇文章
    func selectFiveArticles() {
        // 实际实现需要获取文章ID并选择5篇
    }
    
    // 打开文章链接
    func openArticleLink(_ link: String) {
        guard let url = URL(string: link) else {
            showAlert(title: "无效链接", message: "无法打开文章链接，URL格式不正确。")
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    // 从Google Drive导入文章
    func importFromGoogleDrive() {
        // 检查是否已登录Google账户
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            // 已登录，开始选择文件
            fetchFilesFromGoogleDrive()
        } else {
            // 未登录，先进行登录
            signInToGoogleDrive()
        }
    }
    
    // 登录Google Drive
    private func signInToGoogleDrive() {
        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            showAlert(title: "错误", message: "无法获取当前视图控制器。")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
            if let error = error {
                self.showAlert(title: "登录失败", message: "无法登录Google账户: \(error.localizedDescription)")
                return
            }
            
            // 登录成功，开始选择文件
            self.fetchFilesFromGoogleDrive()
        }
    }
    
    // 获取Google Drive文件列表
    private func fetchFilesFromGoogleDrive() {
        // 实际实现需要使用GoogleAPIClientForREST_Drive获取文件列表
        // 然后显示文件选择器让用户选择.json文件
    }
    
    // 下载并解析选定的JSON文件
    private func downloadAndParseJSONFile(fileID: String) {
        // 实际实现需要下载文件并解析JSON内容
        // 然后将文章数据保存到CoreData
    }
    
    // 批量总结选中的文章
    func summarizeSelectedArticles(articles: FetchedResults<Article>, context: NSManagedObjectContext) {
        guard !selectedArticleIDs.isEmpty else {
            showAlert(title: "未选择文章", message: "请至少选择一篇文章进行总结。")
            return
        }
        
        isLoading = true
        
        // 获取选中的文章内容
        let selectedArticles = articles.filter { article in
            return selectedArticleIDs.contains(article.id)
        }
        
        // 获取用户设置的API Key和总结提示词
        // 实际实现需要从UserSettings获取
        let apiKey = "YOUR_API_KEY"
        let summaryPrompt = "请针对以下多篇文章内容，为每一篇都生成包含"主要内容"、"核心观点"、"关键细节"和"深度解读"的结构化总结报告。将所有文章的总结合并为一个统一的文本块输出。"
        
        // 准备文章内容
        var articlesContent = ""
        for (index, article) in selectedArticles.enumerated() {
            articlesContent += "[\(index + 1)] \(article.titleString)\n\n\(article.contentString)\n\n"
        }
        
        // 调用AI服务进行总结
        AIService.shared.generateSummary(
            apiKey: apiKey,
            prompt: summaryPrompt,
            content: articlesContent
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let summaryContent):
                    // 创建新的批量总结记录
                    let summary = BatchSummary.createBatchSummary(
                        content: summaryContent,
                        articleIDs: Array(self.selectedArticleIDs),
                        context: context
                    )
                    
                    do {
                        try context.save()
                        // 清除选择
                        self.selectedArticleIDs.removeAll()
                    } catch {
                        self.showAlert(title: "保存失败", message: "无法保存总结内容: \(error.localizedDescription)")
                    }
                    
                case .failure(let error):
                    self.showAlert(title: "总结失败", message: "无法生成文章总结: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 显示警告
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}