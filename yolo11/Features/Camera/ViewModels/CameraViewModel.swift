//
//  CameraViewModel.swift
//  yolo11
//
//  Created by tim on 2025/8/3.
//

import Foundation
import CoreGraphics
import UIKit
import AVFoundation
import Vision
import CoreML
import Combine

@Observable
class CameraViewModel: NSObject, CameraPreviewDelegate {
    // 摄像头状态
    var isDetecting = false
    var errorMessage: String?
    var isUsingWideAngle = false
    
    // NMS参数
    var confidenceThreshold: Float = 0.25 {
        didSet {
            predictor?.confidenceThreshold = confidenceThreshold
        }
    }
    var iouThreshold: Float = 0.45 {
        didSet {
            predictor?.iouThreshold = iouThreshold
        }
    }
    
    // 检测结果
    var detectionResults: [DetectionResult] = []
    
    // 弹幕显示的结果
    var bannerResults: [DetectionResult] = []
    
    // YOLO预测器
    private var predictor: YOLOv11Predictor?
    
    // 用于控制检测频率
    private var lastDetectionTime: CFTimeInterval = 0
    private let minDetectionInterval: CFTimeInterval = 0.3  // 每0.3秒检测一次
    
    // 用于控制弹幕生成频率
    private var lastBannerTime: CFTimeInterval = 0
    private let minBannerInterval: CFTimeInterval = 0.8  // 每0.8秒最多产生一个弹幕
    
    override init() {
        super.init()
        setupPredictor()
    }
    
    // 设置YOLO预测器
    private func setupPredictor() {
        do {
            predictor = try YOLOv11Predictor()
            print("✅ YOLOv11Predictor 初始化成功")
        } catch {
            print("❌ Failed to initialize YOLOv11Predictor: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    // 开始检测
    func startDetection() {
        isDetecting = true
        errorMessage = nil
    }
    
    // 停止检测
    func stopDetection() {
        isDetecting = false
    }
    
    // 添加检测结果用于弹幕显示
    func addDetectionResultForBanner(_ result: DetectionResult) {
        bannerResults.append(result)
        
        // 限制弹幕数量，避免过多（IG样式建议少一些）
        if bannerResults.count > 8 {
            bannerResults.removeFirst()
        }
        
        // 自动清理已消失的弹幕
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if let index = self.bannerResults.firstIndex(where: { $0.id == result.id }) {
                self.bannerResults.remove(at: index)
            }
        }
    }
    
    // 清除弹幕结果
    func clearBannerResults() {
        bannerResults.removeAll()
    }
    
    // 切换相机类型（广角/普通）
    func toggleCameraType() {
        isUsingWideAngle.toggle()
        // 通知代理更新相机设置
        NotificationCenter.default.post(
            name: NSNotification.Name("CameraTypeChanged"),
            object: nil,
            userInfo: ["isWideAngle": isUsingWideAngle]
        )
    }
    
    // MARK: - CameraPreviewDelegate
    func didOutput(sampleBuffer: CMSampleBuffer) {
        // 控制检测频率
        let currentTime = CACurrentMediaTime()
        if currentTime - lastDetectionTime < minDetectionInterval {
            return
        }
        lastDetectionTime = currentTime
        
        // 在后台线程处理检测
        DispatchQueue.global(qos: .userInitiated).async {
            self.processDetection(sampleBuffer: sampleBuffer)
        }
    }
    
    private func processDetection(sampleBuffer: CMSampleBuffer) {
        guard let predictor = predictor else { 
            print("⚠️ Predictor is nil, skipping detection")
            return 
        }
        
        guard isDetecting else {
            return
        }
        
        // 从sampleBuffer获取图像
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { 
            print("⚠️ Failed to get pixel buffer from sample buffer")
            return 
        }
        
        // 创建CGImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { 
            print("⚠️ Failed to create CGImage from pixel buffer")
            return 
        }
        
        // 执行异步预测
        Task {
            let detections = await predictor.performPrediction(on: cgImage)
            
            // 转换为DetectionResult格式
            let results = detections.map { detection in
                DetectionResult(
                    label: detection.label,
                    confidence: detection.confidence,
                    boundingBox: detection.boundingBox
                )
            }
            
            // 在主线程更新UI
            await MainActor.run {
                self.detectionResults = results
                
                // 控制弹幕生成频率，避免过于频繁
                let currentTime = CACurrentMediaTime()
                if currentTime - self.lastBannerTime >= self.minBannerInterval {
                    // 只为置信度最高的检测结果创建弹幕
                    if let bestResult = results.max(by: { $0.confidence < $1.confidence }) {
                        self.addDetectionResultForBanner(bestResult)
                        self.lastBannerTime = currentTime
                    }
                }
            }
        }
    }
}