//
//  VoiceInteractionView.swift
//  yolo11
//
//  Created by tim on 2025/8/4.
//

import SwiftUI

struct VoiceInteractionView: View {
    @StateObject private var voiceAssistant = VoiceAssistantService()
    @Binding var detections: [DetectionResult]
    
    @State private var showConversationHistory = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 语音交互主按钮
            voiceInteractionButton
            
            // 展开的控制面板
            if isExpanded {
                expandedControlPanel
            }
            
            // 对话历史面板
            if showConversationHistory {
                conversationHistoryPanel
            }
        }
        .onChange(of: detections) { _, newDetections in
            voiceAssistant.updateDetections(newDetections)
        }
    }
    
    // MARK: - Voice Interaction Button
    
    private var voiceInteractionButton: some View {
        HStack(spacing: 12) {
            // 主语音按钮
            Button(action: {
                if voiceAssistant.isListening {
                    voiceAssistant.stopListening()
                } else {
                    voiceAssistant.startListening()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(voiceAssistant.isListening ? 
                              Color.red.opacity(0.8) : 
                              Color.blue.opacity(0.8))
                        .frame(width: 60, height: 60)
                        .scaleEffect(voiceAssistant.isListening ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), 
                                 value: voiceAssistant.isListening)
                    
                    Image(systemName: voiceAssistant.isListening ? "mic.fill" : "mic")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            
            // 状态文本
            VStack(alignment: .leading, spacing: 2) {
                Text(voiceAssistant.isListening ? "正在聆听..." : "点击开始语音对话")
                    .font(.caption)
                    .foregroundColor(.white)
                
                if !voiceAssistant.lastResponse.isEmpty {
                    Text(voiceAssistant.lastResponse)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            
            Spacer()
            
            // 展开/收起按钮
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.black.opacity(0.7))
        )
    }
    
    // MARK: - Expanded Control Panel
    
    private var expandedControlPanel: some View {
        VStack(spacing: 12) {
            // 快捷操作按钮
            HStack(spacing: 12) {
                quickActionButton("播报检测", systemImage: "speaker.wave.2") {
                    voiceAssistant.announceCurrentDetections()
                }
                
                quickActionButton("统计物体", systemImage: "chart.bar") {
                    voiceAssistant.askQuestion("统计一下当前检测到的物体")
                }
                
                quickActionButton("查看历史", systemImage: "clock") {
                    withAnimation(.spring()) {
                        showConversationHistory.toggle()
                    }
                }
                
                quickActionButton("清除记录", systemImage: "trash") {
                    voiceAssistant.clearHistory()
                }
            }
            
            // 常用问题按钮
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    commonQuestionButton("这是什么？")
                    commonQuestionButton("有多少个人？")
                }
                
                HStack(spacing: 8) {
                    commonQuestionButton("有没有车？")
                    commonQuestionButton("帮助")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.6))
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.8)),
            removal: .opacity.combined(with: .scale(scale: 0.8))
        ))
    }
    
    // MARK: - Conversation History Panel
    
    private var conversationHistoryPanel: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(voiceAssistant.conversationHistory.reversed()) { conversation in
                    ConversationBubbleView(conversation: conversation)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(maxHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.5))
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity.combined(with: .move(edge: .top))
        ))
    }
    
    // MARK: - Helper Views
    
    private func quickActionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.2))
            )
        }
    }
    
    private func commonQuestionButton(_ question: String) -> some View {
        Button(action: {
            voiceAssistant.askQuestion(question)
        }) {
            Text(question)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.blue.opacity(0.6))
                )
        }
    }
}

// MARK: - Conversation Bubble View

struct ConversationBubbleView: View {
    let conversation: ConversationItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 用户问题
            HStack {
                Spacer()
                Text(conversation.question)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue.opacity(0.7))
                    )
                    .frame(maxWidth: 200, alignment: .trailing)
            }
            
            // AI回答
            HStack {
                Text(conversation.response)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.7))
                    )
                    .frame(maxWidth: 200, alignment: .leading)
                Spacer()
            }
            
            // 时间戳
            Text(formatTimestamp(conversation.timestamp))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct VoiceInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VoiceInteractionView(detections: .constant([
                DetectionResult(label: "人", confidence: 0.85),
                DetectionResult(label: "车", confidence: 0.72)
            ]))
        }
        .previewDevice("iPhone 15")
    }
}