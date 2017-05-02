import CocoaAsyncSocket

@objc class SocketService: NSObject, GCDAsyncSocketDelegate {
    let delegateQueue = DispatchQueue(label: "com.tictacsocket.app")
    var service: NetService?
    var services = [NetService]()
    var connectedSocket: GCDAsyncSocket?
    var onJsonReceived: (([String: Any]) -> ())?

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

    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("\(#function) sock: \(sock.connectedUrl), newSocket: \(newSocket)")
        connectedSocket = newSocket
        connectedSocket?.delegate = self
        connectedSocket?.readData(toLength: UInt(MemoryLayout<Int>.size), withTimeout: -1, tag: 1)
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        switch tag {
        case 1:
            let receiveBuffer = data.bufferedBytes()
            let bodyLength = Int(buffer: receiveBuffer)
            connectedSocket?.readData(toLength: UInt(bodyLength), withTimeout: -1, tag: 2)
        case 2:
            if let json = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] {
                onJsonReceived?(json)
            }
            connectedSocket?.readData(toLength: UInt(MemoryLayout<Int>.size), withTimeout: -1,  tag: 1)
        default: break
        }
    }
}

extension SocketService: NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
        guard let service = service else { return }
        print("published on port \(service.port) / domain: \(service.domain) / \(service.type) / \(service.name)")
    }
}

