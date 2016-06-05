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
//    func foundPeer()
//    func lostPeer()
//    func invitationWasReceived(fromPeer: String)
    func timeDataChanged(data: TimeData)
    
}

class TimeServiceManager: NSObject {
    
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    let serviceType = "timer-countdown"
    let peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
    let advertiser:MCNearbyServiceAdvertiser
//    let browser:MCNearbyServiceBrowser
    
    var foundPeers = [MCPeerID]()
    var invitationHandler: ((Bool, MCSession)->Void)!
    
    var delegate: TimeServiceManagerDelegate?
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        session.delegate = self
        return session
    }()
    
    override init() {
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
//        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        super.init()
        self.advertiser.delegate = self
        self.advertiser.startAdvertisingPeer()
//        self.browser.delegate = self
//        self.browser.startBrowsingForPeers()
    }
    
    deinit {
        self.advertiser.stopAdvertisingPeer()
//        self.browser.stopBrowsingForPeers()
    }

}

extension TimeServiceManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                                    withContext context: NSData?,
                                    invitationHandler: (Bool, MCSession) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
//        self.invitationHandler = invitationHandler
//        delegate?.invitationWasReceived(peerID.displayName)
    }
}

extension TimeServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(browser: MCNearbyServiceBrowser,
                   foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        foundPeers.append(peerID)
//        delegate?.foundPeer()
//        NSLog("%@", "invitePeer: \(peerID)")
//        browser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
        for (index, aPeer) in foundPeers.enumerate() {
            if aPeer == peerID {
                foundPeers.removeAtIndex(index)
                break
            }
        }
        
//        delegate?.lostPeer()
    }
    
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch(self) {
        case .NotConnected: return "NotConnected"
        case .Connecting: return "Connecting"
        case .Connected: return "Connected"
//        default: return "Unknown"
        }
    }
    
}

extension TimeServiceManager : MCSessionDelegate {
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
}
