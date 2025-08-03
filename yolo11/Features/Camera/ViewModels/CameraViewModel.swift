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
    
    // 检测结果
    var detectionResults: [DetectionResult] = []
    
    // 弹幕显示的结果
    var bannerResults: [DetectionResult] = []
    
    // YOLO预测器
    private var predictor: YOLOv11Predictor?
    
    // 用于控制检测频率
    private var lastDetectionTime: CFTimeInterval = 0
    private let minDetectionInterval: CFTimeInterval = 0.3  // 每0.3秒检测一次
    
    override init() {
        super.init()
        setupPredictor()
    }
    
    // 设置YOLO预测器
    private func setupPredictor() {
        do {
            predictor = try YOLOv11Predictor()
        } catch {
            print("Failed to initialize YOLOv11Predictor: \(error)")
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
        
        // 限制弹幕数量，避免过多
        if bannerResults.count > 30 {
            bannerResults.removeFirst()
        }
    }
    
    // 清除弹幕结果
    func clearBannerResults() {
        bannerResults.removeAll()
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
        guard let predictor = predictor else { return }
        
        // 从sampleBuffer获取图像
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // 创建CGImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
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
                
                // 为每个检测结果创建弹幕
                for result in results {
                    self.addDetectionResultForBanner(result)
                }
            }
        }
    }
}