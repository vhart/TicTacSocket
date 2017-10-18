import UIKit
import Cartography

class Board: UIView {

    var buttons = [[UIButton]]()
    var closeButton: UIButton?

    var onButtonTapped: ((UIButton) -> Void)?
    var onCloseTapped: (() -> Void)?

    private let dimension: CGFloat = 50
    private let margin: CGFloat = 10
    private var strikeThroughView: UIView?
    private var strikeThrough: CAShapeLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    func setUp() {
        for i in 0 ..< 3 {
            let yOffset = CGFloat(i) * (dimension + margin) + margin
            let leftButton = UIButton()
            let midButton = UIButton()
            let rightButton = UIButton()

            let rowOfButtons = [leftButton, midButton, rightButton]

            leftButton.tag = i * 3
            midButton.tag = i * 3 + 1
            rightButton.tag = i * 3 + 2

            for button in rowOfButtons {
                button.backgroundColor = .gray
                button.addTarget(self,
                                 action: #selector(onButtonTapped(button:)),
                                 for: .touchUpInside)
            }
            buttons.append(rowOfButtons)

            self.addSubview(leftButton)
            self.addSubview(midButton)
            self.addSubview(rightButton)

            constrain(leftButton, midButton, rightButton, self){ (lB, mB, rB, board) in
                for layout in [lB, mB, rB] {
                    layout.width == dimension
                    layout.height == dimension
                }
                mB.centerX == board.centerX
                mB.top == board.top + yOffset
                lB.top == mB.top
                rB.top == mB.top

                lB.right == mB.left - margin
                rB.left == mB.right + margin
            }
        }
    }

    func addCloseButton(onTap: @escaping () -> Void) {
        guard closeButton == nil else { return }
        let close = UIButton()
        addSubview(close)
        onCloseTapped = onTap
        close.addTarget(self,
                        action: #selector(callCloseBlock),
                        for: .touchUpInside)
        close.backgroundColor = .red

        constrain(close, self) { closeButton, board in
            closeButton.width == dimension
            closeButton.height == dimension
            closeButton.right == board.right - margin
            closeButton.top == board.top + margin
        }
    }

    func drawStrikeFrom(start: Location, end: Location) {
        enum StrikeType {
            case horizontal
            case vertical
            case diagonal
        }
        let type: StrikeType
        if start.row == end.row {
            type = .horizontal
        } else if start.col == end.col {
            type = .vertical
        } else {
            type = .diagonal
        }

        guard let startButton = buttons.safeIndex(start.row)?
            .safeIndex(start.col),
            let endButton = buttons.safeIndex(end.row)?
                .safeIndex(end.col)
            else { return }
        let startPoint: CGPoint
        let endPoint: CGPoint

        switch type {
        case .horizontal:
            startPoint = CGPoint(x: startButton.frame.minX,
                                 y: startButton.center.y)
            endPoint = CGPoint(x: endButton.frame.maxX,
                               y: endButton.center.y)
        case .vertical:
            startPoint = CGPoint(x: startButton.center.x,
                                 y: startButton.frame.minY)
            endPoint = CGPoint(x: endButton.center.x,
                               y: endButton.frame.maxY)
        case .diagonal:
            startPoint = CGPoint(x: startButton.frame.minX,
                                 y: startButton.frame.minY)
            endPoint = CGPoint(x: endButton.frame.maxX,
                               y: endButton.frame.maxY)
        }

        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)

        let line = CAShapeLayer()
        line.path = path.cgPath
        line.frame = self.bounds
        line.lineWidth = 2.0
        line.strokeColor = UIColor.blue.cgColor
        strikeThrough = line
        layer.addSublayer(line)

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            self?.strikeThrough?.strokeStart = 0
            self?.strikeThrough?.strokeEnd = 1
        }
    }

    @objc fileprivate func callCloseBlock() {
        onCloseTapped?()
    }

    func onButtonTapped(button: UIButton) {
        onButtonTapped?(button)
    }
}
