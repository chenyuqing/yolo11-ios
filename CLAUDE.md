# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **fully functional real-time object detection iOS application** built with SwiftUI 6 and iOS 18. The app uses a YOLOv11 CoreML model to perform live object detection from the device's camera, supporting **80 COCO dataset classes** (person, car, dog, cat, etc.) with detection results displayed as animated bullet-curtain banners.

**Current Status**: Production-ready application with successful model integration, real-time detection pipeline, and optimized UI. Successfully deployed to GitHub repository at https://github.com/chenyuqing/yolo11-ios.git

### Key Features
- ✅ **Real-time YOLOv11 object detection** with NMS post-processing
- ✅ **80 COCO classes support** (person, bicycle, car, motorcycle, etc.)
- ✅ **Bullet-curtain animation** for detection results
- ✅ **Apple Neural Engine acceleration** for optimal performance  
- ✅ **SwiftUI 6 + iOS 18** modern architecture with @Observable
- ✅ **Camera permissions** and full AVFoundation integration
- ✅ **Memory optimized** with background processing
- ✅ **Direct model integration** (YOLOv11Predictor integrated into app)
- ✅ **Optimized homepage layout** with proper spacing
- 🔄 **Wide-angle camera feature** (planned for right-bottom corner)
- 🔄 **NMS threshold adjustment slider** (planned for top-right corner)

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

#### 1. YOLOv11Predictor (Direct Integration)
- **Location**: `yolo11/Shared/Services/YOLOv11Predictor.swift`
- **Purpose**: Integrated YOLOv11 CoreML model with complete NMS post-processing
- **Key Features**:
  - Direct model loading from app bundle
  - YOLO output parsing for [1, 84, 8400] format
  - Complete NMS implementation with configurable thresholds
  - COCO dataset 80 class labels
  - Apple Neural Engine acceleration
- **Usage**: Performs async object detection on CGImage with full post-processing

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
- `yolo11/Features/Camera/ViewModels/CameraViewModel.swift`: Main detection logic and camera handling
- `yolo11/Features/Camera/Views/CameraView.swift`: Camera UI with detection overlays
- `yolo11/Shared/Services/YOLOv11Predictor.swift`: Integrated model with complete NMS processing
- `yolo11/Shared/Extensions/UIViewRepresentable+.swift`: Camera preview implementation
- `yolo11/Features/Home/Views/HomeView.swift`: Optimized homepage layout

### Model and Resources
- `yolo11/Resources/yolo11n.mlpackage`: CoreML model (integrated into app bundle)
- Model loading handled directly by YOLOv11Predictor class
- Complete YOLO output processing with confidence filtering and NMS

### Project Structure
```
yolo11/
├── App/                          # App entry point and dependencies
├── Features/                     # Feature-based organization
│   ├── Home/                     # Home screen with optimized layout
│   └── Camera/                   # Camera and detection
│       ├── Models/               # Detection data models
│       ├── ViewModels/           # Camera business logic
│       └── Views/                # Camera UI components
├── Shared/                       # Shared components and extensions
│   ├── Services/                 # YOLOv11Predictor and core services
│   └── Extensions/               # UIViewRepresentable camera extensions
└── Resources/                    # Model files and assets
```

## Common Development Tasks

### Adding New Detection Features
1. Modify `DetectionResult` model if new data fields needed
2. Update `YOLOv11Predictor.performPrediction` for additional processing
3. Enhance `CameraViewModel.processDetection` for new result handling
4. Update UI components in `CameraView` as needed

### Performance Tuning
- Adjust `minDetectionInterval` in CameraViewModel for detection frequency (currently 0.3s)
- Modify banner count limit in `addDetectionResultForBanner` (currently max 30)
- NMS thresholds: IoU=0.45, Confidence=0.25 (configurable in YOLOv11Predictor)
- Model uses Apple Neural Engine with .computeUnits = .all

### Camera Configuration
- Camera settings managed in CameraPreviewUIView initialization
- HD resolution: .hd1280x720 for optimal performance
- Permission handling integrated into camera startup flow
- Support for wide-angle camera switching (planned feature)

## Current Implementation Details

### YOLO Model Integration
- **Model Format**: CoreML .mlpackage for iOS 18 compatibility
- **Input**: 640x640 RGB images (automatically resized)
- **Output**: [1, 84, 8400] format with complete post-processing
- **Classes**: Full COCO dataset 80 classes with labels
- **Performance**: ~30ms inference time on Apple Neural Engine

### Detection Pipeline Flow
1. Camera captures 1280x720 frames at 30fps
2. Frame rate limited to ~3fps for detection processing
3. YOLOv11Predictor processes CGImage with Vision framework
4. NMS post-processing filters overlapping detections
5. Results converted to DetectionResult structs
6. Bullet-curtain animations triggered on main thread

### Recent Optimizations
- Direct model integration (removed SDK dependency)
- Optimized homepage layout with proper spacing
- Complete NMS implementation for better detection quality
- Memory-efficient processing with background queues
- GitHub repository setup with clean project structure

## Planned Features (Next Development Phase)
- 🔄 Wide-angle camera toggle (bottom-right corner)
- 🔄 NMS threshold adjustment slider (top-right corner)
- 🔄 Detection info positioned at bottom-left with bullet-curtain effect
- 🔄 More compact and centered homepage layout