//
//  Request.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-02.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import Foundation

struct SpatialTopologyDefinition: Serializeable {
    
    
    init(fromJSON: [String : AnyObject]) {
    }
    
    init() {
        
    }
    
    func toJSON() -> [String: AnyObject]{
        return [String: AnyObject]()
    }
}

struct SpatialTopologyResponse: Serializeable {
    
    var position: Int
    
    init(fromJSON json: [String : AnyObject]) {
        self.position = json["position"] as Int
    }
    
    init(position: Int) {
        self.position = position
    }
    
    func toJSON() -> [String: AnyObject]{
        return ["position": position]
    }
}