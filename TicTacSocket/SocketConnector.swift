import CocoaAsyncSocket
import RxSwift

protocol SocketConnectorDelegate: class {
    func connectorDidDetectService(connector: SocketConnector)
    func connectorDidResolveAddress(connector: SocketConnector)
    func connectorDidConnect(connector: SocketConnector, service: NetService)
    func connectorDidReceive(json: [String: Any])
}

@objc class SocketConnector: NSObject, NetServiceDelegate, NetServiceBrowserDelegate, GCDAsyncSocketDelegate, SocketHandler {
    var serviceBrowser = NetServiceBrowser()
    var services = [NetService]()
    var service: NetService?
    var socket: GCDAsyncSocket?
    weak var delegate: SocketConnectorDelegate?
    private var jsonMessage: Variable<[String: Any]> = Variable([:])

    func startBrowsing() {
        services = []
        serviceBrowser.delegate = self
        serviceBrowser.searchForServices(ofType: "_http._tcp", inDomain: "local.")
    }

    func send(packet: Packet) {
        socket?.send(packet: packet, tag: 0)
    }

    func messageObservable() -> Observable<[String : Any]> {
        return jsonMessage.asObservable()
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
            socket = newSocket
            tryConnecting(newSocket, onComplete: onComplete)
        }
    }

    // MARK: NetServiceDelegate

    func netServiceDidResolveAddress(_ sender: NetService) {
        if let addresses = sender.addresses, addresses.count > 0 {
            for address in addresses {
                let data = address as NSData

                let inetAddress: sockaddr_in = data.castToCPointer()
                if inetAddress.sin_family == __uint8_t(AF_INET) {
                    if let ip = String(cString: inet_ntoa(inetAddress.sin_addr), encoding: .utf8) {
                        // IPv4
                        print(ip)
                    }
                } else if inetAddress.sin_family == __uint8_t(AF_INET6) {
                    let inetAddress6: sockaddr_in6 = data.castToCPointer()
                    let ipStringBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
                    var addr = inetAddress6.sin6_addr

                    if let ipString = inet_ntop(Int32(inetAddress6.sin6_family), &addr, ipStringBuffer, __uint32_t(INET6_ADDRSTRLEN)) {
                        if let ip = String(cString: ipString, encoding: .utf8) {
                            // IPv6
                            print(ip)
                        }
                    }
                    
                    ipStringBuffer.deallocate(capacity: Int(INET6_ADDRSTRLEN))
                }
            }
        }


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

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("STOPPED")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        print(domainString)
    }

    // MARK: GCDAsyncSocket

    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("Connected to host: \(host) on port \(port)")
        socket?.readData(toLength: UInt(MemoryLayout.size(ofValue: Int())),
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
                jsonMessage.value = json
            }
            socket?.readData(toLength: UInt(MemoryLayout.size(ofValue: Int())), withTimeout: -1,  tag: 1)
        default: break
        }
    }
}

extension NSData {
    func castToCPointer<T>() -> T {
        let mem = UnsafeMutablePointer<T>.allocate(capacity: MemoryLayout<T.Type>.size)
        self.getBytes(mem, length: MemoryLayout<T.Type>.size)
        return mem.move()
    }
}
