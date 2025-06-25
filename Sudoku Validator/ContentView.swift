import SwiftUI

struct ContentView: View{
    // A sample of a correctly solved Sudoku board which will be used for testing
    let sampleBoard: [[Int]] = [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9]
    ]
    
    // @State is a special property wrapper that tells SwiftUI to watch this variable
    // If 'validationMessage' changes, the UI will automatically update itself
    @State private var validationMessage: String = "Ready to validate."
    
    var body: some View{
        // VStack arranges views vertically
        VStack(spacing: 30){
            Text("Sudoku Validator")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // This Text view displays the @State variable
            Text(validationMessage)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0))
                .foregroundStyle(.black)
                .padding()
                .background(Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // The button that will trigger the logic
            Button("Validate Sample Board"){
                // This code runs when the button is tapped
                
                // Creates an instance of our validator
                let validator = SudokuValidator()
                
                // Runs the validation function on the sample board
                let isCorrect = validator.isValid(board: sampleBoard)
                
                // Updates the message based on the result
                // Since 'validationMessage' is a @State variable, the UI will chnage
                if isCorrect{
                    validationMessage = "Correct!"
                }
                else{
                    validationMessage = "Incorrect! Check the board."
                }
            }
            .font(.title)
            .padding()
            .background(Color.gray)
            .foregroundStyle(.black)
            .clipShape(Capsule())
        }
        .padding()
    }
}

// Generates the preview in Xcode
#Preview{
    ContentView()
}
