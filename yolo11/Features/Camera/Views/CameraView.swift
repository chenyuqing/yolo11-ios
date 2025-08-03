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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 摄像头预览
                CameraPreviewView(delegate: viewModel)
                    .onAppear {
                        screenSize = geometry.size
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
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
        .edgesIgnoringSafeArea(.all)  // 确保全屏显示
    }
}

#Preview {
    CameraView()
}