//
//  MotionManager.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-04.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import CoreMotion

protocol MotionManagerDelegate: NSObjectProtocol {
    func motionManager(manager: MotionManager, didDetectContact: ContactEvent)
}

class MotionManager: NSObject {
    
    var _log = [Double]()
    let motionManager = CMMotionManager()
    
    weak var delegate: MotionManagerDelegate!
    
    override init() {
        super.init()
        
        motionManager.accelerometerUpdateInterval = 0.002
    }
    
    func startMotionUpdates() {
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue(), withHandler: { (data, err) -> Void in
            
            //There are no values, but we may need to start the clock
            if abs(data.acceleration.x) > 0.01 {
                self._log.append(data.acceleration.x)
            } else if self._log.count > 0 {
                if self._log.reduce(false, combine: { $0 || $1 > 0.2 }) {
                    self.performAnalysis(self._log)
                }
                self._log.removeAll(keepCapacity: true)
            }
        })
    }
    
    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
    
    func performAnalysis(log: [Double]) {
        var behaviour: String
        
        if log.count > 10 {
            var sum: Double = 0
            for i in 0...5 {
                sum += log[i]
            }
            
            var direction: Side
            if sum > 0 {
                direction = .Left
            } else {
                direction = .Right
            }
            delegate.motionManager(self, didDetectContact: ContactEvent(initiationWithContactDirection: direction))

        } else {
            delegate.motionManager(self, didDetectContact: ContactEvent())
        }
    }
}