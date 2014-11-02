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
    
    var meshConnectionManager: MeshConnectionManager = MeshConnectionManager()

    var scene: BallScene!
    var openSides: (Bool, Bool) = (false, false)
    
    @IBAction func shouldSpew(sender: AnyObject) {
        scene.addNode()
    }
    @IBOutlet weak var spriteView: SKView!
    @IBAction func shouldAdvertise(sender: AnyObject) {
        meshConnectionManager.browseAgain()
    }
    
    func shouldTransferBall(ball: [String: AnyObject], toSide side: Side, error: NSErrorPointer) {
        meshConnectionManager.shouldTransferBall(ball, toSide: side, error: error)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        meshConnectionManager.delegate = self
        
        scene = BallScene()
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
        scene.transferDelegate = self
        spriteView.presentScene(scene)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func wallDidOpenToSide(side: Side) {
        switch side {
        case .Left: openSides = (true, openSides.1)
        case .Right: openSides = (openSides.0, true)
        }
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.scene.setPhysicsBodyOpenings(self.openSides.0, right: self.openSides.1)
        }
    }
    
    func wallDidCloseToSide(side: Side) {
        switch side {
        case .Left: openSides = (false, openSides.1)
        case .Right: openSides = (openSides.0, false)
        }
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.scene.setPhysicsBodyOpenings(self.openSides.0, right: self.openSides.1)
        }
    }
    
    func shouldAddNewNode(data: [String : AnyObject], fromSide side: Side) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.scene.addNeighborNode(data, fromSide: side)
        }
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        let size = self.view.frame.size
        scene.aspectRatio = CGFloat(size.width/size.height)
    }
}

