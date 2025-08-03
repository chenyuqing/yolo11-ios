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
            VStack(spacing: 30) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("YOLOv11 实时检测")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("点击下方按钮开始实时物体检测")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    navigateToCamera = true
                }) {
                    Text("开始实时检测")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $navigateToCamera) {
                CameraView()
            }
        }
    }
}

#Preview {
    HomeView()
}