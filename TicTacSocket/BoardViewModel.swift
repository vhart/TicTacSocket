struct BoardViewModel {
    let size: Int
    private let boardModel: BoardModel

    init?(size: Int) {
        guard let boardModel = BoardModel(size: size)
            else { return nil }
        self.size = size
        self.boardModel = boardModel
    }

    func buttonTitle(forTag tag: Int) -> String? {
        guard let mark = mark(forTag: tag) else { return nil }
        return mark.description
    }

    func isButtonEnabled(forTag tag: Int) -> Bool {
        guard let mark = mark(forTag: tag) else { return true }
        return mark == .none
    }

    func updateBoard(location: Location, mark: Mark) {
        updateBoard(row: location.row, col: location.col, mark: mark)
    }

    func updateBoard(row: Int, col: Int, mark: Mark) {
        boardModel.update(row: row, col: col, mark: mark)
    }

    private func mark(forTag tag: Int) -> Mark? {
        let row = tag / 3
        let col = tag % 3

        guard let mark = boardModel.boardValues
            .safeIndex(row)?
            .safeIndex(col)
            else { return nil }
        return mark
    }
}
