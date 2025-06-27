import Foundation
import Vision
import UIKit

// A helper struct that holds a recognized digit and its position
struct RecognizedDigit{
    let text: String
    let boundingBox: CGRect
}

class GridProcessor{
    // Takes the raw observations from Vision
    func process(observations: [VNRecognizedTextObservation], in frame: CGRect) -> [[Int]]{
        // Converts Vision observations to our custom struct and filter out non-digits
        let recognizedDigits = observations.compactMap{ observation -> RecognizedDigit? in
            guard let topCandidate = observation.topCandidates(1).first,
                  // Ensures the recognized text is a single digit from 1-9
                  let digit = Int(topCandidate.string),
                  (1...9).contains(digit) else{
                return nil
            }
            
            // Converts the Vision bounding box (normalized, bottom-left origin) to UIKit coordinates (pixels, top-left origin)
            let boundingBox = VNImageRectForNormalizedRect(observation.boundingBox, Int(frame.width), Int(frame.height))
            
            return RecognizedDigit(text: topCandidate.string, boundingBox: boundingBox)
        }
        
        // Returns an empty board if no valid digits are found
        guard !recognizedDigits.isEmpty else{
            return Array(repeating: Array(repeating: 0, count: 9), count: 9)
        }
        
        // Sorts the digits into a grid like structure
        // First, sorts by y coordinates to group them into rows
        // Then, sorts by x coordinates within each row
        let sortedDigits = recognizedDigits.sorted{ (digit1, digit2) -> Bool in
            // Uses a tolerance for y coordinate comparison to account for slight skews
            // If two digits are on roughly the same y level, they're considered in the same row
            let yTolerance = digit1.boundingBox.height / 2
            
            if abs(digit1.boundingBox.midY - digit2.boundingBox.midY) < yTolerance{
                // Sorts by their x position if they're in the same row
                return digit1.boundingBox.midX < digit2.boundingBox.midX
            }
            
            // Otherwise, sorts by their y position
            return digit1.boundingBox.midY < digit2.boundingBox.midY
        }
        
        // Builds the 9x9 integer grid from the sorted digits
        // Assumes a reasonable complete grid has been found
        var sudokuGrid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        // Assumes it fills the frame
        let gridSquareSize = frame.width / 9
        
        for digit in sortedDigits{
            // Determines the row and column by the digit's position
            let rowIndex = Int(digit.boundingBox.midY / gridSquareSize)
            let colIndex = Int(digit.boundingBox.midX / gridSquareSize)
            
            if(0...8).contains(rowIndex) && (0...8).contains(colIndex){
                sudokuGrid[rowIndex][colIndex] = Int(digit.text) ?? 0
            }
        }
        
        return sudokuGrid
    }
}
