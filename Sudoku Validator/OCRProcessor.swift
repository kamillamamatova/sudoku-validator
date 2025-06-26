import Foundation
import Vision
import UIKit

class OCRProcessor{
    // Takes a UIImage and uses the Vision framework to find text in it
    // Then calls a completion handler with the results
    func processImage(_ image: UIImage, completion: @escaping ([String]) -> Void){
        // Ensures there is a valid CGImage to work with
        guard let cgImage = image.cgImage else{
            print("Failed to get CGImage from UIImage.")
            completion([])
            return
        }
        
        // Creates a new image request handler for the image
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        
        // Creates a new text recognition request
        let recognizeTextRequest = VNRecognizeTextRequest { (request, error) in
            // Completion handler for the recognition request itself
            guard let observations = request.results as? [VNRecognizedTextObservation] else{
                completion([])
                return
            }
        
            // Extracts the recognized text strings from the observation
            let recognizedStrings = observations.compactMap{ observation in
                // Returns the top candidate for recognition
                return observation.topCandidates(1).first?.string
            }
            
            // Calls the main completion handler with the results
            completion(recognizedStrings)
        }
        
        // Configures the request for more accurate results
        recognizeTextRequest.recognitionLevel = .accurate
        
        // Performs the request
        do{
            try requestHandler.perform([recognizeTextRequest])
        }
        catch{
            print("Unable to perform the request: \(error.localizedDescription)")
            completion([])
        }
    }
}
