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
            VStack(spacing: 0) {
                // 上方弹性间距
                Spacer()
                
                // 紧凑的主要内容区域
                VStack(spacing: 20) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("YOLOv11 实时检测")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("点击下方按钮开始实时物体检测")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    // 紧凑的按钮区域
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
                    .padding(.horizontal, 30)
                    .padding(.top, 16)
                }
                
                // 下方弹性间距
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .navigationDestination(isPresented: $navigateToCamera) {
                CameraView()
            }
        }
    }
}

#Preview {
    HomeView()
}