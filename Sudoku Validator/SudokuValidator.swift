import Foundation

struct SudokuValidator{
    // The main function that checks the entire board
    // Has 3 helper functions to check rows, columns, and the 3x3 squares
    func isValid(board: [[Int]]) -> Bool{
        return areRowsValid(board: board) &&
            areColumnsValid(board: board) &&
            areSquaresValid(board: board)
    }
    // Checks if all the rows are valid
    private func areRowsValid(board: [[Int]]) -> Bool{
        for row in board{
            if !isSetValid(row){
                // Found an invalid row
                return false;
            }
        }
        // All rows are valid
        return true;
    }
    
    // Checks if all the cols are valid
    private func areColumnsValid(board: [[Int]]) -> Bool{
        // Transposes the board to treat columns as rows for easy checking
        for colIndex in 0..<9{
            var column: [Int] = []
            for rowIndex in 0..<9{
                column.append(board[rowIndex][colIndex])
            }
            if !isSetValid(column){
                // Found an invalid column
                return false
            }
        }
        // All columns are valid
        return true;
    }
    
    // Checks if all 3x3 squares are valid
    private func areSquaresValid(board: [[Int]]) -> Bool{
        // Iterates through the starting point of each square
        for rowOffset in stride(from: 0, to: 9, by: 3){
            for colOffset in stride(from: 0, to: 9, by: 3){
                var square: [Int] = []
                for rowIndex in 0..<3{
                    for colIndex in 0..<3{
                        square.append(board[rowOffset + rowIndex][colOffset + colIndex])
                    }
                }
                if !isSetValid(square){
                    // Found an invalid square
                    return false
                }
            }
        }
        // All squares are valid
        return true;
    }
    
    // Checks if a given array of 9 numbers is valid
    // A set is valid if it contains numbers 1-9 with no duplicates
    // 'Set' automatically handles duplicates
    private func isSetValid(_ set: [Int]) -> Bool{
        var seenNumbers = Set<Int>()
        for number in set{
            // If a number is outside the 1-9 range, it's invalid
            if number == 0{
                // Skips since 0 means empty
                continue
            }
            // If a number is a duplicate
            if seenNumbers.contains(number){
                return false
            }
            seenNumbers.insert(number)
        }
        // The set is valid if the loop is valid
        return true;
    }
}
