import Foundation
import Vision
import UIKit

class GridProcessor {
    
    // --- The main public function is now ASYNC and can THROW errors ---
    func process(image: UIImage, log: @escaping (String) -> Void) async throws -> [[Int]] {
        log("GridProcessor: Starting.")
        guard let cgImage = image.cgImage else {
            log("GridProcessor: ERROR - Failed to create CGImage.")
            throw ProcessingError.cgImageError
        }

        log("GridProcessor: Assuming puzzle fills image. Slicing into 81 cells...")
        
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        let imageRect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let cellWidth = imageRect.width / 9
        let cellHeight = imageRect.height / 9

        // We process each cell sequentially using async/await. This prevents the app from freezing.
        for row in 0..<9 {
            for col in 0..<9 {
                log("Processing cell (\(row), \(col))...")
                
                let cellRect = CGRect(x: CGFloat(col) * cellWidth, y: CGFloat(row) * cellHeight, width: cellWidth, height: cellHeight)
                let insetRect = cellRect.insetBy(dx: cellWidth * 0.2, dy: cellHeight * 0.2)

                guard let cellImage = cgImage.cropping(to: insetRect) else {
                    log("Warning: Could not crop cell (\(row), \(col)).")
                    continue // Skip this cell if cropping fails
                }

                // Await the result of the OCR for the single cell
                let digit = await recognizeText(in: cellImage)
                grid[row][col] = digit
            }
        }
        
        log("GridProcessor: All cells processed.")
        return grid
    }

    // --- This helper function is also async ---
    private func recognizeText(in cgImage: CGImage) async -> Int {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.customWords = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)

        return await withCheckedContinuation { continuation in
            do {
                try requestHandler.perform([request])
                if let mostLikely = request.results?.first?.topCandidates(1).first,
                   let digit = Int(mostLikely.string) {
                    continuation.resume(returning: digit)
                } else {
                    continuation.resume(returning: 0)
                }
            } catch {
                continuation.resume(returning: 0)
            }
        }
    }
    
    enum ProcessingError: Error, LocalizedError {
        case cgImageError
        var errorDescription: String? {
            "Could not convert image to a processable format."
        }
    }
}
