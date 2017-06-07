final class Location: Packet {
    let packetType: PacketType = .locationPacket
    var row: Int
    var col: Int

    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    init?(json: [String: Any]) {
        guard let objectTypeValue = json["objectType"] as? Int,
            objectTypeValue == PacketType.locationPacket.rawValue,
            let row = json["row"] as? Int,
            let col = json["col"] as? Int
            else { return nil }

        self.row = row
        self.col = col
    }

    var toJson: [String : Any] {
        return ["objectType": packetType.rawValue,
                "row": row,
                "col": col]
    }
}

