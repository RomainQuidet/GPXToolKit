//
//  GPXTrack.swift
//  GPXToolKit
//
//  Created by Romain Quidet on 23/03/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import Foundation

public class GPXTrack {
    public internal(set) var name: String = ""
	public internal(set) var comment: String?
	public internal(set) var description: String?
    public internal(set) var segments = [GPXTrackSegment]()

}
