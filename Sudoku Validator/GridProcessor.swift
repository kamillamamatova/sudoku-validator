import Foundation
import Vision
import UIKit

// A helper struct that holds a recognized digit and its position
struct RecognizedDigit{
    let text: String
    let center: CGPoint
}

class GridProcessor{
    // Takes the raw observations from Vision
    func process(observations: [VNRecognizedTextObservation], in frame: CGRect) -> [[Int]]{
        // Converts Vision observations to our custom struct and filter out non-digits
        let recognizedDigits = observations.compactMap{ observation -> RecognizedDigit? in
            guard let candidate = observation.topCandidates(1).first,
                  // Ensures the recognized text is a single digit from 1-9
                  let digit = Int(candidate.string),
                  (1...9).contains(digit) else{
                return nil
            }
            
            // Converts the Vision bounding box (normalized, bottom-left origin) to UIKit coordinates (pixels, top-left origin)
            let boundingBox = VNImageRectForNormalizedRect(observation.boundingBox, Int(frame.width), Int(frame.height))
            let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
            
            return RecognizedDigit(text: "\(digit)", center: center)
        }
        
        // Returns an empty grid if no digits are found
        guard !recognizedDigits.isEmpty else{
            return Array(repeating: Array(repeating: 0, count: 9), count: 9)
        }
        
        // Calculates a precise bounding box around the detected digits
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude
        
        for digit in recognizedDigits{
            minX = min(minX, digit.center.x)
            minY = min(minY, digit.center.y)
            maxX = max(maxX, digit.center.x)
            maxY = max(maxY, digit.center.y)
        }
        
        let digitAreaWidth = maxX - minX
        let digitAreaHeight = maxY - minY
        
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        
        // Uses the more precise dimensions of the digit area, with a little padding
        let colWidth = digitAreaWidth / 9.0
        let rowHeight = digitAreaHeight / 9.0
        
        for digit in recognizedDigits{
            // Estimates position based on the grid
            let estimatedCol = Int((digit.center.x - minX) / colWidth)
            let estimatedRow = Int((digit.center.y - minY) / rowHeight)
            
            // Clamps to 0-8 to avoid out of bound errors
            let col = min(max(estimatedCol, 0), 8)
            let row = min(max(estimatedRow, 0), 8)
            
            // Places the digit in the grid at its estimated row and column
            if grid[row][col] == 0{
                grid[row][col] = Int(digit.text) ?? 0
            }
        }
        
        print("--- Generated Sudoku Grid ---")
        for row in grid{
            print(row)
        }
        print("---------------------------")
        
        return grid
    }
}
