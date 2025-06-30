import Foundation // Fundamental data types and collections
import Vision
import UIKit // Core infrastructure for IOS apps

// Responsible for processing the image to find the Sudoku grid
class GridProcessor{
    // Returns a 2D array of integers representing the Sudoku grid
    // or throws an error
    func process(image: UIImage, log: @escaping (String) -> Void) async throws -> [[Int]]{
        // Sends the first log message back to the UI
        log("GridProcessor: Starting.")
        guard let cgImage = image.cgImage else{
            log("GridProcessor: ERROR - Failed to create CGImage.")
            throw ProcessingError.cgImageError
        }

        // Logs the next step in the process
        log("GridProcessor: Assuming puzzle fills image. Slicing into 81 cells...")
        
        // Initializes an empty 9x9 grid
        // filling it with 0s
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        // Defines a rectangle that covers the entire image area in pixel coordinates
        let imageRect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let cellWidth = imageRect.width / 9
        let cellHeight = imageRect.height / 9

        // A sequential loop over an asynchronous task
        // Processes each cell one by one
        for row in 0..<9{
            for col in 0..<9{
                log("Processing cell (\(row), \(col))...")
                
                // Calculates the exact pixel rectangle for the current cell based on its row and column
                let cellRect = CGRect(x: CGFloat(col) * cellWidth, y: CGFloat(row) * cellHeight, width: cellWidth, height: cellHeight)
                // Shrinks the cell rectangle slightly to create an inset
                // So the OCR avoids seeing the Sudoku grid lines
                let insetRect = cellRect.insetBy(dx: cellWidth * 0.2, dy: cellHeight * 0.2)

                // Attemps to crop the main image to just the tiny inset rectangle of the current cell
                guard let cellImage = cgImage.cropping(to: insetRect) else{
                    // Logs a warning and skips to the next iteration of the loop if cropping fails
                    log("Warning: Could not crop cell (\(row), \(col)).")
                    continue // Skip this cell if cropping fails
                }

                // Awaits the result of the OCR for the single cell
                let digit = await recognizeText(in: cellImage)
                // Places the recognized digit into the correct position in the grid
                grid[row][col] = digit
            }
        }
        
        // Logs the completion and returns the final grid after all 81 cells have been processed
        log("GridProcessor: All cells processed.")
        return grid
    }

    // Performs OCR on one small image
    private func recognizeText(in cgImage: CGImage) async -> Int{
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        // Not looking for real words
        request.usesLanguageCorrection = false
        // Tells Vision to only consider these specifc strings as valid results
        request.customWords = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

        // Performs the OCR on the provided small cell image
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)

        // Bridges older, completion handler based APIs with async/await
        return await withCheckedContinuation{ continuation in
            do{
                try requestHandler.perform([request])
                if let mostLikely = request.results?.first?.topCandidates(1).first,
                   let digit = Int(mostLikely.string){
                    continuation.resume(returning: digit)
                }
                else{
                    continuation.resume(returning: 0)
                }
            }
            catch{
                continuation.resume(returning: 0)
            }
        }
    }
    
    // Allows for more specific error handling
    enum ProcessingError: Error, LocalizedError{
        // If UIImage can't be converted to CGImage
        case cgImageError
        // Human readable description for each error case
        var errorDescription: String?{
            "Could not convert image to a processable format."
        }
    }
}
