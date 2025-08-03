
import Vision
import CoreML
import UIKit

// A struct to hold detection results in a clean, usable format.
public struct Detection {
    public let id = UUID()
    public let label: String
    public let confidence: Float
    public let boundingBox: CGRect
}

// The main predictor class that handles the Vision requests.
public class YOLOv11Predictor {
    
    private let model: VNCoreMLModel

    public init() {
        // Load the compiled model from the bundle.
        guard let modelURL = Bundle.module.url(forResource: "yolo11n", withExtension: "mlmodelc") else {
            fatalError("Failed to find CoreML model in the bundle.")
        }
        
        guard let coreMLModel = try? MLModel(contentsOf: modelURL) else {
            fatalError("Failed to load CoreML model.")
        }
        
        // Create a Vision model from the CoreML model.
        guard let visionModel = try? VNCoreMLModel(for: coreMLModel) else {
            fatalError("Failed to create VNCoreMLModel.")
        }
        self.model = visionModel
    }

    // Performs the prediction on a given image.
    public func performPrediction(on image: CGImage) async -> [Detection] {
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .scaleFill

        let requestHandler = VNImageRequestHandler(cgImage: image)

        return await withCheckedContinuation { continuation in
            request.completionHandler = { (request, error) in
                if let error = error {
                    print("Vision request failed with error: \(error)")
                    continuation.resume(returning: [])
                    return
                }

                guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let detections = observations.map {
                    let bestLabel = $0.labels.first! // YOLO models usually have one primary label
                    return Detection(
                        label: bestLabel.identifier,
                        confidence: bestLabel.confidence,
                        boundingBox: $0.boundingBox
                    )
                }
                continuation.resume(returning: detections)
            }

            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform Vision request: \(error)")
                continuation.resume(returning: [])
            }
        }
    }
}
