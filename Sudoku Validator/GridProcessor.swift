import Foundation
import Vision
import UIKit

// A helper struct that holds a recognized digit and its position
struct RecognizedDigit{
    let text: String
    let boundingBox: CGRect
}

class GridProcessor{
    // Takes the raw observations from Vision and return a 9x9 grid
    func process(observations: [VNRecognizedTextObservation]) -> [[Int]]{
        // Future logic
        
        // Returns an empty board, for now
        let emptyBoard = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        return emptyBoard
    }
}
