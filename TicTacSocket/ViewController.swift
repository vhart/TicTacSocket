//
//  ViewController.swift
//  TicTacSocket
//
//  Created by Varinda Hart on 4/27/17.
//  Copyright © 2017 ShopKeep. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class SocketConnectivityViewController: UIViewController {

    enum Role {
        case none
        case server
        case client

        var description: String {
            switch self {
            case .none: return ""
            case .server: return "Broadcasting socket"
            case .client: return "Socket client"
            }
        }
    }

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var socketTable: UITableView!
    @IBOutlet weak var serverButton: UIButton!
    @IBOutlet weak var clientButton: UIButton!

    private(set) var connector: SocketConnector?
    private var broadcaster: SocketService?

    private(set) var role: Role = .none {
        didSet {
            statusLabel.text = role.description
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        socketTable.delegate = self
        socketTable.dataSource = self
        serverButton.layer.cornerRadius = 10
        clientButton.layer.cornerRadius = 10
        // Do any additional setup after loading the view, typically from a nib.
    }
    @IBAction func actAsServerTapped(_ sender: Any) {
        guard role != .server else { return }
        role = .server
        connector = nil
        socketTable.reloadData()
        broadcaster = SocketService()
        broadcaster?.onJsonReceived = { json in
            DispatchQueue.executeOnMainThread { [weak self] in
                guard self?.role == .server else { return }
                self?.dataLabel.text = "\(json)"
            }
        }
        do {
            try broadcaster?.broadcast()
        } catch {
            print(error)
        }
    }
    @IBAction func actAsClientTapped(_ sender: Any) {
        guard role != .client else { return }
        role = .client
        broadcaster = nil
        connector = SocketConnector()
        connector?.delegate = self
        connector?.startBrowsing()
    }

    @IBAction func sendPacketTapped(_ sender: Any) {
        let row = Int(arc4random_uniform(10))
        let col = Int(arc4random_uniform(10))
        let location = Location(objectType: .locationPacket, row: row, col: col)

        switch role {
        case .client: connector?.send(packet: location)
        case .server: broadcaster?.send(packet: location)
        case .none: break
        }
    }
}

extension SocketConnectivityViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let connector = connector else { return 0 }
        return connector.services.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServicesCell")!
        guard let connector = connector
            else { return cell }

        let service = connector.services[indexPath.row]
        cell.textLabel?.text = service.name
        cell.detailTextLabel?.text =
            service == connector.service ? "✅" : ""

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let connector = connector else { return }
        connector.resolveAddress(of: connector.services[indexPath.row])
    }
}
extension SocketConnectivityViewController: SocketConnectorDelegate {
    func connectorDidDetectService(connector: SocketConnector) {
        DispatchQueue.executeOnMainThread { [weak self] in
            self?.socketTable.reloadData()
        }
    }

    func connectorDidResolveAddress(connector: SocketConnector) {

    }

    func connectorDidConnect(connector: SocketConnector, service: NetService) {
        DispatchQueue.executeOnMainThread { [weak self] in
            self?.socketTable.reloadData()
        }
    }

    func connectorDidReceive(json: [String: Any]) {
        guard role == .client else { return }
        DispatchQueue.executeOnMainThread { [weak self] in
            self?.dataLabel.text = "\(json)"
        }
    }
}
