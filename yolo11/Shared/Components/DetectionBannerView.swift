//
//  DetectionBannerView.swift
//  yolo11
//
//  Created by tim on 2025/8/3.
//

import SwiftUI

struct DetectionBannerView: View {
    let result: DetectionResult
    let screenHeight: CGFloat
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    
    init(result: DetectionResult, screenHeight: CGFloat) {
        self.result = result
        self.screenHeight = screenHeight
    }
    
    var body: some View {
        HStack {
            Text(result.label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text(String(format: "%.2f", result.confidence))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.4))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 计算动画终点（屏幕高度的2/3处）
        let targetOffset = -(screenHeight * 2/3)
        
        withAnimation(.linear(duration: 3.0)) {
            offset = targetOffset
        }
        
        // 淡出效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
            }
        }
    }
}

#Preview {
    DetectionBannerView(
        result: DetectionResult(label: "person", confidence: 0.95),
        screenHeight: 800
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.3))
}