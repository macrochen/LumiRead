import SwiftUI

struct ContentSummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BatchSummary.creationDate, ascending: false)],
        animation: .default)
    private var summaries: FetchedResults<BatchSummary>
    
    var body: some View {
        NavigationView {
            Group {
                if summaries.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let latestSummary = summaries.first {
                                Text(latestSummary.articleCountString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                SummaryContentView(summary: latestSummary, appState: appState)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("内容总结")
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("暂无内容总结")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("请先到文章列表选择文章进行批量总结。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

struct SummaryContentView: View {
    let summary: BatchSummary
    let appState: AppState
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var articles: FetchedResults<Article>
    
    init(summary: BatchSummary, appState: AppState) {
        self.summary = summary
        self.appState = appState
        
        // 创建获取与此总结相关的文章的请求
        let articleIDs = summary.articleIDs as? [UUID] ?? []
        let predicate = NSPredicate(format: "id IN %@", articleIDs)
        
        _articles = FetchRequest<Article>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Article.title, ascending: true)],
            predicate: predicate
        )
    }
    
    var body: some View {
        // 解析总结内容，提取每篇文章的部分
        // 这里简化处理，实际实现可能需要更复杂的解析逻辑
        let summaryContent = summary.contentString
        
        VStack(alignment: .leading, spacing: 16) {
            ForEach(articles) { article in
                SummaryCard(
                    article: article,
                    summaryContent: summaryContent,
                    onOpenLink: {
                        if let url = URL(string: article.linkString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    onStartChat: {
                        appState.startChatWithArticle(article)
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

struct SummaryCard: View {
    let article: Article
    let summaryContent: String
    let onOpenLink: () -> Void
    let onStartChat: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onOpenLink) {
                    Text(article.titleString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .lineLimit(2)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: onStartChat) {
                    Text("对话")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.pink]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 这里简化处理，实际实现需要根据文章标题或ID从总结内容中提取对应部分
            VStack(alignment: .leading, spacing: 8) {
                SummarySection(title: "主要内容:", content: "本文深入探讨了相关主题...")
                SummarySection(title: "核心观点:", content: "作者认为...")
                SummarySection(title: "关键细节:", content: "1. 重要细节一\n2. 重要细节二\n3. 重要细节三")
                SummarySection(title: "深度解读:", content: "从更广泛的角度来看...")
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SummarySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}