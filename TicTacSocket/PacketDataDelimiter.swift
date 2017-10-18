import Foundation

struct PacketDataDelimiter {
    static var delimiterData: Data {
        // using hex '&' value as delimiter
        let buffer: [UInt8] = [0x26]
        return Data(bytes: buffer)
    }

    static func stripDelimiter(from data: Data) -> Data? {
        guard data.count != 0 else { return nil }
        let delimiterCount = delimiterData.count
        return data.subdata(in: Range<Int>(uncheckedBounds:
            (0, data.count - delimiterCount)))
    }
}
