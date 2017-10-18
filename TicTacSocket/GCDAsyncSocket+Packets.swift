import CocoaAsyncSocket

extension GCDAsyncSocket {
    func send(packet: Packet, tag: Int) {
        guard var packetData = packet.data() else { return }
        packetData.append(PacketDataDelimiter.delimiterData)
        write(packetData, withTimeout: -1, tag: tag)
    }

    func queueNextRead() {
        readData(to: PacketDataDelimiter.delimiterData,
                 withTimeout: -1,
                 maxLength: 0,
                 tag: 1)
    }
}
