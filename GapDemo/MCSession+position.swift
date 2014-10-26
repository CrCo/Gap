//
//  MCSession+position.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-10-25.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import MultipeerConnectivity

var spatialPositionKey: Int = 0

extension MCSession {
    var position: SpatialPosition! {
        get {
            return SpatialPosition.Right
//            return SpatialPosition(rawValue: objc_getAssociatedObject(self, &spatialPositionKey) as String)
        }
        set(newValue) {
//            objc_setAssociatedObject(self, &spatialPositionKey, newValue.rawValue, UInt(OBJC_ASSOCIATION_RETAIN))
        }
    }
}

enum SpatialPosition : String {
    case Left = "left"
    case Right = "right"
    case Middle = "middle"
}