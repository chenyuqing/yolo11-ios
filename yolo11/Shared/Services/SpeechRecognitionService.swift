//
//  SpeechRecognitionService.swift
//  yolo11
//
//  Created by tim on 2025/8/4.
//

import Foundation
import Speech
import AVFoundation

/// 语音识别服务 - 处理语音转文本功能
class SpeechRecognitionService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var isAuthorized = false
    
    // MARK: - Private Properties
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // MARK: - Initialization
    override init() {
        super.init()
        requestPermissions()
    }
    
    // MARK: - Public Methods
    
    /// 开始语音识别
    func startRecording() {
        guard isAuthorized else {
            print("❌ 语音识别未授权")
            return
        }
        
        if audioEngine.isRunning {
            stopRecording()
            return
        }
        
        do {
            try startSpeechRecognition()
            isRecording = true
            print("🎙️ 开始语音识别...")
        } catch {
            print("❌ 启动语音识别失败: \(error)")
        }
    }
    
    /// 停止语音识别
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        
        print("🛑 停止语音识别")
    }
    
    /// 清除识别文本
    func clearText() {
        recognizedText = ""
    }
    
    // MARK: - Private Methods
    
    /// 请求语音识别权限
    private func requestPermissions() {
        // 请求语音识别权限
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.isAuthorized = true
                    print("✅ 语音识别权限已授权")
                    
                    // 请求麦克风权限
                    self.requestMicrophonePermission()
                    
                case .denied:
                    self.isAuthorized = false
                    print("❌ 语音识别权限被拒绝")
                    
                case .restricted:
                    self.isAuthorized = false
                    print("❌ 语音识别权限受限")
                    
                case .notDetermined:
                    self.isAuthorized = false
                    print("⏳ 语音识别权限未确定")
                    
                @unknown default:
                    self.isAuthorized = false
                    print("❌ 未知的语音识别权限状态")
                }
            }
        }
    }
    
    /// 请求麦克风权限
    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("✅ 麦克风权限已授权")
                } else {
                    print("❌ 麦克风权限被拒绝")
                    self.isAuthorized = false
                }
            }
        }
    }
    
    /// 启动语音识别
    private func startSpeechRecognition() throws {
        // 取消之前的任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 配置音频引擎
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // 开始识别任务
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
    }
}

// MARK: - Speech Error Enum

enum SpeechError: Error {
    case recognitionRequestFailed
    case audioEngineFailed
    case permissionDenied
    
    var localizedDescription: String {
        switch self {
        case .recognitionRequestFailed:
            return "语音识别请求创建失败"
        case .audioEngineFailed:
            return "音频引擎启动失败"
        case .permissionDenied:
            return "权限被拒绝"
        }
    }
}