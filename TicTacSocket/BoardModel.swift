import RxSwift

enum Mark: Int {
    case x = -1
    case o = 1
    case none = 0

    var description: String {
        switch self {
        case .x: return "X"
        case .o: return "O"
        case .none: return ""
        }
    }
}

class BoardModel {

    enum CrossSection: String {
        case row
        case column
        case diagLeftTopRightBottom
        case diagLeftBottomRightTop

        static func string(_ section: CrossSection, variation: Int) -> String {
            return "\(section.rawValue)+\(variation)"
        }
    }

    let size: Int
    var boardValues = [[Mark]]()
    var runningSums = [String: Int]()
    let winner = Variable<Mark>(.none)

    init?(size: Int) {
        guard size > 0 else { return nil }
        self.size = size

        for i in 0..<size {
            boardValues.append([Mark](repeating: .none, count: size))
            runningSums[CrossSection.string(.row, variation: i)] = 0
            runningSums[CrossSection.string(.column, variation: i)] = 0
        }

        runningSums[CrossSection.diagLeftTopRightBottom.rawValue] = 0
        runningSums[CrossSection.diagLeftBottomRightTop.rawValue] = 0
    }

    func update(row: Int, col: Int, mark: Mark) {
        let range = 0..<size
        guard range ~= row, range ~= col else { return }
        boardValues[row][col] = mark
        updateSums(row: row, col: col, mark: mark)
        winner.value = winningMark()
    }

    func winningMark() -> Mark {
        for sum in runningSums.values {
            switch sum {
            case Mark.o.rawValue * size: return .o
            case Mark.x.rawValue * size: return .x
            default: continue
            }
        }
        return .none
    }

    func winningPath() -> (start: Location, end: Location)? {
        guard winningMark() != .none else { return nil }
        var winningKey: String?
        for (key, sum) in runningSums {
            if sum == Mark.o.rawValue * size || sum == Mark.x.rawValue * size {
                winningKey = key
                break
            }
        }
        guard let sectionKey = winningKey else { return nil }

        switch sectionKey {
        case CrossSection.diagLeftBottomRightTop.rawValue:
            return (start: Location(row: size - 1, col: 0), end: Location(row: 0, col: size - 1))
        case CrossSection.diagLeftTopRightBottom.rawValue:
            return (start: Location(row: 0, col: 0), end: Location(row: size - 1, col: size - 1))
        default:
            break
        }

        let components = sectionKey.components(separatedBy: "+")

        guard components.count == 2,
            let section = components.first,
            let indexString = components.last,
            let index = Int(indexString)
            else { return nil }

        switch section {
        case CrossSection.column.rawValue:
            return (start: Location(row: 0, col: index), end: Location(row: size - 1, col: index))
        case CrossSection.row.rawValue:
            return (start: Location(row: index, col: 0), end: Location(row: index, col: size - 1))
        default:
            return nil
        }
    }

    private func updateSums(row: Int, col: Int, mark: Mark) {
        let range = 0..<size
        guard range ~= row, range ~= col else { return }
        let rowString = CrossSection.string(.row, variation: row)
        let colString = CrossSection.string(.column, variation: col)
        var keys = [rowString, colString]
        if row == col {
            keys.append(CrossSection.diagLeftTopRightBottom.rawValue)
        }
        if col == size - row - 1 {
            keys.append(CrossSection.diagLeftBottomRightTop.rawValue)
        }

        for key in keys {
            if let value = runningSums[key] {
                runningSums[key] = value + mark.rawValue
            }
        }
    }
}

extension Array {
    func safeIndex(_ i: Int) -> Element? {
        guard i < count else { return nil }
        return self[i]
    }
}
