//
//  YOLOv11Predictor.swift
//  yolo11
//
//  Created by tim on 2025/8/3.
//

import Vision
import CoreML
import UIKit

// 检测结果结构体
struct Detection {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect
}

// YOLOv11预测器类
class YOLOv11Predictor {
    
    private let model: VNCoreMLModel
    var confidenceThreshold: Float = 0.25
    var iouThreshold: Float = 0.45
    
    // COCO数据集的80个类别标签 - 中文版
    private let cocoClasses = [
        "人", "自行车", "汽车", "摩托车", "飞机", "公交车", "火车", "卡车", "船", "红绿灯",
        "消防栓", "停车标志", "停车计时器", "长椅", "鸟", "猫", "狗", "马", "羊", "牛",
        "大象", "熊", "斑马", "长颈鹿", "背包", "雨伞", "手提包", "领带", "行李箱", "飞盘",
        "滑雪板", "滑雪板", "运动球", "风筝", "棒球棒", "棒球手套", "滑板", "冲浪板",
        "网球拍", "瓶子", "酒杯", "杯子", "叉子", "刀", "勺子", "碗", "香蕉", "苹果",
        "三明治", "橙子", "西兰花", "胡萝卜", "热狗", "披萨", "甜甜圈", "蛋糕", "椅子", "沙发",
        "盆栽", "床", "餐桌", "马桶", "电视", "笔记本电脑", "鼠标", "遥控器", "键盘", "手机",
        "微波炉", "烤箱", "烤面包机", "水槽", "冰箱", "书", "时钟", "花瓶", "剪刀", "泰迪熊",
        "吹风机", "牙刷"
    ]
    
    init() throws {
        // 从app bundle加载编译后的.mlmodelc格式的模型
        guard let modelURL = Bundle.main.url(forResource: "yolo11n", withExtension: "mlmodelc") else {
            print("Failed to find yolo11n.mlmodelc in app bundle")
            print("Available resources in bundle:")
            let allResources = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) ?? []
            for resource in allResources {
                print("  - \(resource.lastPathComponent)")
            }
            throw PredictorError.modelNotFound
        }
        
        print("Found model at: \(modelURL)")
        
        // 设置CoreML计算单元为全部（包括Neural Engine）
        let config = MLModelConfiguration()
        config.computeUnits = .all
        
        guard let coreMLModel = try? MLModel(contentsOf: modelURL, configuration: config) else {
            throw PredictorError.modelLoadFailed
        }
        
