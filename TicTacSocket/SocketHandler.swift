import RxSwift

protocol SocketHandler {
    func messageObservable() -> Observable<[String: Any]>
    func send(packet: Packet)
}
