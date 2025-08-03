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
    let startOffset: CGFloat
    @State private var verticalOffset: CGFloat = 0
    @State private var opacity: Double = 1.0
    
    init(result: DetectionResult, screenHeight: CGFloat, startOffset: CGFloat = 0) {
        self.result = result
        self.screenHeight = screenHeight
        self.startOffset = startOffset
        self._verticalOffset = State(initialValue: 0) // 从底部开始
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
        .offset(x: startOffset, y: verticalOffset)
        .opacity(opacity)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // IG直播样式：从底部向上移动到屏幕中间位置消失
        let targetOffset = -(screenHeight * 0.5) // 移动到屏幕中间位置
        
        // 向上移动动画
        withAnimation(.linear(duration: 3.0)) {
            verticalOffset = targetOffset
        }
        
        // 在移动过程中逐渐淡出
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 1.0)) {
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