import Foundation
import Vision
import UIKit

class GridProcessor {
    func process(image: UIImage, completion: @escaping ([[Int]]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        
        let request = VNRecognizeTextRequest { (request, error) in
            var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
            
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion(grid)
                return
            }

            let frame = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
            let cellWidth = frame.width / 9.0
            let cellHeight = frame.height / 9.0

            for observation in observations {
                guard let candidate = observation.topCandidates(1).first,
                      let digit = Int(candidate.string) else { continue }

                let boundingBox = VNImageRectForNormalizedRect(observation.boundingBox, Int(frame.width), Int(frame.height))
                let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)

                let col = Int(center.x / cellWidth)
                let row = 8 - Int(center.y / cellHeight)

                if row >= 0 && row < 9 && col >= 0 && col < 9 {
                    if grid[row][col] == 0 {
                        grid[row][col] = digit
                    }
                }
            }
            completion(grid)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        // This setting is crucial to force the recognizer to find small, individual digits.
        request.minimumTextHeight = 0.015
        request.customWords = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

        do {
            try requestHandler.perform([request])
        } catch {
            completion(Array(repeating: Array(repeating: 0, count: 9), count: 9))
        }
    }
}
