//
//  GPX.swift
//  GPXToolKit
//
//  Created by Romain Quidet on 23/03/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import Foundation

fileprivate enum GPXError: Error {
    case WriteError(String)
    case InternalError(String)
}

public struct GPX {
	public let version: String
	public var creator: String?
	public var metadata: GPXMetadata?
	public var waypoints: [GPXWaypoint]?
	public var routes: [GPXRoute]?
	public var tracks: [GPXTrack]?
    
    public typealias GPXWriteCompletion = (_ success: Bool) -> Void
    
    private var dateFormatter:ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    //MARK: - Lifecycle
	
    public init(version: String) {
        self.version = version
        self.creator = "GPXToolKit - http://www.xdappfactory.com"
    }
    
    //MARK: - Public
    
    public func write(to fileURL: URL, completion: @escaping GPXWriteCompletion) {
        //Keep strong ref on self while writing
        DispatchQueue.global(qos: .userInitiated).async {
            guard fileURL.isFileURL == true else {
                self.warnDelegateWriteCompletion(success: false, completion: completion)
                return
            }
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: fileURL.absoluteString) == false {
                let data = Data()
                do {
                    try data.write(to: fileURL)
                } catch {
                    debugPrint("error: \(error)")
                }                    
            }
            
            guard let file = try? FileHandle(forWritingTo: fileURL) else {
                self.warnDelegateWriteCompletion(success: false, completion: completion)
                return
            }
            
            do {
                try self.writeXMLHeader(to: file)
                try self.writeGPXHeader(to: file)
                
                if let waypoints = self.waypoints {
                    try waypoints.forEach({ (waypoint) in
                        try self.writeWayPoint(waypoint, to: file)
                    })
                }
                else if let routes = self.routes {
                    try routes.forEach({ (route) in
                        try self.writeRouteHeader(route, to: file)
                        try route.points.forEach({ (wpt) in
                            try self.writeRoutePoint(wpt, to: file)
                        })
                        try self.writeRouteHeaderEnd(to: file)
                    })
                }
                else if let tracks = self.tracks {
                    try tracks.forEach({ (track) in
                        try self.writeTrackHeader(track, to: file)
                        try track.segments.forEach({ (segment) in
                            try self.writeTrackSegmentHeader(to: file)
                            try segment.points.forEach({ (point) in
                                try self.writeTrackPoint(point, to: file)
                            })
                            try self.writeTrackSegmentHeaderEnd(to: file)
                        })
                        try self.writeTrackHeaderEnd(to: file)
                    })
                }
                
                try self.writeGPXHeaderEnd(to: file)
                
                self.warnDelegateWriteCompletion(success: true, completion: completion)
            } catch {
                self.warnDelegateWriteCompletion(success: false, completion: completion)
            }
        }
    }
    
    //MARK: - Private
    
    private func warnDelegateWriteCompletion(success: Bool, completion: @escaping GPXWriteCompletion) {
        DispatchQueue.main.async {
            completion(success)
        }
    }
    
    private func writeXMLHeader(to file: FileHandle) throws {
        let header = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        try file.write(header)
    }
    
    private func writeGPXHeader(to file: FileHandle) throws {
        var header = "<\(GPXKey.gpx) version=\"\(version)\"\n"
        if let creator = self.creator {
            header += "\tcreator=\"\(creator)\"\n"
        }
        header += "\txsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n"
        try file.write(header)
    }
    
    private func writeGPXHeaderEnd(to file: FileHandle) throws {
        let end = "</\(GPXKey.gpx)>"
        try file.write(end)
    }
    
    //MARK: Track
    
    private func writeTrackHeader(_ track: GPXTrack, to file: FileHandle) throws {
        var header = "\t<\(GPXKey.trk)>\n"
        let tabOffset = "\t"
        header = header + tabOffset + "\t<\(GPXKey.name)>\(track.name)</\(GPXKey.name)>\n"
        if let comment = track.comment {
            header = header + tabOffset + "\t<\(GPXKey.cmt)>\(comment)</\(GPXKey.cmt)>\n"
        }
        if let description = track.description {
            header = header + tabOffset + "\t<\(GPXKey.desc)>\(description)</\(GPXKey.desc)>\n"
        }
        try file.write(header)
    }
    
    private func writeTrackHeaderEnd(to file: FileHandle) throws {
        let end = "\t</\(GPXKey.trk)>\n"
        try file.write(end)
    }
    
    private func writeTrackSegmentHeader(to file: FileHandle) throws {
        let header = "\t\t<\(GPXKey.trkseg)>\n"
        try file.write(header)
    }
    
    private func writeTrackSegmentHeaderEnd(to file: FileHandle) throws {
        let end = "\t\t</\(GPXKey.trkseg)>\n"
        try file.write(end)
    }
    
    private func writeTrackPoint(_ point: GPXWaypoint, to file: FileHandle) throws {
        try writePoint(point, type: .trkpt, to: file)
    }
    
    //MARK: Route
    
    private func writeRouteHeader(_ route: GPXRoute, to file: FileHandle) throws {
        var header = "\t<\(GPXKey.rte)>\n"
        let tabOffset = "\t"
        if let name = route.name {
            header = header + tabOffset + "\t<\(GPXKey.name)>\(name)</\(GPXKey.name)>\n"
        }
        if let comment = route.comment {
            header = header + tabOffset + "\t<\(GPXKey.cmt)>\(comment)</\(GPXKey.cmt)>\n"
        }
        if let description = route.description {
            header = header + tabOffset + "\t<\(GPXKey.desc)>\(description)</\(GPXKey.desc)>\n"
        }
        try file.write(header)
    }
    
    private func writeRouteHeaderEnd(to file: FileHandle) throws {
        let end = "\t</\(GPXKey.rte)>\n"
        try file.write(end)
    }
    
    private func writeRoutePoint(_ point: GPXWaypoint, to file: FileHandle) throws {
        try writePoint(point, type: .rtept, to: file)
    }
    
    //MARK: Waypoints
    
    private func writeWayPoint(_ point: GPXWaypoint, to file: FileHandle) throws {
        try writePoint(point, type: .wpt, to: file)
    }
    
    //MARK: Generic point
    
    private func writePoint(_ point: GPXWaypoint, type: GPXKey, to file: FileHandle) throws {
        let tabOffset: String
        switch type {
        case .wpt:
            tabOffset = "\t"
        case .rtept:
            tabOffset = "\t\t"
        case .trkpt:
            tabOffset = "\t\t\t"
        default:
            let error = GPXError.InternalError("Incorrect point key")
            throw error
        }
        
        var pointString = tabOffset + "<\(type) lat=\"\(point.lat)\" lon=\"\(point.lon)\">\n"
        if let elevation = point.elevation {
            pointString = pointString + tabOffset + "\t<\(GPXKey.ele)>\(elevation)</\(GPXKey.ele)>\n"
        }
        if let date = point.date {
            let time = dateFormatter.string(from: date)
            pointString = pointString + tabOffset + "\t<\(GPXKey.time)>\(time)</\(GPXKey.time)>\n"
        }
        if let name = point.name {
            pointString = pointString + tabOffset + "\t<\(GPXKey.name)>\(name)</\(GPXKey.name)>\n"
        }
        if let comment = point.comment {
            pointString = pointString + tabOffset + "\t<\(GPXKey.cmt)>\(comment)</\(GPXKey.cmt)>\n"
        }
        if let description = point.description {
            pointString = pointString + tabOffset + "\t<\(GPXKey.desc)>\(description)</\(GPXKey.desc)>\n"
        }
        pointString = pointString + tabOffset + "</\(type)>\n"
        try file.write(pointString)
    }
}

fileprivate extension FileHandle {
    func write(_ string: String) throws {
        guard let data = string.data(using: .utf8) else {
            let error = GPXError.WriteError("write failed")
            throw error
        }
        write(data)
    }
}
