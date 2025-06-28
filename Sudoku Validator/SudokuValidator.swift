import Foundation

// Defines an enum for more descriptive validation results
enum SudokuValidationResult{
    case validAndComplete
    case validAndIncomplete
    case invalid
}

struct SudokuValidator{
    // Returns the new enum
    func validate(board: [[Int]]) -> SudokuValidationResult{
        let hasNoDuplicates = areRowsValid(board: board) && areColumnsValid(board: board) && areSquaresValid(board: board)
        
        if !hasNoDuplicates{
            return .invalid
        }
        
        // Checks if there are any empty cells
        let isBoardComplete = !board.flatMap { $0 }.contains(0)
        
        if isBoardComplete{
            return .validAndComplete
        }
        else{
            return .validAndIncomplete
        }
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
    private func isSetValid(_ set: [Int]) -> Bool {
        var seen: Set<Int> = []
        for number in set {
            if number != 0 {
                if seen.contains(number) {
                    // Found a duplicate non-zero number
                    return false
                }
                seen.insert(number)
            }
        }
        // No duplicates found
        return true
    }
}
