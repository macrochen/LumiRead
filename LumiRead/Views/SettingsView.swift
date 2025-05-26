import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = SettingsViewModel()

    // For Add/Edit Preset Prompt Sheet
    @State private var showingAddEditPromptSheet = false
    @State private var editingPrompt: PresetPrompt? = nil
    @State private var promptTitleInput: String = ""
    @State private var promptContentInput: String = ""

    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Google Drive Section
                Section(header: Text("Google Drive 账户")) {
                    Text("当前账户: \(viewModel.googleDriveUserEmail ?? "未连接")")

                    Button(viewModel.isGoogleDriveConnected ? "切换账户" : "连接账户") {
                        viewModel.connectGoogleDrive()
                    }

                    if viewModel.isGoogleDriveConnected {
                        Button("断开连接") {
                            viewModel.disconnectGoogleDrive()
                        }
                        .foregroundColor(.red)
                    }
                }

                // MARK: - AI Service Configuration Section
                Section(header: Text("AI 服务配置")) {
                    Text("API Key")
                    SecureField("输入您的 API Key", text: $viewModel.apiKey)
                        .textContentType(.oneTimeCode) // Helps with password manager suggestions
                    Button("保存API Key") {
                        viewModel.saveApiKey()
                    }

                    Text("批量总结提示词")
                    TextEditor(text: $viewModel.batchSummaryPrompt)
                        .frame(minHeight: 100, maxHeight: 250)
                        .overlay( RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.2)) )


                    HStack {
                        Button("保存提示词") {
                            viewModel.saveBatchSummaryPrompt()
                        }
                        Spacer()
                        Button("恢复默认") {
                            viewModel.restoreDefaultBatchSummaryPrompt()
                        }
                    }
                }

                // MARK: - AI Dialogue Preset Prompts Section
                Section(header: Text("AI 对话预设提示词")) {
                    if viewModel.presetPrompts.isEmpty {
                        Text("没有预设提示词。点击下方按钮添加。")
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                    } else {
                        List {
                            ForEach(viewModel.presetPrompts) { prompt in
                                VStack(alignment: .leading) {
                                    Text(prompt.title ?? "无标题").font(.headline)
                                    Text(prompt.prompt ?? "无内容") // 'prompt' attribute holds the content
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                    HStack {
                                        Spacer()
                                        Button("编辑") {
                                            editingPrompt = prompt
                                            promptTitleInput = prompt.title ?? ""
                                            promptContentInput = prompt.prompt ?? ""
                                            showingAddEditPromptSheet = true
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                            }
                            .onDelete(perform: viewModel.deletePresetPrompt)
                        }
                    }
                    
                    Button("添加新提示词") {
                        editingPrompt = nil
                        promptTitleInput = ""
                        promptContentInput = ""
                        showingAddEditPromptSheet = true
                    }
                }
            }
            .navigationTitle("系统设置")
            .onAppear {
                viewModel.setup(context: viewContext)
            }
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(title: Text(viewModel.alertTitle), message: Text(viewModel.alertMessage), dismissButton: .default(Text("好的")))
            }
            .sheet(isPresented: $showingAddEditPromptSheet) {
                NavigationView {
                    Form {
                        Section(header: Text(editingPrompt == nil ? "添加新提示词" : "编辑提示词")) {
                            TextField("标题", text: $promptTitleInput)
                            
                            Text("提示内容") // Label for TextEditor
                            TextEditor(text: $promptContentInput)
                                .frame(minHeight: 150, maxHeight: 300)
                                .overlay( RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.2)) )
                        }
                    }
                    .navigationTitle(editingPrompt == nil ? "添加提示词" : "编辑提示词")
                    .navigationBarItems(
                        leading: Button("取消") {
                            showingAddEditPromptSheet = false
                        },
                        trailing: Button("保存") {
                            if let prompt = editingPrompt {
                                viewModel.updatePresetPrompt(prompt: prompt, newTitle: promptTitleInput, newContent: promptContentInput)
                            } else {
                                viewModel.addPresetPrompt(title: promptTitleInput, content: promptContentInput)
                            }
                            showingAddEditPromptSheet = false
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
