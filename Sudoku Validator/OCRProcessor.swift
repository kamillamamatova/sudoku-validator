import Foundation
import Vision
import UIKit

class OCRProcessor{
    // Takes a UIImage and uses the Vision framework to find text in it
    // Then calls a completion handler with the results
    func processImage(_ image: UIImage, completion: @escaping ([VNRecognizedTextObservation]) -> Void){
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
            
            // Calls the main completion handler with the results
            completion(observations)
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
