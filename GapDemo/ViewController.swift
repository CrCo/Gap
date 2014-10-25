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

class ViewController: UIViewController, MCSessionDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate {

    var messages = [String]()
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func newthing(sender: AnyObject) {
        NSLog("Reconnect")
    }
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var statusView: StatusView!
    @IBAction func didPressSend(sender: AnyObject) {
        let message = textField.text
        let data = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        var error : NSError?
        session?.sendData(data, toPeers: session?.connectedPeers, withMode: .Reliable, error: &error)
        
        if let actualError = error {
            NSLog("Oops, error occured when sending \(message) with error \(actualError)")
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        didPressSend(textField)
        return false
    }
    
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
            NSLog("💏 \(peerID.displayName)")
            statusView.status = .Good
        case .NotConnected:
            NSLog("💔 \(peerID.displayName)")
            if session.connectedPeers.count == 0 {
                statusView.status = .Bad
            }
            
            //session.disconnect()
        case .Connecting:
            NSLog("💗")
        }
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        let string = NSString(data: data, encoding: NSUTF8StringEncoding)
        if let actualString = string {
            messages.insert(actualString, atIndex: 0)
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
            })
        }
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(_cellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel.text = messages[indexPath.row]
        return cell
    }
}

