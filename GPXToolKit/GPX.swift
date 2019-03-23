//
//  GPX.swift
//  GPXToolKit
//
//  Created by Romain Quidet on 23/03/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import Foundation

public struct GPX {
	public let version: String
	public let creator: String
	public let metadata: GPXMetadata?
	public let waypoints: [GPXWaypoint]?
	public let routes: [GPXRoute]?
	public let tracks: [GPXTrack]?
	
	public typealias GPXCreationCompletion = (_ gpx: GPX?, _ error: Error?) -> Void
	public static let GPXErrorDomain = "com.xdappfactory.GPXToolKit"
	
	public static func from(contentsOf url: URL, completion: @escaping GPXCreationCompletion) {
		guard let parser = GPXParser(contentsOf: url) else {
			let error = NSError(domain: GPX.GPXErrorDomain, code: -1, userInfo: nil)
			completion(nil, error)
			return
		}
		parser.parse { (gpx, error) in
			completion(gpx, error)
		}
	}
	
	public static func from(data: Data, completion: @escaping GPXCreationCompletion) {
		let parser = GPXParser(data: data)
		parser.parse { (gpx, error) in
			completion(gpx, error)
		}
	}
}
