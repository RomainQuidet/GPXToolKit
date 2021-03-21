//
//  GPXTrack.swift
//  GPXToolKit
//
//  Created by Romain Quidet on 23/03/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import Foundation

public struct GPXTrack {
    public var name: String
	public var comment: String?
	public var description: String?
    public var segments = [GPXTrackSegment]()

    public init(name: String) {
        self.name = name
    }
}