        // 创建Vision模型
        do {
            let visionModel = try VNCoreMLModel(for: coreMLModel)
            self.model = visionModel
            print("VNCoreMLModel创建成功")
        } catch {
            print("VNCoreMLModel创建失败: \(error)")
            throw PredictorError.visionModelCreationFailed
        }
    }
    
    // 执行预测
    func performPrediction(on image: CGImage) async -> [Detection] {
        let requestHandler = VNImageRequestHandler(cgImage: image)
        
        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { (request, error) in
                if let error = error {
                    print("Vision request failed with error: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                // 检查所有可能的输出类型
                if let observations = request.results as? [VNRecognizedObjectObservation] {
                    print("使用VNRecognizedObjectObservation输出")
                    let rawDetections = observations.compactMap { observation -> Detection? in
                        guard let bestLabel = observation.labels.first,
                              bestLabel.confidence >= self.confidenceThreshold else {
                            return nil
                        }
                        
                        return Detection(
                            label: bestLabel.identifier,
                            confidence: bestLabel.confidence,
                            boundingBox: observation.boundingBox
                        )
                    }
                    
                    // 应用NMS后处理
                    let filteredDetections = self.applyNMS(to: rawDetections)
                    continuation.resume(returning: filteredDetections)
                    return
                } else if let pixelBuffers = request.results as? [VNPixelBufferObservation] {
                    print("使用VNPixelBufferObservation输出，需要后处理")
                    // YOLO模型原始输出处理
                    let detections = self.processYOLOOutput(pixelBuffers)
                    let filteredDetections = self.applyNMS(to: detections)
                    continuation.resume(returning: filteredDetections)
                    return
                } else if let coreMLFeatures = request.results as? [VNCoreMLFeatureValueObservation] {
                    print("使用VNCoreMLFeatureValueObservation输出")
                    let detections = self.processCoreMLFeatures(coreMLFeatures)
                    let filteredDetections = self.applyNMS(to: detections)
                    continuation.resume(returning: filteredDetections)
                    return
                } else {
                    print("未知的输出类型: \(type(of: request.results))")
                    if let results = request.results {
                        print("结果数量: \(results.count)")
                        for (i, result) in results.enumerated() {
                            print("结果 \(i): \(type(of: result))")
                        }
                    }
                    continuation.resume(returning: [])
                    return
                }
                
            }
            
            request.imageCropAndScaleOption = .scaleFill
            
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform Vision request: \(error)")
                continuation.resume(returning: [])
            }
        }
    }
    
    // NMS（非极大值抑制）后处理
    private func applyNMS(to detections: [Detection]) -> [Detection] {
        guard !detections.isEmpty else { return [] }
        
        // 按置信度降序排序
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        var selectedDetections: [Detection] = []
        
        for detection in sortedDetections {
            var shouldKeep = true
            
            // 检查与已选择的检测结果的IoU
            for selectedDetection in selectedDetections {
                let iou = calculateIoU(box1: detection.boundingBox, box2: selectedDetection.boundingBox)
                
                // 如果IoU超过阈值且是同一类别，则抑制当前检测
                if iou > iouThreshold && detection.label == selectedDetection.label {
                    shouldKeep = false
                    break
                }
            }
            
            if shouldKeep {
                selectedDetections.append(detection)
            }
        }
        
        return selectedDetections
    }
    
    // 计算两个边界框的IoU（交并比）
    private func calculateIoU(box1: CGRect, box2: CGRect) -> Float {
        let intersection = box1.intersection(box2)
        
        // 如果没有交集，IoU为0
        guard !intersection.isNull else { return 0.0 }
        
        let intersectionArea = intersection.width * intersection.height
        let unionArea = box1.width * box1.height + box2.width * box2.height - intersectionArea
        
        return Float(intersectionArea / unionArea)
    }
    
    // 处理YOLO原始输出
    private func processYOLOOutput(_ pixelBuffers: [VNPixelBufferObservation]) -> [Detection] {
        // TODO: 实现YOLO原始输出解析
        print("处理YOLO原始输出，pixelBuffer数量: \(pixelBuffers.count)")
        return []
    }
    
    // 处理CoreML特征值输出
    private func processCoreMLFeatures(_ features: [VNCoreMLFeatureValueObservation]) -> [Detection] {
        var detections: [Detection] = []
        
        print("处理CoreML特征值输出，特征数量: \(features.count)")
        
        for feature in features {
            print("特征名称: \(feature.featureName)")
            if let multiArray = feature.featureValue.multiArrayValue {
                print("MultiArray形状: \(multiArray.shape)")
                print("MultiArray数据类型: \(multiArray.dataType)")
                
                let shape = multiArray.shape.map { $0.intValue }
                
                // 检查是否是YOLO输出格式: [1, 84, 8400]
                if shape.count == 3 && shape[0] == 1 && shape[1] == 84 && shape[2] == 8400 {
                    print("开始解析YOLO输出格式 [1, 84, 8400]")
                    detections = parseYOLOOutput(multiArray: multiArray)
                } else {
                    print("未知的输出形状: \(shape)")
                }
            }
        }
        
        return detections
    }
    
    // 解析YOLO输出 - 内存优化版本
    private func parseYOLOOutput(multiArray: MLMultiArray) -> [Detection] {
        // 预分配检测结果数组容量以减少重分配
        var detections: [Detection] = []
        detections.reserveCapacity(50)  // 预期最多50个有效检测
        
        // YOLO输出格式: [1, 84, 8400]
        // 84 = 4个边界框坐标 (x, y, w, h) + 80个类别概率
        // 8400 = 检测框总数
        
        let numDetections = 8400
        let numClasses = 80
        
        // 转换为Float数组以便处理
        let dataPointer = multiArray.dataPointer.bindMemory(to: Float.self, capacity: multiArray.count)
        let stride1 = multiArray.strides[1].intValue  // 84
        let stride2 = multiArray.strides[2].intValue  // 1
        
        for i in 0..<numDetections {
            // 获取边界框坐标 (中心点格式)
            let x = dataPointer[0 * stride1 + i * stride2]
            let y = dataPointer[1 * stride1 + i * stride2]
            let w = dataPointer[2 * stride1 + i * stride2]
            let h = dataPointer[3 * stride1 + i * stride2]
            
            // 查找最高置信度的类别
            var maxClassScore: Float = 0
            var maxClassIndex = 0
            
            for classIndex in 0..<numClasses {
                let classScore = dataPointer[(4 + classIndex) * stride1 + i * stride2]
                if classScore > maxClassScore {
                    maxClassScore = classScore
                    maxClassIndex = classIndex
                }
            }
            
            // 过滤低置信度检测 - 早期退出优化
            if maxClassScore >= confidenceThreshold {
                // 转换边界框格式：从中心点(x,y,w,h)到左上角(x,y,w,h)
                let rectX = (x - w / 2) / 640.0  // 归一化到[0,1]
                let rectY = (y - h / 2) / 640.0
                let rectW = w / 640.0
                let rectH = h / 640.0
                
                // 过滤明显无效的边界框
                guard rectW > 0.01 && rectH > 0.01 else { continue }
                
                // 确保边界框在有效范围内
                let boundingBox = CGRect(
                    x: max(0, min(1, CGFloat(rectX))),
                    y: max(0, min(1, CGFloat(rectY))),
                    width: max(0, min(1, CGFloat(rectW))),
                    height: max(0, min(1, CGFloat(rectH)))
                )
                
                // 获取类别标签
                let classLabel = maxClassIndex < cocoClasses.count ? cocoClasses[maxClassIndex] : "unknown"
                
                let detection = Detection(
                    label: classLabel,
                    confidence: maxClassScore,
                    boundingBox: boundingBox
                )
                
                detections.append(detection)
                
                // 限制检测结果数量以控制内存使用
                if detections.count >= 30 {
                    break
                }
            }
        }
        
        print("原始检测结果数量: \(detections.count)")
        
        // 内存优化：压缩数组容量
        detections.reserveCapacity(detections.count)
        return detections
    }
}

// 预测器错误类型
enum PredictorError: Error {
    case modelNotFound
    case modelLoadFailed
    case modelConfigurationFailed
    case visionModelCreationFailed
    
    var localizedDescription: String {
        switch self {
        case .modelNotFound:
            return "CoreML model not found in bundle"
        case .modelLoadFailed:
            return "Failed to load CoreML model"
        case .modelConfigurationFailed:
            return "Failed to configure CoreML model"
        case .visionModelCreationFailed:
            return "Failed to create VNCoreMLModel"
        }
    }
}