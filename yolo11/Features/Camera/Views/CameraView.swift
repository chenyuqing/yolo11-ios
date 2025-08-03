//
//  CameraView.swift
//  yolo11
//
//  Created by tim on 2025/8/3.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @State private var viewModel = CameraViewModel()
    @State private var screenSize: CGSize = .zero
    @State private var isPresented = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 摄像头预览
                CameraPreviewView()
                    .onAppear {
                        screenSize = geometry.size
                    }
                
                // 结束按钮
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            viewModel.stopDetection()
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
                
                // 检测结果弹幕
                VStack {
                    Spacer()
                    
                    // 弹幕显示区域（屏幕底部到2/3高度）
                    ZStack(alignment: .bottomLeading) {
                        ForEach(viewModel.bannerResults) { result in
                            DetectionBannerView(
                                result: result,
                                screenHeight: screenSize.height
                            )
                            .id(result.id)
                        }
                    }
                    .frame(height: screenSize.height * 2/3)
                    .padding(.leading, 20)
                    .padding(.bottom, 50)
                    
                    Spacer()
                }
            }
            .onAppear {
                viewModel.startDetection()
            }
            .onDisappear {
                viewModel.stopDetection()
                viewModel.clearBannerResults()
            }
        }
    }
}

#Preview {
    CameraView()
}