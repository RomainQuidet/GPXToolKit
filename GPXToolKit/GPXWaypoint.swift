//
//  GPXWaypoint.swift
//  GPXToolKit
//
//  Created by Romain Quidet on 23/03/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import Foundation

public class GPXWaypoint {
	public let lat: Double
	public let lon: Double
    public internal(set) var elevation: Double?
    public internal(set) var date: Date?
    public internal(set) var name: String?
    public internal(set) var comment: String?
    public internal(set) var description: String?

    //MARK: - Internal
    
    init?(lat: String, lon: String) {
        guard let latitude = Double(lat),
            let longitude = Double(lon) else { return nil }
        guard latitude >= -90 && latitude <= 90,
            longitude >= -180 && longitude <= 180 else { return nil }
        self.lat = latitude
        self.lon = longitude
    }
}
