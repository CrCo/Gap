//
//  ViewController.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-23.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import UIKit
import MultipeerConnectivity

let _cellIdentifier = "default"

class ViewController: UIViewController, MCSessionDelegate {

  var session: MCSession? {
        didSet {
            session?.delegate = self
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        switch (state) {
        case .Connected:
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                NSLog("💏 \(peerID.displayName)")
                
                self.view.backgroundColor = UIColor.greenColor()
            })
            
        case .NotConnected:
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                NSLog("💔 \(peerID.displayName)")
                
                self.view.backgroundColor = UIColor.redColor()
            })
        case .Connecting:
            NSLog("💗")
        }
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        let string = NSString(data: data, encoding: NSUTF8StringEncoding)
        NSLog("Data: \(string)")
   }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
    }
}

