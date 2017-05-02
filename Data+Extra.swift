import Foundation

extension Data {
    func bufferedBytes() -> [UInt8] {
        var buffer = [UInt8](repeatElement(0, count: count))
        copyBytes(to: &buffer, count: count)
        return buffer
    }
}

extension Int {
    init(buffer: [UInt8]) {
        var v: Int = 0
        for byte in buffer.reversed() {
            v = v << 8
            v = v | Int(byte)
        }
        self = v
    }
}
