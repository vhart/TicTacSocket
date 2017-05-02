import CocoaAsyncSocket

protocol SocketConnectorDelegate {
    func connectorDidDetectService(connector: SocketConnector)
    func connectorDidResolveAddress(connector: SocketConnector)
    func connectorDidConnect(connector: SocketConnector, service: NetService)
    func connectorDidReceive(json: [String: Any])
}

@objc class SocketConnector: NSObject, NetServiceDelegate, NetServiceBrowserDelegate, GCDAsyncSocketDelegate {
    var serviceBrowser = NetServiceBrowser()
    var services = [NetService]()
    var service: NetService?
    var socket: GCDAsyncSocket?
    var delegate: SocketConnectorDelegate?

    func startBrowsing() {
        services = []
        serviceBrowser.delegate = self
        serviceBrowser.searchForServices(ofType: "_tutorial._tcp", inDomain: "local.")
    }

    func send(packet: Packet) {
        socket?.send(packet: packet, tag: 0)
    }

    func resolveAddress(of service: NetService) {
        self.service = service
        service.delegate = self
        service.resolve(withTimeout: 30.0)
    }

    func connect(to service: NetService, onComplete: @escaping (Bool) -> Void) {
        var isConnected = false

        guard let addresses = service.addresses
            else { onComplete(false); return }

        func tryConnecting(_ socket: GCDAsyncSocket, onComplete: ((Bool) -> Void)) {
            connectLoop: for address in addresses {
                do {
                    try socket.connect(toAddress: address)
                    onComplete(true)
                    break connectLoop
                } catch {
                    print("Failed to connect")
                    onComplete(false)
                }
            }
        }

        if let currentSocket = socket {
            if currentSocket.isConnected {
                isConnected = true
            } else {
                tryConnecting(currentSocket, onComplete:onComplete)
            }
        } else {
            let newSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
            tryConnecting(newSocket, onComplete: onComplete)
            socket = newSocket
        }
    }

    // MARK: NetServiceDelegate

    func netServiceDidResolveAddress(_ sender: NetService) {
        connect(to: sender) { [weak self] status in
            switch status {
            case true:
                guard let strongSelf = self else { return }
                print("Did connect to service")
                sender.delegate = strongSelf
                strongSelf.delegate?.connectorDidConnect(connector: strongSelf,
                                                         service: sender)
            case false: print("Error connecting to service")
            }
        }
    }
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print(errorDict)
        self.service?.delegate = nil
        self.service = nil
    }

    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        if let json = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] {
            delegate?.connectorDidReceive(json: json)
        }
    }
    // MARK: NetServiceBrowserDelegate

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.append(service)
        delegate?.connectorDidDetectService(connector: self)
    }

    // MARK: GCDAsyncSocket

    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("Connected to host: \(host) on port \(port)")
        socket?.readData(toLength: UInt(MemoryLayout.size(ofValue: Int())
            ),
                         withTimeout: -1,
                         tag: 1)
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        switch tag {
        case 1:
            let receiveBuffer = data.bufferedBytes()
            let bodyLength = Int(buffer: receiveBuffer)
            socket?.readData(toLength: UInt(bodyLength), withTimeout: -1, tag: 2)
        case 2:
            if let json = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] {
                delegate?.connectorDidReceive(json: json)
            }
            socket?.readData(toLength: UInt(MemoryLayout.size(ofValue: Int())), withTimeout: -1,  tag: 1)
        default: break
        }
    }
}
