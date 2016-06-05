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
    func invitationWasReceived(name: String)
    func timeDataReceived(data: TimeData)
}

class TimeServiceManager: NSObject {
    
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    let serviceType = "timer-countdown"
    let peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
    let advertiser:MCNearbyServiceAdvertiser
    
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
        super.init()
        self.advertiser.delegate = self
        self.advertiser.startAdvertisingPeer()
    }
    
    deinit {
        self.advertiser.stopAdvertisingPeer()
    }
    
    func sendTimeData(data: TimeData) {
        if session.connectedPeers.count > 0 {
            do {
                try self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(data),
                                          toPeers: self.session.connectedPeers,
                                          withMode: MCSessionSendDataMode.Reliable)
            } catch _ {
                NSLog("%@", "Error, could not send data!")
            }
        }
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
        self.invitationHandler = invitationHandler
        delegate?.invitationWasReceived(peerID.displayName)
    }
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch(self) {
        case .NotConnected: return "NotConnected"
        case .Connecting: return "Connecting"
        case .Connected: return "Connected"
        }
    }
    
}

extension TimeServiceManager : MCSessionDelegate {
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        delegate?.timeDataReceived(NSKeyedUnarchiver.unarchiveObjectWithData(data) as! TimeData)
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
