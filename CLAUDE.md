# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a real-time object detection iOS application built with SwiftUI 6 and iOS 18. The app uses YOLOv11 CoreML model to perform live object detection from the device's camera with detection results displayed as animated banners.

## Build and Development Commands

### Building the Project
```bash
# Build for device (iOS 18.5+)
xcodebuild -project "yolo11.xcodeproj" -scheme "yolo11" -sdk iphoneos18.5 -configuration Release

# Build for simulator  
xcodebuild -project "yolo11.xcodeproj" -scheme "yolo11" -sdk iphonesimulator -configuration Debug
```

### Running Tests
```bash
# Run unit tests
xcodebuild test -project "yolo11.xcodeproj" -scheme "yolo11" -destination "platform=iOS Simulator,name=iPhone 15"

# Run UI tests
xcodebuild test -project "yolo11.xcodeproj" -scheme "yolo11" -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:yolo11UITests
```

### Development Commands
- Use Xcode 15.4+ for development
- Target iOS 18.0+ deployment
- Camera permissions required for device testing

## Architecture Overview

### MVVM Pattern with SwiftUI 6
- **Models**: `DetectionResult` for detection data structures
- **ViewModels**: Observable classes using `@Observable` macro (iOS 18 requirement)
- **Views**: SwiftUI 6 views with modern navigation using `NavigationStack`

### Core Components Architecture

#### 1. YOLOv11_CoreML_SDK (Local Swift Package)
- **Location**: `/YOLOv11_CoreML_SDK/`
- **Purpose**: Encapsulates CoreML model and prediction logic
- **Key Files**:
  - `YOLOv11Predictor.swift`: Main prediction class using Vision framework
  - `Resources/yolo11n.mlpackage`: Pre-trained YOLOv11 CoreML model
- **Usage**: Performs async object detection on CGImage inputs

#### 2. Camera System
- **CameraViewModel**: Handles camera capture and detection coordination
  - Uses `AVFoundation` for camera access
  - Implements `CameraPreviewDelegate` for frame processing
  - Controls detection frequency (0.3s intervals)
  - Manages detection results and banner display
- **CameraView**: SwiftUI view with camera preview and detection overlays

#### 3. Detection Pipeline
1. Camera captures frames via `AVCaptureSession`
2. `CameraViewModel.didOutput(sampleBuffer:)` processes frames
3. Vision framework (`VNImageRequestHandler`) handles model inference
4. Results converted to `DetectionResult` structs
5. Banner animations triggered on main thread

#### 4. State Management
- Uses `@Observable` macro (SwiftUI 6 requirement)
- `Dependencies.swift`: Centralized dependency injection (currently minimal)
- Published properties for reactive UI updates

### Key Architectural Patterns

#### Detection Result Flow
```
AVCaptureSession → CMSampleBuffer → VNImageRequestHandler → VNCoreMLRequest → VNRecognizedObjectObservation → DetectionResult → Banner Animation
```

#### Navigation Structure
- `HomeView`: Entry point with "Start Detection" button
- `CameraView`: Full-screen camera with real-time detection
- Uses `NavigationStack` for iOS 18 navigation

#### Performance Optimizations
- Background thread processing for model inference
- Frame rate limiting (2-3 FPS detection)
- Banner result count limiting (max 30 items)
- Memory-conscious image processing

## Development Conventions

### SwiftUI 6 & iOS 18 Requirements
- Minimum deployment target: iOS 18.0
- Use `@Observable` macro instead of `ObservableObject`
- NavigationStack over deprecated navigation APIs
- Modern Swift concurrency (async/await) in YOLOv11Predictor

### Model Integration Notes
- YOLOv11 model expects specific input image format
- Model file must be in `.mlpackage` format for iOS 18
- Vision framework handles model compilation and caching
- Confidence threshold filtering available in observation processing

### Testing Strategy
- Device testing required for camera functionality
- Simulator testing limited (no camera access)
- UI tests focus on navigation flow
- Unit tests for detection result processing

## Important Files and Locations

### Core Implementation Files
- `yolo11/Features/Camera/ViewModels/CameraViewModel.swift`: Main detection logic
- `yolo11/Features/Camera/Views/CameraView.swift`: Camera UI
- `YOLOv11_CoreML_SDK/Sources/YOLOv11CoreMLSDK/YOLOv11Predictor.swift`: Model interface

### Model and Resources
- `YOLOv11_CoreML_SDK/Sources/YOLOv11CoreMLSDK/Resources/yolo11n.mlpackage`: CoreML model
- Model loading handled in both CameraViewModel and YOLOv11Predictor

### Project Structure
```
yolo11/
├── App/                          # App entry point and dependencies
├── Features/                     # Feature-based organization
│   ├── Home/                     # Home screen
│   └── Camera/                   # Camera and detection
│       ├── Models/               # Detection data models
│       ├── ViewModels/           # Camera business logic
│       └── Views/                # Camera UI components
├── Shared/                       # Shared components and extensions
└── YOLOv11_CoreML_SDK/          # Local Swift package for ML model
```

## Common Development Tasks

### Adding New Detection Features
1. Modify `DetectionResult` model if new data fields needed
2. Update `YOLOv11Predictor.performPrediction` for additional processing
3. Enhance `CameraViewModel.processObservations` for new result handling
4. Update UI components in `CameraView` as needed

### Performance Tuning
- Adjust `minDetectionInterval` in CameraViewModel for detection frequency
- Modify banner count limit in `addDetectionResultForBanner`
- Consider model optimization (quantization, pruning) for faster inference

### Camera Configuration
- Camera settings managed in CameraViewModel initialization
- Permission handling integrated into camera startup flow
- Support for front/back camera switching can be added to CameraViewModel