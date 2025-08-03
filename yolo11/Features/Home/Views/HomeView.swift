//
//  HomeView.swift
//  yolo11
//
//  Created by tim on 2025/8/3.
//

import SwiftUI

struct HomeView: View {
    @State private var navigateToCamera = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // 顶部安全区域间距
                    Spacer()
                        .frame(height: 60)
                    
                    // 主要内容区域
                    VStack(spacing: 30) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 12) {
                            Text("YOLOv11 实时检测")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("点击下方按钮开始实时物体检测")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    // 弹性间距
                    Spacer()
                        .frame(minHeight: 40)
                    
                    // 按钮区域
                    VStack(spacing: 20) {
                        Button(action: {
                            navigateToCamera = true
                        }) {
                            Text("开始实时检测")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 底部安全区域间距
                    Spacer()
                        .frame(height: 80)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .navigationDestination(isPresented: $navigateToCamera) {
                CameraView()
            }
        }
    }
}

#Preview {
    HomeView()
}