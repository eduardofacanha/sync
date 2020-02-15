//
//  Sync.swift
//  Sync
//
//  Created by Eduardo Façanha on 15/02/20.
//  Copyright © 2020 Eduardo Façanha. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public class Sync {
    
    public static let shared = Sync()
    
    enum connectionStatus {
        case connected, notConnected, connecting
    }
    
    private let syncManager = SyncManager(id: UUID().uuidString)
    
    public var myId: String {
        return syncManager.myPeerId.displayName
    }
    public var connectedId: String? {
        return syncManager.previousConnectedPeerId?.displayName
    }
    
    private init () { }
    
    public func send(text: String) {
        syncManager.send(text: text)
    }
    
    public func unPair() {
        syncManager.unPair()
    }
}

private class RealmManager {
    
}

private class SyncManager: NSObject {
    
    private let SyncServiceType = "Sync"
    private let TimeOut: TimeInterval = 10
    
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    private var automatic: Bool
    private var idFoundedCallBack: ((_ id: MCPeerID) -> ())?
    private var invitationCallBack: ((Bool, MCSession?) -> ())?
    
    private(set) var myPeerId: MCPeerID
    private(set) var previousConnectedPeerId: MCPeerID?
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    public init(id: String, previousConnectedId: String? = nil, autoConnection: Bool = true) {
        myPeerId = MCPeerID(displayName: id)
        
        if let previousConnectedId = previousConnectedId {
            previousConnectedPeerId = MCPeerID(displayName: previousConnectedId)
        }
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: SyncServiceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: SyncServiceType)
        
        automatic = autoConnection
        
        super.init()
        
        automatic ? startSearch() : ()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
}

extension SyncManager {
    public func startSearch() {
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    public func invite(_ peerID: MCPeerID) {
        print("invitePeer: \(peerID)")
        self.serviceBrowser.invitePeer(peerID, to: self.session, withContext: nil, timeout: TimeOut)
    }
    
    public func disconnect() {
        session.disconnect()
    }
    
    public func unPair() {
        disconnect()
        previousConnectedPeerId = nil
    }
}

extension SyncManager {
    public func send(text: String) {
        
    }
}

extension SyncManager: MCNearbyServiceAdvertiserDelegate {
    
    fileprivate func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
    
    fileprivate func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("didReceiveInvitationFromPeer \(peerID)")
        automatic ? invitationHandler(true, self.session) : (self.invitationCallBack = invitationHandler)
    }
    
}

extension SyncManager : MCNearbyServiceBrowserDelegate {
    
    fileprivate func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("didNotStartBrowsingForPeers: \(error)")
    }
    
    fileprivate func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer: \(peerID)")
        automatic ? invite(peerID) : self.idFoundedCallBack?(peerID)
    }
    
    fileprivate func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lostPeer: \(peerID)")
    }
    
}

extension SyncManager: MCSessionDelegate {
    
    fileprivate func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.rawValue)")
//        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
//            session.connectedPeers.map{$0.displayName})
    }
    
    fileprivate func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceiveData: \(data)")
//        let str = String(data: data, encoding: .utf8)!
        //        self.delegate?.colorChanged(manager: self, colorString: str)
    }
    
    fileprivate func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {
        print("didReceiveStream")
    }
    
    fileprivate func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {
        print("didStartReceivingResourceWithName")
    }
    
    fileprivate func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {
        print("didFinishReceivingResourceWithName")
    }
    
}
