import Foundation

struct PacketDataDelimiter {
    static var delimiterData: Data {
        // using hex '&' value as delimiter
        let buffer: [UInt8] = [0x26]
        return Data(bytes: buffer)
    }
}
