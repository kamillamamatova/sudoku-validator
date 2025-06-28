import SwiftUI

struct ContentView: View{
    // State variable to hold the image taken by the user
    // It's an optional because there is no image at the start
    @State private var capturedImage: UIImage? = nil
    
    // State variable to control when to show the camera view
    @State private var isShowingCamera = false
    
    // State variable to hold the final validation result
    @State private var validationMessage: String = ""
    
    var body: some View{
        // VStack arranges views vertically
        VStack(spacing: 20){
            Text("Sudoku Validator")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // The there is an image, it will be displayed here
            if let image = capturedImage{
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .border(Color.gray, width: 2)
            }
            else{
                // If no image has been captured yet, this shows a placeholder
                ZStack{
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 300, height: 300)
                        .border(Color.gray, width: 2)
                    
                    Text("No image scanned")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // The button that triggers the camera
            Button("Select Sudoku Image"){
                // Clears previous validation message
                self.validationMessage = ""
                // Flips the switch to true
                self.isShowingCamera = true
            }
            .font(.title2)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            
            // This button only appears when after an image has been selected
            if capturedImage != nil{
                Button("Process Image for Numbers", action: {
                        // Makes sure there is an image to process
                        guard let imageToProcess = capturedImage else {
                            return
                        }
                    
                    self.validationMessage = "Processing..."
                    
                    let ocrProcessor = OCRProcessor()
                    
                    // Calls the processor. This happens in the background.
                    ocrProcessor.processImage(imageToProcess){ observations in
                        // Processes the observationsto build a 9x9 grid
                        let gridProcessor = GridProcessor()
                        
                        // Creates a CGRect from the image's size, with an origin at (0,0)
                        let imageFrame = CGRect(origin: .zero, size: imageToProcess.size)
                        
                        // Makes sure the image frame converts coordinates correctly
                        let grid = gridProcessor.process(observations: observations, in: imageFrame)

                        // Validates the final grid
                        let validator = SudokuValidator()
                        let result = validator.validate(board: grid)
                        
                        // Updates the UI on the main thread
                        DispatchQueue.main.async{
                            // Updates the message based on the more detailed result
                            switch result{
                            case .validAndComplete:
                                self.validationMessage = "This is a valid and complete puzzle!"
                            case .validAndIncomplete:
                                self.validationMessage = "This puzzle is valid so far, but incomplete."
                            case .invalid:
                                self.validationMessage = "This puzzle is incorrect."
                            }
                        }
                    }
                })
                .font(.title2)
                .padding()
                .background(Color.green)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                
                // Displays the final validation message
                Text(validationMessage)
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding()
            }
        }
        .padding()
        // Presents the camera view
        // Listens to the 'isShowingCamera' variable. The sheet appears when it's true
        .sheet(isPresented: $isShowingCamera){
            // Passes a 'binding' ($) to our captureImage state, so the ImagePicker can update directly
            ImagePicker(selectedImage: $capturedImage)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider{
    static var previews: some View{
        ContentView()
    }
}
#endif
