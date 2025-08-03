
# GEMINI.md

## Project Overview

This is a real-time object detection iOS application built with SwiftUI 6 and iOS 18. It uses a YOLOv11 CoreML model to perform live object detection from the device's camera. The user interface is designed to be intuitive, displaying detection results as a real-time "bullet curtain" overlay on the camera preview.

The application consists of a home screen with a "Start Real-Time Detection" button. Tapping this button launches a full-screen camera view. The app then processes the camera feed, running the YOLOv11 model to detect objects 2-3 times per second. The labels of detected objects are displayed as banners that animate from the bottom-left of the screen, disappearing as they reach two-thirds of the way up the screen.

## Building and Running

### Prerequisites

*   Xcode 15.4+
*   An iOS device running iOS 18.0 or later

### Building the Project

To build the project, you can use the following command in your terminal:

```bash
xcodebuild -project "yolo11.xcodeproj" -scheme "yolo11" -sdk iphoneos18.0 -configuration Release
```

Alternatively, you can open the `yolo11.xcodeproj` file in Xcode and build it directly from the IDE.

### Running the Application

1.  Connect your iOS device to your Mac.
2.  In Xcode, select your device from the list of run destinations.
3.  Press `Cmd+R` or click the "Run" button to build and run the application on your device.

**Note:** The application requires camera access. Make sure to grant permission when prompted.

## Development Conventions

*   **Architecture:** The project follows the Model-View-ViewModel (MVVM) architectural pattern.
*   **State Management:** State is managed using the `@Observable` macro, a new feature in SwiftUI 6.
*   **Dependencies:** Dependencies are managed in the `Dependencies.swift` file, following a simple dependency injection pattern.
*   **Code Style:** The code adheres to the "SwiftUI 6 & iOS 18 Development规范 (2025年版)" which emphasizes the use of modern Swift and SwiftUI features.
*   **SDK:** The project includes a local Swift Package, `YOLOv11_CoreML_SDK`, which encapsulates the CoreML model and prediction logic.

