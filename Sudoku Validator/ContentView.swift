import SwiftUI
import Vision // Image analysis and text recognition

struct ContentView: View {
    // Holds the image the user selects from their camera or photo library
    @State private var capturedImage: UIImage? = nil
    // Controls whether the ImagePicker view is currently being shown
    @State private var isShowingCamera = false
    // Holds the final message shown to the user
    @State private var validationMessage: String = ""
    // Holds an array of strings for the on screen processing log
    @State private var ocrLog: [String] = []
    // Tracks if the OCR process is currently running
    @State private var isProcessing = false
    // Optional 2D array of integers to hold the final recognized Sudoku grid
    @State private var finalGrid: [[Int]]? = nil

    var body: some View {
        // Allows the user to scroll, so nothing gets cut off
        ScrollView {
            VStack(spacing: 15) {
                Text("Sudoku Validator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Checks if 'capturedImage' contains an actual image
                if let image = capturedImage {
                    // Creates a view to display it if an image exists
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .border(Color.gray, width: 2)
                } else {
                    ZStack {
                        Rectangle().fill(Color(.secondarySystemBackground))
                            .frame(width: 300, height: 300)
                            .border(Color.gray, width: 2)
                        Text("No image scanned").font(.headline).foregroundStyle(.secondary)
                    }
                }

                Button("Select Sudoku Image"){
                    // Runs when the button is tapped
                    // Resets the state of the app
                    self.validationMessage = ""
                    self.ocrLog = []
                    self.finalGrid = nil
                    self.isShowingCamera = true
                }
                
                // Changes the appearance of the button
                .font(.title2).padding().background(Color.blue).foregroundStyle(.white).clipShape(Capsule())

                // Only works if an image has been captured
                if capturedImage != nil{
                    Button(action:{
                        // Creates a new background task to run the image processing asynchronously
                        Task{
                            // Pauses the execution of this task until the 'processImage' function is complete
                            await processImage()
                        }
                    }) {
                        // Shows a loading indicator if it's true
                        if isProcessing {
                            // Arranges view horizontally
                            HStack {
                                ProgressView()
                                Text("Processing...")
                            }
                        } else {
                            Text("Process Image for Numbers")
                        }
                    }
                    .font(.title2).padding().background(Color.green).foregroundStyle(.white).clipShape(Capsule())
                    .disabled(isProcessing)

                    Text(validationMessage).font(.title3).fontWeight(.medium).padding(.top, 5)

                    if !ocrLog.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Processing Log:").font(.headline).padding(.bottom, 2)
                            ScrollView {
                                ForEach(ocrLog.indices, id: \.self) { index in
                                    Text(self.ocrLog[index]).font(.caption)
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                        .padding()
                    }
                    
                    // Displays the final grid if it has been generated
                    if let grid = finalGrid {
                        VStack(spacing: 2) {
                            Text("Final Processed Grid:").font(.headline).padding(.bottom, 5)
                            // Loops 9 times to create 9 cells in a row
                            ForEach(0..<9, id: \.self) { row in
                                HStack(spacing: 2) {
                                    ForEach(0..<9, id: \.self) { col in
                                        // Displays the number from the grid at the current [row][col]
                                        Text("\(grid[row][col])")
                                            .font(.system(size: 14, design: .monospaced).bold())
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(grid[row][col] == 0 ? .red : .primary)
                                            .border(Color.gray, width: 0.5)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding()
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(selectedImage: $capturedImage)
            }
        }
    }

    // Declares a function that can run asynchronously on the main thread
    @MainActor
    private func processImage() async {
        guard let image = capturedImage else { return }
        
        // Sets the app state to "processing" to update the UI
        isProcessing = true
        validationMessage = "Processing..."
        ocrLog = ["Starting process..."]
        finalGrid = nil

        // Creates an instance of the grid processing logic
        let gridProcessor = GridProcessor()
        
        // For error handling
        do {
            // 'try await' calls the asynchronours 'process' function and waits for it to return a result or throw an error
            let grid = try await gridProcessor.process(image: image, log: { message in
                // A "trailing closure" passed to the processor using it to send log messages back to the UI
                self.ocrLog.append(message)
            })
            
            // Updates the 'finalGrid' state to display the result once the processing is done
            self.finalGrid = grid
            ocrLog.append("Grid processed. Validating...")
            
            // An instance of the Sudoku validation logic
            let validator = SudokuValidator()
            // Calls the validator with the processed grid
            let validationResult = validator.validate(board: grid)
            // Handles the different validation outcomes
            switch validationResult {
            case .validAndComplete: self.validationMessage = "Puzzle is Valid & Complete!"
            case .validAndIncomplete: self.validationMessage = "Valid, but Incomplete."
            case .invalid: self.validationMessage = "Invalid Puzzle."
            }
            
        } catch {
            self.validationMessage = "Processing Failed"
            // User friendly description
            if let localizedError = error as? LocalizedError {
                self.ocrLog.append("FINAL ERROR: \(localizedError.errorDescription ?? "Unknown error")")
            }
        }
        
        // Reenables the buttons and hides the loading indicator
        isProcessing = false
    }
}
