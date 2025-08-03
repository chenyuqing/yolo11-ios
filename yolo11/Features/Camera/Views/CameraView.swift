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
                
                // 检测结果弹幕（IG直播样式：左下角向上移动）
                VStack {
                    Spacer()
                    
                    // 弹幕显示区域（左下角，向上移动）
                    ZStack(alignment: .bottomLeading) {
                        ForEach(Array(viewModel.bannerResults.enumerated()), id: \.element.id) { index, result in
                            DetectionBannerView(
                                result: result,
                                screenHeight: screenSize.height,
                                startOffset: CGFloat(index * 5) // 轻微的水平偏移避免重叠
                            )
                            .id(result.id)
                        }
                    }
                    .frame(height: screenSize.height * 0.6) // 占屏幕高度60%用于弹幕区域
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.bottom, 100) // 从底部向上留出空间
                    .clipped() // 确保弹幕不会超出边界
                }
                
                // NMS阈值调节滑条（右上角）
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 12) {
                            // 置信度阈值滑条
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("置信度: \(String(format: "%.2f", viewModel.confidenceThreshold))")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(4)
                                
                                Slider(value: Binding(
                                    get: { Double(viewModel.confidenceThreshold) },
                                    set: { viewModel.confidenceThreshold = Float($0) }
                                ), in: 0.1...0.9, step: 0.05)
                                .frame(width: 120)
                                .accentColor(.blue)
                            }
                            
                            // IoU阈值滑条
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("IoU: \(String(format: "%.2f", viewModel.iouThreshold))")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(4)
                                
                                Slider(value: Binding(
                                    get: { Double(viewModel.iouThreshold) },
                                    set: { viewModel.iouThreshold = Float($0) }
                                ), in: 0.1...0.9, step: 0.05)
                                .frame(width: 120)
                                .accentColor(.green)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 60)
                    }
                    Spacer()
                }
                
                // 相机切换按钮（右下角）
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.toggleCameraType()
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: viewModel.isUsingWideAngle ? "0.5.circle.fill" : "1.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                
                                Text(viewModel.isUsingWideAngle ? "0.5x" : "1x")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 40)
                    }
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