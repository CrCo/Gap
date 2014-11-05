//
//  ViewController.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-23.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import SpriteKit

class ViewController: UIViewController, MeshConnectionManagerDelegate, BallSceneDelegate, MotionManagerDelegate {
    
    var me: MCPeerID {
        get {
            let def = NSUserDefaults.standardUserDefaults()
                        
            if let data = def.objectForKey("me") as NSData? {
                return NSKeyedUnarchiver.unarchiveObjectWithData(data) as MCPeerID
            } else {
                let newPeer = MCPeerID(displayName: UIDevice.currentDevice().name)
                def.setObject(NSKeyedArchiver.archivedDataWithRootObject(newPeer), forKey: "me")
                return newPeer
            }
        }
    }
    
    var receptiveToContact: Bool = false
    
    var meshConnectionManager: MeshConnectionManager!
    var spatialOrderManager: SpatialOrderManager!
    var motionManager: MotionManager!
    var scene: BallScene!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        meshConnectionManager = MeshConnectionManager(peer: me)
        meshConnectionManager.delegate = self

        spatialOrderManager = SpatialOrderManager(peerID: me)
        
        motionManager = MotionManager()
        motionManager.delegate = self
    }
    
    var alertController: UIAlertController!
    
    @IBOutlet weak var spriteView: SKView!
    
    //MARK: View delegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene = BallScene(type: .Green)
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
        scene.transferDelegate = self
        spriteView.presentScene(scene)
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
    }
    
    @IBAction func shouldSpew(sender: AnyObject) {
        scene.addNode(scene.generateRandomBall())
    }
        
    //MARK: utilities
    
    func updateSceneAfterPeerChanges() {
    }
    
    func peerForSide(side: Side) -> MCPeerID? {
        switch side {
        case .Left:
            return spatialOrderManager.leftDevice
        case .Right:
            return spatialOrderManager.rightDevice
        }
    }

    //MARK: Peer delegates
    func peer(peer: MCPeerID, sentMessage message: AnyObject) {
        switch message {
        case is BallTransferRepresentation:
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                let ball = message as BallTransferRepresentation
                
                NSLog("🎾 from \(ball.position)")
                self.scene.addNode(ball)
            }
        case is RelativeTopologyAssertionRepresentation:
            let topo = message as RelativeTopologyAssertionRepresentation
            
            spatialOrderManager.addInference(topo)
            scene.setPhysicsBodyOpenings(spatialOrderManager.leftDevice != nil, right: spatialOrderManager.rightDevice != nil)
            
            if meshConnectionManager.mode == .Listener {
                let topoRep = GlobalTopologyDefinitionRepresentation(topology: spatialOrderManager.order)
                var err: NSError?
                self.meshConnectionManager.sendMessage(topoRep, toPeers: meshConnectionManager.session.connectedPeers as [MCPeerID], error: &err)
                if let e = err {
                    NSLog("Couldn't send the mesh message")
                } else {
                    NSLog("Got some more information, now forwarding it to all")
                }
            }
        case is GlobalTopologyDefinitionRepresentation:
            NSLog("World is fully specified")

            let topo = message as GlobalTopologyDefinitionRepresentation
            
            spatialOrderManager.order = topo.topology
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.scene.setPhysicsBodyOpenings(self.spatialOrderManager.leftDevice != nil, right: self.spatialOrderManager.rightDevice != nil)
            })
        case is ContactEvent:
            if receptiveToContact {
                
                let type = (message as ContactEvent).contactSide!
                
                var topoAssertion: RelativeTopologyAssertionRepresentation
                
                switch type {
                case .Left:
                    topoAssertion = RelativeTopologyAssertionRepresentation(leftHandCandidate: me, rightHandCandidate: peer)
                case .Right:
                    topoAssertion = RelativeTopologyAssertionRepresentation(leftHandCandidate: peer, rightHandCandidate: me)
                }
                
                if let hub = meshConnectionManager.hubPeer {
                    var err: NSError?
                    self.meshConnectionManager.sendMessage(topoAssertion, toPeers: [hub], error: &err)
                    if let e = err {
                        NSLog("Couldn't send the contact event message")
                    }
                } else {
                    self.peer(me, sentMessage: topoAssertion)
                }
            }
        default:
            break
        }
    }
    
    func peerDidConnect(peer: MCPeerID) {
        let newItemCount = meshConnectionManager.session.connectedPeers.count + 1
        spatialOrderManager.addSpot(newItemCount)
        motionManager.startMotionUpdates()
    }
    
    func peerDidDisconnect(peer: MCPeerID) {
        spatialOrderManager.removeSpot(peer)
    }
    
    //MARK: Ball scene delegates
    
    func scene(scene: BallScene, ball: BallTransferRepresentation, didMoveOffscreen side: Side) {
        //TODO: Determine logic of how to know which peer should transfer to
        if let peer = peerForSide(side) {
            var err: NSError?
            meshConnectionManager.sendMessage(ball, toPeers: [peer], error: &err)
            if let e = err {
                NSLog("An error occured sending message to \(peer.displayName) - \(e.localizedDescription)")
            } else {
                NSLog("🎾 to \(side.rawValue) \(ball.position)")
            }
        } else {
            fatalError("This shouldn't happen; means the scene is out of date with spatial topology")
        }
    }
    
    //MARK: Motion manager delegate
    
    func motionManager(manager: MotionManager, didDetectContact contactEvent: ContactEvent) {
        NSLog("Motion was \(contactEvent.contactType.rawValue) on side \(contactEvent.contactSide?.rawValue)")

        switch contactEvent.contactType {
        case .Passive:
            self.receptiveToContact = true
            NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "_resetContactReception", userInfo: nil, repeats: false)
        case .Initiation:
            var err: NSError?
            meshConnectionManager.sendMessage(contactEvent, toPeers: meshConnectionManager.session.connectedPeers as [MCPeerID], error: &err)
            if let e = err {
                NSLog("An error occured sending contact information")
            } else {
                NSLog("⚡️ \(contactEvent.contactType) \(contactEvent.contactSide?.rawValue)")
            }
        }
    }
    
    func _resetContactReception() {
        self.receptiveToContact = false
    }
}

