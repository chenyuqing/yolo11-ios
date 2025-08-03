//
//  CameraViewModel.swift
//  yolo11
//
//  Created by tim on 2025/8/3.
//

import Foundation
import CoreGraphics
import UIKit

@Observable
class CameraViewModel {
    // 摄像头状态
    var isDetecting = false
    var errorMessage: String?
    
    // 检测结果
    var detectionResults: [DetectionResult] = []
    
    // 弹幕显示的结果
    var bannerResults: [DetectionResult] = []
    
    // 摄像头服务（将在后续实现中连接）
    // private let cameraService: CameraService
    
    init() {
        // cameraService = CameraService()
        // cameraService.delegate = self
    }
    
    // 开始检测
    func startDetection() {
        isDetecting = true
        errorMessage = nil
        // cameraService.startDetection()
    }
    
    // 停止检测
    func stopDetection() {
        isDetecting = false
        // cameraService.stopDetection()
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
}