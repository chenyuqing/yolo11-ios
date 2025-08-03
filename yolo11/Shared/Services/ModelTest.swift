//
//  ModelTest.swift
//  yolo11
//
//  Created by tim on 2025/8/3.
//

import Foundation
import UIKit

class ModelTest {
    static func testModelLoading() {
        print("=== 开始测试YOLO模型加载 ===")
        
        do {
            let predictor = try YOLOv11Predictor()
            print("✅ YOLO模型加载成功！")
            
            // 创建一个简单的测试图像
            let size = CGSize(width: 640, height: 640)
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            UIColor.blue.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            
            if let testImage = UIGraphicsGetImageFromCurrentImageContext(),
               let cgImage = testImage.cgImage {
                UIGraphicsEndImageContext()
                
                Task {
                    let detections = await predictor.performPrediction(on: cgImage)
                    print("✅ 模型预测完成，检测到 \(detections.count) 个对象")
                    
                    for (index, detection) in detections.enumerated() {
                        print("检测结果 \(index + 1): \(detection.label), 置信度: \(detection.confidence)")
                    }
                }
            } else {
                print("❌ 无法创建测试图像")
                UIGraphicsEndImageContext()
            }
            
        } catch {
            print("❌ YOLO模型加载失败: \(error)")
        }
        
        print("=== 模型测试完成 ===")
    }
}