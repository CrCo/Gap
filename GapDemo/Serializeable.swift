//
//  Serializeable.swift
//  GapDemo
//
//  Created by Stephen Visser on 2014-11-02.
//  Copyright (c) 2014 Stephen Visser. All rights reserved.
//

import Foundation

protocol Serializeable {
    init(fromJSON: [String: AnyObject])
    func toJSON() -> [String: AnyObject]
}