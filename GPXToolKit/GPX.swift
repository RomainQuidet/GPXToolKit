//
//  GPX.swift
//  GPXToolKit
//
//  Created by Romain Quidet on 23/03/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import Foundation

public class GPX {
	public let version: String
	public var creator: String?
	public var metadata: GPXMetadata?
	public var waypoints: [GPXWaypoint]?
	public var routes: [GPXRoute]?
	public var tracks: [GPXTrack]?
	
    public init(version: String) {
        self.version = version
        if version != "1.0" {
            self.creator = "com.xdappfactory.GPXToolKit"
        }
    }
}
