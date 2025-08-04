//
//  VoiceAssistantService.swift
//  yolo11
//
//  Created by tim on 2025/8/4.
//

import Foundation
import Combine

/// 语音助手服务 - 处理语音对话和YOLO检测结果的智能交互
class VoiceAssistantService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var lastQuestion = ""
    @Published var lastResponse = ""
    @Published var conversationHistory: [ConversationItem] = []
    
    // MARK: - Services
    private let speechRecognition = SpeechRecognitionService()
    private let textToSpeech = TextToSpeechService()
    
    // MARK: - Current Detection Data
    private var currentDetections: [DetectionResult] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// 更新当前检测结果
    /// - Parameter detections: 最新的检测结果
    func updateDetections(_ detections: [DetectionResult]) {
        currentDetections = detections
    }
    
    /// 开始语音对话
    func startListening() {
        guard !isListening else { return }
        
        speechRecognition.clearText()
        speechRecognition.startRecording()
        isListening = true
        
        print("🎙️ 开始语音对话...")
    }
    
    /// 停止语音对话
    func stopListening() {
        guard isListening else { return }
        
        speechRecognition.stopRecording()
        isListening = false
        
        // 处理识别到的文本
        let recognizedText = speechRecognition.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !recognizedText.isEmpty {
            processVoiceInput(recognizedText)
        }
        
        print("🛑 停止语音对话")
    }
    
    /// 手动输入文本问题
    /// - Parameter text: 用户输入的文本
    func askQuestion(_ text: String) {
        processVoiceInput(text)
    }
    
    /// 播报当前检测结果
    func announceCurrentDetections() {
        let detectionLabels = currentDetections.map { $0.label }
        textToSpeech.announceDetections(detectionLabels)
    }
    
    /// 清除对话历史
    func clearHistory() {
        conversationHistory.removeAll()
        lastQuestion = ""
        lastResponse = ""
    }
    
    // MARK: - Private Methods
    
    /// 设置绑定
    private func setupBindings() {
        // 监听语音识别状态
        speechRecognition.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                if !isRecording && self?.isListening == true {
                    // 语音识别停止时自动处理结果
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.stopListening()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// 处理语音输入
    /// - Parameter input: 用户的语音输入文本
    private func processVoiceInput(_ input: String) {
        lastQuestion = input
        
        let response = generateResponse(for: input)
        lastResponse = response
        
        // 添加到对话历史
        let conversation = ConversationItem(
            question: input,
            response: response,
            timestamp: Date(),
            detectionContext: currentDetections
        )
        conversationHistory.append(conversation)
        
        // 语音播报回答
        textToSpeech.speak(response)
        
        print("💬 Q: \(input)")
        print("🤖 A: \(response)")
    }
    
    /// 生成智能回答
    /// - Parameter question: 用户问题
    /// - Returns: AI生成的回答
    private func generateResponse(for question: String) -> String {
        let normalizedQuestion = question.lowercased()
        
        // 检测结果统计
        let detectionStats = generateDetectionStatistics()
        
        // 智能问答匹配
        if normalizedQuestion.contains("这是什么") || normalizedQuestion.contains("看到什么") {
            return generateWhatIsThisResponse()
            
        } else if normalizedQuestion.contains("多少") && (normalizedQuestion.contains("人") || normalizedQuestion.contains("个")) {
            return generateCountResponse(for: "人")
            
        } else if normalizedQuestion.contains("有没有") {
            return generateExistenceResponse(for: question)
            
        } else if normalizedQuestion.contains("统计") || normalizedQuestion.contains("总共") {
            return generateStatisticsResponse(detectionStats)
            
        } else if normalizedQuestion.contains("开始") || normalizedQuestion.contains("检测") {
            return "好的，我将继续为您进行实时物体检测。"
            
        } else if normalizedQuestion.contains("停止") {
            return "已停止检测。如需重新开始，请说'开始检测'。"
            
        } else if normalizedQuestion.contains("帮助") || normalizedQuestion.contains("怎么用") {
            return generateHelpResponse()
            
        } else if normalizedQuestion.contains("清楚") || normalizedQuestion.contains("清晰") {
            return "图像检测正在进行中。当前检测置信度设置为\(String(format: "%.0f", 0.25 * 100))%。"
            
        } else {
            return generateContextualResponse(for: question, with: detectionStats)
        }
    }
    
    /// 生成"这是什么"类型的回答
    private func generateWhatIsThisResponse() -> String {
        guard !currentDetections.isEmpty else {
            return "我暂时没有检测到任何物体，请确保摄像头对准要识别的物体。"
        }
        
        // 按置信度排序，取前3个
        let topDetections = currentDetections
            .sorted { $0.confidence > $1.confidence }
            .prefix(3)
        
        if topDetections.count == 1 {
            let detection = topDetections.first!
            let confidence = Int(detection.confidence * 100)
            return "我看到这是\(detection.label)，置信度为\(confidence)%。"
        } else {
            let items = topDetections.map { detection in
                let confidence = Int(detection.confidence * 100)
                return "\(detection.label)(\(confidence)%)"
            }
            return "我看到了\(items.joined(separator: "、"))。"
        }
    }
    
    /// 生成计数类型的回答
    private func generateCountResponse(for objectType: String) -> String {
        let count = currentDetections.filter { $0.label.contains(objectType) }.count
        
        if count == 0 {
            return "当前画面中没有检测到\(objectType)。"
        } else {
            return "我检测到\(count)个\(objectType)。"
        }
    }
    
    /// 生成存在性查询的回答
    private func generateExistenceResponse(for question: String) -> String {
        // 简单的关键词匹配
        let keywords = ["人", "车", "猫", "狗", "椅子", "桌子", "手机", "笔记本电脑"]
        
        for keyword in keywords {
            if question.contains(keyword) {
                let exists = currentDetections.contains { $0.label.contains(keyword) }
                return exists ? "是的，我检测到了\(keyword)。" : "没有，我没有检测到\(keyword)。"
            }
        }
        
        return "请具体说明您要查找的物体，我会帮您检测。"
    }
    
    /// 生成统计类型的回答
    private func generateStatisticsResponse(_ stats: [String: Int]) -> String {
        guard !stats.isEmpty else {
            return "当前没有检测到任何物体。"
        }
        
        let totalCount = stats.values.reduce(0, +)
        let items = stats.map { "\($1)个\($0)" }.joined(separator: "，")
        
        return "总共检测到\(totalCount)个物体：\(items)。"
    }
    
    /// 生成帮助信息
    private func generateHelpResponse() -> String {
        return """
        我可以帮您：
        1. 识别画面中的物体 - 问"这是什么"
        2. 统计物体数量 - 问"有多少个人"
        3. 查找特定物体 - 问"有没有猫"
        4. 播报检测统计 - 说"统计一下"
        您还可以说"开始检测"或"停止检测"来控制检测功能。
        """
    }
    
    /// 生成上下文相关的回答
    private func generateContextualResponse(for question: String, with stats: [String: Int]) -> String {
        if stats.isEmpty {
            return "我暂时没有检测到相关物体。请调整摄像头角度或确保光线充足。"
        } else {
            let mainObjects = Array(stats.keys.prefix(2)).joined(separator: "和")
            return "根据当前检测结果，我主要看到了\(mainObjects)。您想了解什么具体信息呢？"
        }
    }
    
    /// 生成检测结果统计
    private func generateDetectionStatistics() -> [String: Int] {
        var stats: [String: Int] = [:]
        
        for detection in currentDetections {
            stats[detection.label, default: 0] += 1
        }
        
        return stats
    }
}

// MARK: - Conversation Data Model

struct ConversationItem: Identifiable {
    let id = UUID()
    let question: String
    let response: String
    let timestamp: Date
    let detectionContext: [DetectionResult]
}
