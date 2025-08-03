//
//  UIViewRepresentable+.swift
//  yolo11
//
//  Created by tim on 2025/8/3.
//

import SwiftUI
import AVFoundation

// 摄像头预览代理协议
protocol CameraPreviewDelegate: AnyObject {
    func didOutput(sampleBuffer: CMSampleBuffer)
}

// 摄像头预览视图
struct CameraPreviewView: UIViewRepresentable {
    var delegate: CameraPreviewDelegate?
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.delegate = delegate
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.delegate = delegate
    }
}

// 摄像头预览UIView
class CameraPreviewUIView: UIView {
    weak var delegate: CameraPreviewDelegate?
    
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }
    
    private func setupCamera() {
        // 初始化摄像头会话
        session = AVCaptureSession()
        
        // 设置预览层
        guard let previewLayer = layer as? AVCaptureVideoPreviewLayer else { return }
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.session = session
        self.previewLayer = previewLayer
        
        // 请求摄像头权限
        print("请求摄像头权限...")
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            print("摄像头权限结果: \(granted)")
            guard granted else { 
                print("摄像头权限被拒绝")
                return 
            }
            DispatchQueue.global(qos: .userInitiated).async {
                print("开始设置摄像头设备")
                self?.setupCaptureDevice()
            }
        }
    }
    
    private func setupCaptureDevice() {
        guard let session = session else { 
            print("session为空")
            return 
        }
        
        // 获取后置摄像头
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { 
            print("无法获取后置摄像头")
            return 
        }
        
        print("成功获取摄像头设备: \(device.localizedName)")
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            // 添加输入到会话
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            // 设置视频输出
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            if session.canAddOutput(output) {
                session.addOutput(output)
                videoOutput = output
                
                // 设置输出方向
                if #available(iOS 17.0, *) {
                    output.connection(with: .video)?.videoRotationAngle = 90
                } else {
                    output.connection(with: .video)?.videoOrientation = .portrait
                }
            }
            
            // 设置分辨率
            session.sessionPreset = .hd1280x720
            
            // 开始会话
            print("开始摄像头会话")
            session.startRunning()
            print("摄像头会话已启动")
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    func startSession() {
        session?.startRunning()
    }
    
    func stopSession() {
        session?.stopRunning()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraPreviewUIView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.didOutput(sampleBuffer: sampleBuffer)
    }
}