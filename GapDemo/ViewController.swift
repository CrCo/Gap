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

class ViewController: UIViewController, MeshConnectionManagerDelegate, BallSceneDelegate {
    
    let me = MCPeerID(displayName: UIDevice.currentDevice().name)
    var meshConnectionManager: MeshConnectionManager
    var spatialOrderManager: SpatialOrderManager
    var scene: BallScene!
    var mode: OperationMode? {
        didSet {
            if let operationMode = mode {
                self.meshConnectionManager.browseAgain(operationMode)
            }
        }
    }
    
    var alertController: UIAlertController!
    
    @IBOutlet weak var spriteView: SKView!
    
    required init(coder aDecoder: NSCoder) {
        meshConnectionManager = MeshConnectionManager(peer: me)
        spatialOrderManager = SpatialOrderManager(peerID: me)
        super.init(coder: aDecoder)
    }
    
    //MARK: View delegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        meshConnectionManager.delegate = self
        
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
    
    @IBAction func shouldAdvertise(sender: AnyObject) {
        //Toggle modes
        var previousMode = mode
        mode = nil
        mode = previousMode
    }
    
    //MARK: utilities
    
    func updateSceneAfterPeerChanges() {
        spatialOrderManager.reset()
        
        if let hub = self.meshConnectionManager.hubPeer {
            if alertController == nil {
                updateAlert(hub, count: meshConnectionManager.session.connectedPeers.count + 1)
            }
            
            if alertController.presentingViewController == nil {
                presentViewController(alertController, animated: true, completion: nil)
            } else {
                //While waiting for a response from the user, the number of fields changed
                dismissViewControllerAnimated(true, completion: { () -> Void in
                    self.updateAlert(hub, count: self.meshConnectionManager.session.connectedPeers.count + 1)
                    self.presentViewController(self.alertController, animated: true, completion: nil)
                })
            }
        }
    }
    
    func updateAlert(hub: MCPeerID, count: Int) {
        alertController = UIAlertController(title: "Position", message: "Please Confirm Your Relative Position", preferredStyle: UIAlertControllerStyle.Alert)
        
        for i in 0..<count {
            var left = UIAlertAction(title: String(i), style: UIAlertActionStyle.Default) { (action) -> Void in
                var err: NSError?
                
                self.meshConnectionManager.sendMessage(SpatialTopologyResponse(position: i), toPeers: [hub], error: &err)
                
                if let e = err {
                    NSLog("An error occured sending message responding to the position request")
                }
            }
            
            alertController.addAction(left)
        }
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

    func peer(peer: MCPeerID, sentMessage message: Serializeable) {
        switch message {
        case is Ball:
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                self.scene.addNode(message as Ball)
            }
        case is SpatialTopologyResponse:
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                NSLog("Did get response")
            }

        default:
            break
        }
    }
    
    func peerDidConnect(peer: MCPeerID) {
        updateSceneAfterPeerChanges()
    }
    
    func peerDidDisconnect(peer: MCPeerID) {
        updateSceneAfterPeerChanges()
    }
    
    //MARK: Ball scene delegates
    
    func scene(scene: BallScene, ball: Ball, didMoveOffscreen side: Side) {
        //TODO: Determine logic of how to know which peer should transfer to
        if let peer = peerForSide(side) {
            var err: NSError?
            meshConnectionManager.sendMessage(ball, toPeers: [peer], error: &err)
            if let e = err {
                NSLog("An error occured sending message to \(peer.displayName) - \(e.localizedDescription)")
            }
        } else {
            fatalError("This shouldn't happen; means the scene is out of date with spatial topology")
        }
    }
}

