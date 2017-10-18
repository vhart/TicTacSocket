import RxSwift

class BoardViewModel {
    let size: Int
    let winnersPath = PublishSubject<(mark: Mark, path: (start: Location, end: Location))>()
    private let boardModel: BoardModel
    private let disposeBag = DisposeBag()

    init?(size: Int) {
        guard let boardModel = BoardModel(size: size)
            else { return nil }
        self.size = size
        self.boardModel = boardModel
        setUpObservers()
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

    private func setUpObservers() {
        boardModel.winner
            .asObservable()
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] winningMark in
                guard let path = self?.boardModel.winningPath() else { return }
                self?.winnersPath.onNext((mark: winningMark, path: path))
            }).addDisposableTo(disposeBag)
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
