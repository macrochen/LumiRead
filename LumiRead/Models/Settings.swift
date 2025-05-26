import Foundation
import CoreData

// 定义默认的批处理总结提示词
let DEFAULT_SUMMARY_PROMPT = """
        # 任务目标
        你需要扮演一个信息处理和总结助手。请根据我提供的JSON格式的文档，对每篇文章进行处理。

        # 输入格式
        我的文档结构是 JSON 格式，每篇文章是一个 JSON 对象，包含 `title` (文章标题)、`url` (文章链接) 和 `content` (文章主要内容) 这三个字段。你需要按顺序处理JSON中的每篇文章。

        # 主要任务：文章总结与处理

        请用简体中文大白话总结给定的内容。对于需要总结的文章（非软文、非内容无法总结的情况），你的总结应包含以下结构化信息，并确保整体风格口语化、忠于原文：

        1.  **主要内容**：简明扼要地概括文章主要讲述的是什么事情、哪个领域或哪个主题。
        2.  **核心观点**：清晰提炼文章最核心的论点、看法或结论，让人一眼看懂文章主要想表达什么。
        3.  **关键细节**：列出支撑核心观点的关键信息点，如重要数据、人物观点、事件要素、具体案例的核心内容等。如果有多条，请分点列出。
        4.  **深度解读**：基于原文信息，尝试点出观点背后的逻辑、潜在的假设、可能的引申、与其他信息的联系或对事物更深层次的理解。避免主观臆断和过度引申。

        **其他要求：**

        5.  **总结风格**：整体总结要像跟朋友聊天一样，自然口语化，避免生硬的书面语。
        6.  **忠于原文**：所有部分的总结都必须严格忠于原文内容，不允许虚构或歪曲。
        7.  **类型适配**：针对不同类型的文章（比如财经、健康、生活），在“核心观点”、“关键细节”和“深度解读”时，侧重点可以稍微调整（财经侧重数据趋势，健康侧重科学建议等），但都得保证通俗易懂和上述结构。
        8.  **问句标题处理**：如果文章标题是疑问句（例如“未来十年，中国零售渠道会有哪些变化？”），请在“核心观点”部分直接、清晰地回答这个问题，并结合“主要内容”、“关键细节”和“深度解读”进行支撑。
        9.  **软文识别与处理**：如果识别出文章主要目的是推广产品、课程或服务（即软文），请使用以下固定格式进行标注：`[软文识别] 此内容可能为推广信息，核心价值较低。` 无需进行结构化总结。
        10. **内容无法总结处理**：如果文章 `` 字段为空、内容完全是乱码、或因内容过短/信息量过低而无法进行有意义的总结，请进行标注，例如：`[内容无法总结] 原文内容不足或无法有效解析。` 无需进行结构化总结。
        11. **编号**：为每篇文章分配一个从1开始的顺序编号，方便后续提问。

        # 输出格式示例

        对于普通文章：

        [1] 《文章标题示例》

        **主要内容**：[这里概括文章主要讲述的对象和范围]

        **核心观点**：[这里提炼文章最核心的论点或看法；若是问句标题，则在此处回答]

        **关键细节**：
        - [关键细节1，例如：具体数据、案例要素]
        - [关键细节2，例如：重要人物的观点]
        - （更多细节，视文章内容而定）

        **深度解读**：[这里提供基于原文的深层分析、联系或引申]


        对于软文：

        [2] 《另一篇文章标题》
        [软文识别] 此内容可能为推广信息，核心价值较低。


        对于内容无法总结的文章：

        [3] 《内容无法总结的文章标题》
        [内容无法总结] 原文内容不足或无法有效解析。
        """

// 设置模型
class Settings: NSManagedObject {
    @NSManaged public var apiKey: String?
    @NSManaged public var batchSummaryPrompt: String?
    @NSManaged public var googleDriveEmail: String?
    
    // 用于预览的示例数据
    static var preview: Settings {
        let context = PersistenceController.preview.container.viewContext
        let settings = Settings(context: context)
        settings.apiKey = "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        settings.batchSummaryPrompt = DEFAULT_SUMMARY_PROMPT
        settings.googleDriveEmail = "developer@example.com"
        return settings
    }
    
    // 获取当前设置或创建新设置
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Settings> {
        return NSFetchRequest<Settings>(entityName: "Settings")
    }
    static func getCurrentSettings(context: NSManagedObjectContext) -> Settings {
        let fetchRequest: NSFetchRequest<Settings> = Settings.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let settings = results.first {
                return settings
            } else {
                let settings = Settings(context: context)
                settings.batchSummaryPrompt = DEFAULT_SUMMARY_PROMPT
                try context.save()
                return settings
            }
        } catch {
            print("获取设置失败: \(error)")
            let settings = Settings(context: context)
            settings.batchSummaryPrompt = DEFAULT_SUMMARY_PROMPT
            return settings
        }
    }
}
