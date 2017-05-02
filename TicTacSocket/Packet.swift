import Foundation

enum ObjectType: Int {
    case locationPacket = 1
}

protocol Packet {
    init?(json: [String: Any])
    var objectType: ObjectType { get }
    var toJson: [String: Any] { get }
}

extension Packet {
    func data() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self.toJson,
                                           options: [])
    }
}

final class Location: Packet {
    var objectType: ObjectType
    var row: Int
    var col: Int

    init(objectType: ObjectType, row: Int, col: Int) {
        self.objectType = objectType
        self.row = row
        self.col = col
    }

    init?(json: [String: Any]) {
        guard let objectTypeValue = json["objectType"] as? Int,
            let objectType = ObjectType(rawValue: objectTypeValue),
            let row = json["row"] as? Int,
            let col = json["col"] as? Int
            else { return nil }

        self.objectType = objectType
        self.row = row
        self.col = col
    }

    var toJson: [String : Any] {
        return ["objectType": objectType.rawValue, "row": row, "col": col]
    }
}

