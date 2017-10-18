import CocoaAsyncSocket
import RxSwift

@objc class SocketBroadcaster: NSObject, GCDAsyncSocketDelegate, SocketHandler {
    let delegateQueue = DispatchQueue(label: "com.tictacsocket.broadcaster.queue")
    var service: NetService?
    var services = [NetService]()
    var connectedSocket: GCDAsyncSocket?
    var onDidAcceptNewSocket: (() -> Void)?
    private var jsonMessage = PublishSubject<[String: Any]>()

    private var socket: GCDAsyncSocket!

    override init() {
        super.init()
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue)
    }

    func broadcast() throws {
        do {
            try socket.accept(onPort: 0)
            service = NetService(domain: "local.",
                                 type: "_tutorial._tcp",
                                 name: "TicTacSocket",
                                 port: Int32(socket.localPort))
        } catch {
            print("error listing on port")
            throw NSError(domain: "broadcasting.socket",
                          code: 1,
                          userInfo: ["port": 0])
        }

        if let service = service {
            service.delegate = self
            service.publish()
        }
    }

    func send(packet: Packet) {
        connectedSocket?.send(packet: packet, tag: 0)
    }

    func messageObservable() -> Observable<[String: Any]> {
        return jsonMessage.asObservable()
    }

    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("\(#function) sock: \(sock.connectedUrl), newSocket: \(newSocket)")
        connectedSocket = newSocket
        connectedSocket?.delegate = self
        connectedSocket?.queueNextRead()
        onDidAcceptNewSocket?()
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        switch tag {
        case 1:
            if let jsonData = PacketDataDelimiter.stripDelimiter(from: data),
               let json = (try? JSONSerialization.jsonObject(with: jsonData, options: []))
                as? [String: Any] {
                jsonMessage.onNext(json)
            }
        default: break
        }
        connectedSocket?.queueNextRead()
    }
}

extension SocketBroadcaster: NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
        guard let service = service else { return }
        print("published on port \(service.port) / domain: \(service.domain) / \(service.type) / \(service.name)")
    }
}

