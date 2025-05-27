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
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
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
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingViewController = windowScene.windows.first?.rootViewController else {
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
        let settings = Settings.getCurrentSettings(context: viewContext)
        _ = settings.apiKey ?? ""  // 使用 _ 替代未使用的变量
        let summaryPrompt = settings.batchSummaryPrompt ?? DEFAULT_SUMMARY_PROMPT
        
        // 准备文章内容
        var articlesContent = ""
        for (index, article) in selectedArticles.enumerated() {
            articlesContent += "[\(index + 1)] \(article.titleString)\n\n\(article.contentString)\n\n"
        }
        
        // 调用AI服务进行总结
        AIService.shared.generateBatchSummary(
            articles: Array(selectedArticles),
            prompt: summaryPrompt
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let summaryContent):
                    _ = BatchSummary.createBatchSummary(  // 使用 _ 替代未使用的变量
                        content: summaryContent,
                        articleIDs: Array(self.selectedArticleIDs),
                        context: self.viewContext
                    )
                    
                    do {
                        try self.viewContext.save()
                        self.selectedArticleIDs.removeAll()
                    } catch {
                        self.showAlert(title: "保存失败", message: "无法保存总结内容: \(error.localizedDescription)")
                    }
                    
                case .failure(let error):
                    self.showAlert(title: "总结失败", message: "无法生成总结: \(error.localizedDescription)")
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
    
    // 获取Google Drive文件列表
    private func fetchFilesFromGoogleDrive() {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            showAlert(title: "错误", message: "未登录Google账户。")
            return
        }
        
        let driveService = GTLRDriveService()
        driveService.authorizer = user.fetcherAuthorizer
        
        let query = GTLRDriveQuery_FilesList.query()
        query.fields = "files(id, name, mimeType)"
        query.q = "mimeType='application/json'"
        
        driveService.executeQuery(query) { [weak self] (_, result, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "错误", message: "无法获取文件列表：\(error.localizedDescription)")
                    return
                }
                
                guard let fileList = result as? GTLRDrive_FileList,
                      let _ = fileList.files else {  // 将 files 替换为 _
                    self.showAlert(title: "错误", message: "无法解析文件列表。")
                    return
                }
                
                // 处理文件列表，例如显示文件选择器
                // TODO: 实现文件选择器UI
            }
        }
    }
    
    
}