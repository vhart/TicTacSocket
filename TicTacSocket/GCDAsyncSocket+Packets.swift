import CocoaAsyncSocket

extension GCDAsyncSocket {
    func send(packet: Packet, tag: Int) {
        guard let packetData = packet.data() else { return }
        var packetLength = packetData.count
        var buffer = Data(bytes: &packetLength,
                          count: MemoryLayout<Int>.size)
        buffer.append(packetData)
        write(buffer, withTimeout: -1, tag: tag)
    }
}
