import UIKit
import Cartography
import RxSwift

class GameViewController: UIViewController {

    enum GameState {
        case unstarted
        case waiting
        case active
        case ended

        var description: String {
            switch self {
            case .unstarted: return ""
            case .waiting: return "Waiting"
            case .active: return "Your Turn"
            case .ended: return "Game Over"
            }
        }
    }

    @IBOutlet weak var gameStateLabel: UILabel!

    var boardViewModel: BoardViewModel!
    var size: Int!
    var board: Board?
    var mark: Mark!
    var socketHandler: SocketHandler!
    private var disposeBag = DisposeBag()

    private var gameState = GameState.unstarted {
        didSet {
            switch gameState {
            case .unstarted, .waiting, .ended:
                board?.isUserInteractionEnabled = false

            case .active:
                board?.isUserInteractionEnabled = true
            }
            gameStateLabel.text = gameState.description
        }
    }

    static func fromStoryboard(with socketHandler: SocketHandler, mark: Mark, size: Int) -> GameViewController {
        let gameVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
        gameVC.mark = mark
        gameVC.size = size
        gameVC.socketHandler = socketHandler

        return gameVC
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let width = view.frame.width

        boardViewModel = BoardViewModel(size: size)

        board = Board(frame: CGRect(x: 0, y: 120,
                                    width: width, height: width))
        view.addSubview(board!)

        if mark == .x {
            gameState = .active
        }

        setUpListener()

        board?.onButtonTapped = { [weak self] button in
            guard let strongSelf = self else { return }

            strongSelf.gameState = .waiting

            let row = button.tag / strongSelf.size
            let col = button.tag % strongSelf.size

            strongSelf.boardViewModel
                .updateBoard(row: row,
                             col: col,
                             mark: strongSelf.mark)

            strongSelf.update(button: button)
            
            let location = Location(row: row, col: col)
            strongSelf.socketHandler.send(packet: location)
        }
    }

    func setUpListener() {
        socketHandler.messageObservable()
            .subscribe { [weak self] event in
                guard let json = event.element,
                    let strongSelf = self
                    else { return }
                if let location = Location(json: json) {
                    let mark: Mark = strongSelf.mark == .o ? .x : .o
                    strongSelf.boardViewModel
                        .updateBoard(location: location,
                                     mark: mark)

                    DispatchQueue.executeOnMainThread { [weak self] in
                        if let button = self?.board?.buttons[location.row][location.col] {
                            self?.update(button: button)
                        }
                        self?.gameState = .active
                    }
                }
            }.addDisposableTo(disposeBag)
    }

    func update(button: UIButton) {
        let title = boardViewModel
            .buttonTitle(forTag: button.tag)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.backgroundColor = .clear
        button.isEnabled = false
    }
}
