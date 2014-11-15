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
    
    var operatingMode: OperationMode {
        get {
            switch NSUserDefaults.standardUserDefaults().boolForKey("role") {
            case true: return .Listener
            case false:
                fallthrough
            default: return .Broadcaster
            }
        }
    }
    
    var ballType: BallType {
        get {
            return BallType(rawValue: NSUserDefaults.standardUserDefaults().integerForKey("type") as Int)!
        }
    }

    var side: Side {
        get {
            if let s = NSUserDefaults.standardUserDefaults().stringForKey("side") {
                return Side(rawValue: s)!
            }
            return .Left
        }
    }
    
    var motionHandlingQueue = NSOperationQueue()
    var meshConnectionManager: MeshConnectionManager!
    var spatialOrderManager: OrderStorage!
    var motionManager: MotionManager!
    var scene: BallScene!
    @IBOutlet weak var spriteView: SKView!
    @IBOutlet weak var statusIndicator: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        meshConnectionManager = MeshConnectionManager(peer: me, side: side)
        meshConnectionManager.delegate = self
        meshConnectionManager.mode = operatingMode
        
        switch operatingMode {
        case .Listener:
            spatialOrderManager = SpatialOrderManager(peerID: me)

            motionManager = MotionManager(queue: motionHandlingQueue)
            motionManager.delegate = self
            motionManager.startMotionUpdates()
        case .Broadcaster: spatialOrderManager = SpatialOrderContainer(me: me)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "defaultsDidChange:", name: NSUserDefaultsDidChangeNotification, object: nil)
    }
    
    //MARK: View delegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene = BallScene(type: ballType)
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
        scene.transferDelegate = self
        spriteView.presentScene(scene)
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
    }
    
    //MARK: utilities
    
    func defaultsDidChange(notification: NSNotification) {
        meshConnectionManager.mode = operatingMode
        meshConnectionManager.side = side
        scene.type = ballType
    }
    
    func updateAndShareGlobalTopography() {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.scene.openings = (
                left: self.spatialOrderManager.left() != nil,
                right: self.spatialOrderManager.right() != nil
            )
        })
        
        if spatialOrderManager is SpatialOrderManager {
            //We are the hub, we need to forward our knowledge
            let som = spatialOrderManager as SpatialOrderManager

            let topoRep = GlobalTopologyDefinitionRepresentation(topology: som.order)
            var err: NSError?
            self.meshConnectionManager.sendMessage(topoRep, toPeers: meshConnectionManager.session.connectedPeers as [MCPeerID], error: &err)
            if let e = err {
                NSLog("❌🎵🌏: \(som)")
            } else {
                NSLog("🎵🌏: \(som)")
            }
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
            //Only the hub gets these messages
            (spatialOrderManager as SpatialOrderManager).addInference(message as RelativeTopologyAssertionRepresentation, forPeer: peer)
            updateAndShareGlobalTopography()
        case is GlobalTopologyDefinitionRepresentation:
            (spatialOrderManager as SpatialOrderContainer).order = (message as GlobalTopologyDefinitionRepresentation).topology
            updateAndShareGlobalTopography()
            
        case is RelativePositionRequest:
            var err: NSError?
            
            let topoAssertion = RelativeTopologyAssertionRepresentation(side: side)
            self.meshConnectionManager.sendMessage(topoAssertion, toPeers: [peer], error: &err)
            
            if let e = err {
                NSLog("Couldn't send the contact event message")
            } else {
                NSLog("🎵 \(side.rawValue)")
            }
        default:
            fatalError("Unknown message")
        }
    }
    
    func peerDidConnect(peer: MCPeerID) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.statusIndicator.text = "💏"
        }
        
        if operatingMode == .Listener && motionManager.stable {
            var err: NSError?
            
            meshConnectionManager.sendMessage(RelativePositionRequest(), toPeers: meshConnectionManager.session.connectedPeers as [MCPeerID], error: &err)
            
            if let e = err {
                NSLog("Could not send request")
            }
        }
    }
    
    func peerDidDisconnect(peer: MCPeerID) {
        if spatialOrderManager is SpatialOrderManager {
            (spatialOrderManager as SpatialOrderManager).removeSpot(peer)
            updateAndShareGlobalTopography()
        } else if peer == meshConnectionManager.hubPeer {
            (spatialOrderManager as SpatialOrderContainer).clear()
            updateAndShareGlobalTopography()
        }

        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.statusIndicator.text = "💔"
        }
    }
    
    func peerIsConnecting(peer: MCPeerID) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.statusIndicator.text = "💗"
        }
    }
    
    //MARK: Ball scene delegates
    
    func scene(scene: BallScene, ball: BallTransferRepresentation, didMoveOffscreen side: Side) {
        //TODO: Determine logic of how to know which peer should transfer to
        var neighbor: MCPeerID?
        switch side {
        case .Left:
            neighbor = spatialOrderManager.left()
        case .Right:
            neighbor = spatialOrderManager.right()
        }        
        
        if let peer = neighbor {
            var err: NSError?
            meshConnectionManager.sendMessage(ball, toPeers: [peer], error: &err)
            if let e = err {
                NSLog("An error occured sending message to \(peer.displayName) - \(e.localizedDescription)")
            } else {
                NSLog("🎾 to \(side.rawValue) \(ball.position)")
            }
        } else {
            //Means the scene is out of date with spatial topology
            NSLog("❌🎾 to \(side.rawValue) \(ball.position)")
        }
    }
    
    //MARK: Motion manager delegate (only for listener)
    
    func motionManagerDidPickUp() {
        (self.spatialOrderManager as SpatialOrderManager).reset()
        updateAndShareGlobalTopography()
    }

    func motionManagerDidPutDown() {
        var err: NSError?

        meshConnectionManager.sendMessage(RelativePositionRequest(), toPeers: meshConnectionManager.session.connectedPeers as [MCPeerID], error: &err)

        if let e = err {
            NSLog("Could not send request")
        }
    }
}

