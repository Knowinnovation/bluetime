//
//  TimeServiceManager.swift
//  KITime BT
//
//  Created by Drew Dunne on 5/30/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol TimeServiceManagerDelegate {
    func sendFullData()
    func showConnecting()
    func updateConnectionIcon(_ connected: Bool)
    func hideConnecting(_ failed: Bool)
    func invitationWasReceived(_ name: String)
    func changesReceived(_ data: Dictionary<String, AnyObject>)
}

class TimeServiceManager: NSObject {
    
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    let serviceType = "timer-countdown"
    let peerID = MCPeerID(displayName: UIDevice.current.name)
    let advertiser:MCNearbyServiceAdvertiser
    let browser:MCNearbyServiceBrowser
    
    var connected: Bool = false
    
    var invitationHandler: ((Bool, MCSession)->Void)!
    var isInvitee: (Bool, fromWhom: MCPeerID?) = (false, nil)
    
    var lastConnection: MCPeerID!
    
    var isReconnecting: Bool = false
    
    var delegate: TimeServiceManagerDelegate?
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.required)
        session.delegate = self
        return session
    }()
    
    override init() {
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        super.init()
        self.advertiser.delegate = self
        self.browser.delegate = self
        self.advertiser.startAdvertisingPeer()
    }
    
    deinit {
        self.advertiser.stopAdvertisingPeer()
    }
    
    func sendTimeData(_ data: Dictionary<String, AnyObject>) {
        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(NSKeyedArchiver.archivedData(withRootObject: data),
                                          toPeers: self.session.connectedPeers,
                                          with: MCSessionSendDataMode.reliable)
            } catch {
                NSLog("%@", "Error, could not send data!")
            }
        }
    }
    
    func attemptReconnect() {
        NSLog("Attempting Reconnect...")
        isReconnecting = true
        browser.startBrowsingForPeers()
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(TimeServiceManager.stopReconnectAttempt), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func stopReconnectAttempt() {
        browser.stopBrowsingForPeers()
    }

}

extension TimeServiceManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                                    withContext context: Data?,
                                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        if UserSettings.sharedSettings().autoAccept || isReconnecting {
            invitationHandler(true, self.session)
        } else {
            self.invitationHandler = invitationHandler
            delegate?.invitationWasReceived(peerID.displayName)
        }
        isInvitee = (true, peerID)
    }
}

extension TimeServiceManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer \(peerID)")
        if lastConnection != nil {
            if peerID.displayName.isEqual(lastConnection.displayName) {
                NSLog("%@", "Peer is last connection \(peerID)")
                browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 15)
                browser.stopBrowsingForPeers()
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer \(peerID)")
    }
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch(self) {
        case .notConnected:
            return "Not Connected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        }
    }
    
}

extension TimeServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")
        switch state {
        case .connected:
            connected = true
            delegate?.updateConnectionIcon(connected)
            isReconnecting = false
            lastConnection = peerID
            if isInvitee.0 {
                delegate?.sendFullData()
            } else {
                delegate?.hideConnecting(false)
            }
            break
        case .connecting:
            if !UserSettings.sharedSettings().autoAccept {
                delegate?.showConnecting()
            }
            break
        case .notConnected:
            connected = false
            delegate?.updateConnectionIcon(connected)
            if !UserSettings.sharedSettings().autoAccept {
                delegate?.hideConnecting(true)
            }
            if peerID.isEqual(isInvitee.fromWhom) {
                isInvitee = (false, nil)
            }
        }
        // Need to have functions for connecting and complete connecting
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        delegate?.changesReceived(NSKeyedUnarchiver.unarchiveObject(with: data) as! Dictionary<String, AnyObject>)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
}
