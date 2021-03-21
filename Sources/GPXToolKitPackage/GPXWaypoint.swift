//
//  GPXWaypoint.swift
//  GPXToolKit
//
//  Created by Romain Quidet on 23/03/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import Foundation

public struct GPXWaypoint {
	public let lat: Double
	public let lon: Double
    public var elevation: Double?
    public var date: Date?
    public var name: String?
    public var comment: String?
    public var description: String?

    //MARK: - Internal
    
    public init?(lat: String, lon: String) {
        guard let latitude = Double(lat),
            let longitude = Double(lon) else { return nil }
        guard latitude >= -90 && latitude <= 90,
            longitude >= -180 && longitude <= 180 else { return nil }
        self.lat = latitude
        self.lon = longitude
    }
    
    public init?(lat: Double, lon: Double) {
        guard lat >= -90 && lat <= 90,
            lon >= -180 && lon <= 180 else { return nil }
        self.lat = lat
        self.lon = lon
    }
}
