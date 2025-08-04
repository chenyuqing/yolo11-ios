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
    private var currentInput: AVCaptureDeviceInput?
    private var isUsingWideAngle = false
    
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
        
        // 监听相机类型切换通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCameraTypeChanged(_:)),
            name: NSNotification.Name("CameraTypeChanged"),
            object: nil
        )
        
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
        
        session.beginConfiguration()
        
        // 检查设备支持的摄像头类型
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .back
        )
        
        print("可用的后置摄像头设备:")
        for device in discoverySession.devices {
            print("  - \(device.localizedName): \(device.deviceType.rawValue)")
        }
        
        // 获取合适的摄像头设备
        var targetDevice: AVCaptureDevice?
        
        if isUsingWideAngle {
            // 尝试获取超广角摄像头
            targetDevice = discoverySession.devices.first { $0.deviceType == .builtInUltraWideCamera }
            if targetDevice == nil {
                print("❌ 设备不支持超广角摄像头，使用普通广角")
                targetDevice = discoverySession.devices.first { $0.deviceType == .builtInWideAngleCamera }
            } else {
                print("✅ 切换到超广角摄像头")
            }
        } else {
            // 获取普通广角摄像头
            targetDevice = discoverySession.devices.first { $0.deviceType == .builtInWideAngleCamera }
            print("✅ 切换到普通广角摄像头")
        }
        
        guard let device = targetDevice else {
            print("❌ 无法获取目标摄像头设备")
            session.commitConfiguration()
            return
        }
        
        print("🎥 使用摄像头: \(device.localizedName) - \(device.deviceType.rawValue)")
        setupDevice(device, session: session)
        session.commitConfiguration()
        
        // 在配置完成后启动会话
        if !session.isRunning {
            print("开始摄像头会话")
            session.startRunning()
            print("摄像头会话已启动")
        }
    }
    
    private func setupDevice(_ device: AVCaptureDevice, session: AVCaptureSession) {
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            // 移除旧的输入
            if let currentInput = currentInput {
                session.removeInput(currentInput)
            }
            
            // 添加新输入到会话
            if session.canAddInput(input) {
                session.addInput(input)
                currentInput = input
            }
            
            // 只在第一次设置时添加输出
            if videoOutput == nil {
                let output = AVCaptureVideoDataOutput()
                output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                    videoOutput = output
                }
                
                // 设置为设备支持的最高质量分辨率
                if session.canSetSessionPreset(.hd4K3840x2160) {
                    session.sessionPreset = .hd4K3840x2160
                    print("🎥 使用4K分辨率: 3840x2160")
                } else if session.canSetSessionPreset(.hd1920x1080) {
                    session.sessionPreset = .hd1920x1080
                    print("🎥 使用1080p分辨率: 1920x1080")
                } else if session.canSetSessionPreset(.hd1280x720) {
                    session.sessionPreset = .hd1280x720
                    print("🎥 使用720p分辨率: 1280x720")
                } else {
                    session.sessionPreset = .high
                    print("🎥 使用设备最高质量预设")
                }
            }
            
            // 设置输出方向
            if let output = videoOutput {
                if #available(iOS 17.0, *) {
                    output.connection(with: .video)?.videoRotationAngle = 90
                } else {
                    output.connection(with: .video)?.videoOrientation = .portrait
                }
            }
            
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    @objc private func handleCameraTypeChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let isWideAngle = userInfo["isWideAngle"] as? Bool else { return }
        
        print("切换相机类型: \(isWideAngle ? "广角" : "普通")")
        self.isUsingWideAngle = isWideAngle
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 停止当前会话再重新配置
            self.session?.stopRunning()
            self.setupCaptureDevice()
        }
    }
    
    func startSession() {
        session?.startRunning()
    }
    
    func stopSession() {
        session?.stopRunning()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraPreviewUIView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.didOutput(sampleBuffer: sampleBuffer)
    }
}