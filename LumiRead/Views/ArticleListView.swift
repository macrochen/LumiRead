import SwiftUI

struct ArticleListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ArticleListViewModel()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Article.importDate, ascending: false)],
        animation: .default)
    private var articles: FetchedResults<Article>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 操作按钮工具栏
                HStack(spacing: 8) {
                    Button(action: viewModel.selectAllArticles) {
                        Text("全部选中")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    
                    Button(action: viewModel.selectFiveArticles) {
                        Text("选中5篇")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        viewModel.summarizeSelectedArticles(articles: articles, context: viewContext)
                        appState.selectedTab = 1 // 切换到内容总结标签页
                    }) {
                        Text("批量总结选中")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(viewModel.selectedArticleIDs.isEmpty)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.5))
                
                // 文章列表
                List {
                    ForEach(articles) { article in
                        ArticleRow(
                            article: article,
                            isSelected: viewModel.selectedArticleIDs.contains(article.id ?? UUID()),
                            onToggleSelection: { viewModel.toggleArticleSelection(articleID: article.id ?? UUID()) },
                            onOpenLink: { viewModel.openArticleLink(article.linkString) },
                            onStartChat: { 
                                appState.startChatWithArticle(article)
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("文章列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.importFromGoogleDrive) {
                        Image(systemName: "arrow.down.doc")
                    }
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
}

struct ArticleRow: View {
    let article: Article
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onOpenLink: () -> Void
    let onStartChat: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(article.titleString)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("导入日期: \(article.importDateString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onOpenLink) {
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onStartChat) {
                Text("对话")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
}