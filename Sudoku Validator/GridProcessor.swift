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
        
        // Groups digits into 9 row bands using y-positions
        let sortedByY = recognizedDigits.sorted { $0.center.y < $1.center.y }
        var rows: [[RecognizedDigit]] = Array(repeating: [], count: 9)
        let rowHeight = frame.height / 9
        
        for digit in sortedByY{
            let estimatedRow = Int(digit.center.y / rowHeight)
            // Clamp to 0-8
            let row = min(max(estimatedRow, 0), 8)
            rows[row].append(digit)
        }
        
        // Builds the 9x9 integer grid from the sorted digits
        // Assumes a reasonable complete grid has been found
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        let colWidth = frame.width / 9
        
        for(rowIndex, digitsInRow) in rows.enumerated(){
            // Calculates the estimated column for each digit
            for digit in digitsInRow{
                let estimatedCol = Int(digit.center.x / colWidth)
                // Clamp to 0-8
                let col = min(max(estimatedCol, 0), 8)
                
                // Places the digit in the grid at its estimated row and column
                if grid[rowIndex][col] == 0{
                    grid[rowIndex][col] = Int(digit.text) ?? 0
                }
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
