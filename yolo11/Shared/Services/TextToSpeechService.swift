//
//  TextToSpeechService.swift
//  yolo11
//
//  Created by tim on 2025/8/4.
//

import Foundation
import AVFoundation

/// 语音合成服务 - 处理文本转语音功能
class TextToSpeechService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSpeaking = false
    @Published var speechRate: Float = 0.5
    @Published var speechPitch: Float = 1.0
    @Published var speechVolume: Float = 1.0
    
    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupSynthesizer()
    }
    
    // MARK: - Public Methods
    
    /// 播放文本语音
    /// - Parameter text: 要播放的文本
    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        
        // 停止当前播放
        if synthesizer.isSpeaking {
            stopSpeaking()
        }
        
        // 创建语音话语
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume
        
        currentUtterance = utterance
        
        // 配置音频会话
        configureAudioSession()
        
        // 开始播放
        synthesizer.speak(utterance)
        isSpeaking = true
        
        print("🔊 播放语音: \(text)")
    }
    
    /// 停止语音播放
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentUtterance = nil
        print("🛑 停止语音播放")
    }
    
    /// 暂停语音播放
    func pauseSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
            print("⏸️ 暂停语音播放")
        }
    }
    
    /// 继续语音播放
    func continueSpeaking() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            print("▶️ 继续语音播放")
        }
    }
    
    /// 快速播报检测结果
    /// - Parameter detections: 检测结果数组
    func announceDetections(_ detections: [String]) {
        guard !detections.isEmpty else { return }
        
        let announcement: String
        if detections.count == 1 {
            announcement = "检测到\(detections.first!)"
        } else if detections.count <= 3 {
            announcement = "检测到" + detections.joined(separator: "、")
        } else {
            let mainItems = Array(detections.prefix(3)).joined(separator: "、")
            announcement = "检测到\(mainItems)等\(detections.count)个物体"
        }
        
        speak(announcement)
    }
    
    /// 播报物体统计
    /// - Parameter statistics: 物体统计字典
    func announceStatistics(_ statistics: [String: Int]) {
        guard !statistics.isEmpty else { return }
        
        var announcement = "当前检测到："
        let items = statistics.map { "\($1)个\($0)" }
        announcement += items.joined(separator: "，")
        
        speak(announcement)
    }
    
    /// 设置语音参数
    /// - Parameters:
    ///   - rate: 语速 (0.0 - 1.0)
    ///   - pitch: 音调 (0.5 - 2.0)
    ///   - volume: 音量 (0.0 - 1.0)
    func configureSpeech(rate: Float = 0.5, pitch: Float = 1.0, volume: Float = 1.0) {
        speechRate = max(0.0, min(1.0, rate))
        speechPitch = max(0.5, min(2.0, pitch))
        speechVolume = max(0.0, min(1.0, volume))
        
        print("🎛️ 语音参数设置 - 语速: \(speechRate), 音调: \(speechPitch), 音量: \(speechVolume)")
    }
    
    // MARK: - Private Methods
    
    /// 设置语音合成器
    private func setupSynthesizer() {
        synthesizer.delegate = self
    }
    
    /// 配置音频会话
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
        print("🎵 语音播放开始")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentUtterance = nil
        }
        print("✅ 语音播放完成")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentUtterance = nil
        }
        print("❌ 语音播放被取消")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("⏸️ 语音播放已暂停")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        print("▶️ 语音播放已继续")
    }
}