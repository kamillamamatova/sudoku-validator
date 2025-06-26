import SwiftUI

struct ContentView: View{
    // State variable to hold the image taken by the user
    // It's an optional because there is no image at the start
    @State private var capturedImage: UIImage? = nil
    
    // State variable to control when to show the camera view
    @State private var isShowingCamera = false
    
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
            Button("Scan with Camera"){
                // Flips the switch to true
                self.isShowingCamera = true
            }
            .font(.title)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(Capsule())
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

// Generates the preview in Xcode
#Preview{
    ContentView()
}
