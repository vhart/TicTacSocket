import Foundation

enum PacketType: Int {
    case locationPacket = 1
}

protocol Packet {
    init?(json: [String: Any])
    var packetType: PacketType { get }
    var toJson: [String: Any] { get }
}

extension Packet {
    func data() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self.toJson,
                                           options: [])
    }
}
