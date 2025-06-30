import Foundation
import Vision
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

class GridProcessor{

    // Multi pass processing
    func process(image: UIImage, completion: @escaping ([[Int]]) -> Void){
        var imageVersions: [CGImage] = []

        // Original unmodified image
        if let originalCgImage = image.cgImage{
            imageVersions.append(originalCgImage)
        }
        // Simple contrast enhanced image
        if let contrastCgImage = enhanceWithSimpleContrast(image: image)?.cgImage{
            imageVersions.append(contrastCgImage)
        }
        // High contrast monochrome image
        if let monochromeCgImage = enhanceWithMonochrome(image: image)?.cgImage{
            imageVersions.append(monochromeCgImage)
        }
        // Sharpened image
        if let sharpenedCgImage = enhanceWithSharpen(image: image)?.cgImage{
            imageVersions.append(sharpenedCgImage)
        }

        // Stores the grid results from each of the recognition passes
        var recognizedGrids: [[[Int]]] = []
        // Runs all the recognition tasks at the same time and gets a notification when they're all complete
        let dispatchGroup = DispatchGroup()
        // Prevents a scenario where multiple tasks might try to write to the 'recognizedGrids' array simultaneously
        let resultsLock = NSLock()

        // Performs text recognition on each version of the image
        for version in imageVersions{
            // Signals to the group that a new task is starting
            dispatchGroup.enter()
            // Calls the text recognition function for this specific image version
            recognizeText(in: version){ grid in
                // Acquires the lock to ensure safety before writing to the array
                resultsLock.lock()
                recognizedGrids.append(grid)
                // Releases the lock so other tasks can write their results
                resultsLock.unlock()
                // Signals to the group that this specific tasks is now finished
                dispatchGroup.leave()
            }
        }

        // Merges the results
        dispatchGroup.notify(queue: .main){
            let finalGrid = self.merge(grids: recognizedGrids)
            // Sends the completed grid back to the main UI
            completion(finalGrid)
        }
    }

    // Merges multiple grid results into one master grid
    private func merge(grids: [[[Int]]]) -> [[Int]]{
        var masterGrid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        for row in 0..<9{
            for col in 0..<9{
                for grid in grids{
                    if grid[row][col] != 0{
                        masterGrid[row][col] = grid[row][col]
                        break
                    }
                }
            }
        }
        return masterGrid
    }

    // Filters for simple contrast enhancement
    private func enhanceWithSimpleContrast(image: UIImage) -> UIImage?{
        guard let ciImage = CIImage(image: image) else{ return nil }
        let context = CIContext(options: nil)
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.contrast = 2.0
        if let outputImage = filter.outputImage, let cgImage = context.createCGImage(outputImage, from: outputImage.extent){
            return UIImage(cgImage: cgImage)
        }
        return nil
    }

    // Filters for high contrast black & white
    private func enhanceWithMonochrome(image: UIImage) -> UIImage?{
        guard let ciImage = CIImage(image: image) else{ return nil }
        let context = CIContext(options: nil)
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        // Removes all color
        filter.saturation = 0.0
        filter.contrast = 8.0
        if let outputImage = filter.outputImage, let cgImage = context.createCGImage(outputImage, from: ciImage.extent){
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    // Filters to sharpen the image
    private func enhanceWithSharpen(image: UIImage) -> UIImage?{
        guard let ciImage = CIImage(image: image) else{ return nil }
        let context = CIContext(options: nil)
        let filter = CIFilter.sharpenLuminance()
        filter.inputImage = ciImage
        filter.sharpness = 2.0 // A strong sharpen value
        if let outputImage = filter.outputImage, let cgImage = context.createCGImage(outputImage, from: outputImage.extent){
            return UIImage(cgImage: cgImage)
        }
        return nil
    }

    // Core text recognition function
    private func recognizeText(in cgImage: CGImage, completion: @escaping ([[Int]]) -> Void){
        // Performs the Vision request on the image
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        
        // Creates the text recognition request
        let request = VNRecognizeTextRequest { (request, error) in
            // Creates an empty grid to fill in with results
            var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
            // Ensures the observations have no errors
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else{
                completion(grid)
                return
            }
            
            // Gets the dimensions of the image to calculate cell positions
            let frame = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
            let cellWidth = frame.width / 9.0
            let cellHeight = frame.height / 9.0
            
            // Loops through every piece of text of the Vision framework found
            for observation in observations{
                // Gets the most likely candidate for the text
                guard let candidate = observation.topCandidates(1).first, let digit = Int(candidate.string) else{ continue }
                let boundingBox = VNImageRectForNormalizedRect(observation.boundingBox, Int(frame.width), Int(frame.height))
                let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
                let row = 8 - Int(center.y / cellHeight)
                let col = Int(center.x / cellWidth)
                if row >= 0 && row < 9 && col >= 0 && col < 9{
                    if grid[row][col] == 0{ grid[row][col] = digit }
                }
            }
            completion(grid)
        }
        
        if #available(iOS 16.0, *){ request.revision = VNRecognizeTextRequestRevision3 }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.01
        request.customWords = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
        
        DispatchQueue.global(qos: .userInitiated).async{
            do{
                try requestHandler.perform([request])
            }
            catch{
                completion(Array(repeating: Array(repeating: 0, count: 9), count: 9))
            }
        }
    }
}
