//
//  DetectionResult.swift
//  yolo11
//
//  Created by tim on 2025/8/3.
//

import Foundation
import CoreGraphics

struct DetectionResult: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect?
    
    init(label: String, confidence: Float, boundingBox: CGRect? = nil) {
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
    
    static func == (lhs: DetectionResult, rhs: DetectionResult) -> Bool {
        return lhs.label == rhs.label && 
               lhs.confidence == rhs.confidence &&
               lhs.boundingBox?.equalTo(rhs.boundingBox ?? CGRect.zero) ?? (rhs.boundingBox == nil)
    }
}