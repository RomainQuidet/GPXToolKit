//
//  GPXParser.swift
//  GPXToolKit
//
//  Created by Romain Quidet on 23/03/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import Foundation

public class GPXParser: NSObject, XMLParserDelegate {
	
    public static let GPXErrorDomain = "com.xdappfactory.GPXToolKit"
	public typealias GPXParserCompletion = (_ gpx: GPX?, _ error: Error?) -> Void
	
	private let xmlParser: XMLParser
	private var delegateCompletion: GPXParserCompletion?
	private enum GPXParserState {
		case initial, parsing, done
	}
	private var state: GPXParserState = .initial
    private let dateFormatter = ISO8601DateFormatter()
	
    private var currentGPX: GPX?
	private var currentTrack: GPXTrack?
	private var currentTrackSegment: GPXTrackSegment?
	private var currentPoint: GPXWaypoint?
	private var currentRoute: GPXRoute?
    private var currentString: String?
    
    private var foundTracks = [GPXTrack]()
    private var foundRoutes = [GPXRoute]()
    private var foundWaypoints = [GPXWaypoint]()

	//MARK: - Lifecycle
	
	init?(contentsOf url: URL) {
		guard let parser = XMLParser(contentsOf: url) else { return nil }
		self.xmlParser = parser
		self.xmlParser.shouldResolveExternalEntities = true
		
		super.init()
		
		self.xmlParser.delegate = self
        self.dateFormatter.formatOptions = .withInternetDateTime
        self.dateFormatter.timeZone = TimeZone.current
	}
	
	init(data: Data) {
		let parser = XMLParser(data: data)
		self.xmlParser = parser
		self.xmlParser.shouldResolveExternalEntities = true
		
		super.init()
		
		self.xmlParser.delegate = self
	}
	
    //MARK: - Public
    
    public static func parse(contentsOf url: URL, completion: @escaping GPXParserCompletion) {
        guard let parser = GPXParser(contentsOf: url) else {
            let error = NSError(domain: GPXParser.GPXErrorDomain, code: -1, userInfo: nil)
            completion(nil, error)
            return
        }
        parser.parse { (gpx, error) in
            completion(gpx, error)
        }
    }
    
    public static func parse(data: Data, completion: @escaping GPXParserCompletion) {
        let parser = GPXParser(data: data)
        parser.parse { (gpx, error) in
            completion(gpx, error)
        }
    }
    
	//MARK: - Internal
	
	func parse(completion: @escaping GPXParserCompletion) {
		guard state == .initial else {
			completion(nil, nil)
			return
		}
		state = .parsing
        self.delegateCompletion = completion
		DispatchQueue.global(qos: .userInitiated).async {
            // Note: keep strong ref on self during parsing
			self.xmlParser.parse()
		}
	}
	
	func abortParsing() {
		guard state == .parsing else { return }
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			self?.xmlParser.abortParsing()
			if let completion = self?.delegateCompletion {
				DispatchQueue.main.async {
					let error = NSError(domain: "com.xdappfactory.GPXToolKit", code: -1, userInfo: nil)
					completion(nil, error)
				}
			}
		}
	}
	
	//MARK: - XMLParserDelegate
    
    public func parserDidStartDocument(_ parser: XMLParser) {
		//
	}
	
    public func parserDidEndDocument(_ parser: XMLParser) {
		state = .done
        if let completion = self.delegateCompletion {
            DispatchQueue.main.async {
                completion(self.currentGPX, nil)
            }
        }
	}
	
    public func parser(_ parser: XMLParser, didStartElement elementName: String,
				namespaceURI: String?, qualifiedName qName: String?,
				attributes attributeDict: [String : String] = [:]) {
//        debugPrint("+++ didStartElement \(elementName) with dict \(attributeDict)")
        guard let gpxKey = GPXKey(rawValue: elementName) else { return }
        switch gpxKey {
        case .gpx:
            guard let version = attributeDict["version"] else {
                abortParsing()
                return
            }
            var gpx = GPX(version: version)
            if let creator = attributeDict["creator"] {
                gpx.creator = creator
            }
            self.currentGPX = gpx
        case .trk:
            self.currentTrack = GPXTrack(name: "")
        case .trkseg:
            self.currentTrackSegment = GPXTrackSegment()
        case .trkpt, .rtept, .wpt:
            guard let latitude = attributeDict["lat"],
                let longitude = attributeDict["lon"] else { return }
            guard let pt = GPXWaypoint(lat: latitude, lon: longitude) else { return }
            self.currentPoint = pt
        case .rte:
            self.currentRoute = GPXRoute()
        case .ele, .time, .desc, .cmt, .name:
            self.currentString = ""
        }
	}
	
    public func parser(_ parser: XMLParser, didEndElement elementName: String,
				namespaceURI: String?, qualifiedName qName: String?) {
//        debugPrint("--- didEndElement \(elementName)")
        guard let gpxKey = GPXKey(rawValue: elementName) else { return }
        switch gpxKey {
        case .gpx:
            guard var gpx = self.currentGPX else {
                abortParsing()
                return
            }
            if foundWaypoints.count > 0 {
                gpx.waypoints = foundWaypoints
            }
            if foundTracks.count > 0 {
                gpx.tracks = foundTracks
            }
            if foundRoutes.count > 0 {
                gpx.routes = foundRoutes
            }
            self.currentGPX = gpx
        case .trk:
            guard let track = self.currentTrack else { return }
            self.foundTracks.append(track)
            self.currentTrack = nil
        case .trkseg:
            guard var track = self.currentTrack,
                let segment = self.currentTrackSegment else { return }
            track.segments.append(segment)
            self.currentTrackSegment = nil
            self.currentTrack = track
        case .trkpt:
            guard var segment = self.currentTrackSegment,
                let point = self.currentPoint else { return }
            segment.points.append(point)
            self.currentPoint = nil
            self.currentTrackSegment = segment
        case .rte:
            guard let route = self.currentRoute else { return }
            self.foundRoutes.append(route)
            self.currentRoute = nil
        case .rtept:
            guard var route = self.currentRoute,
                let point = self.currentPoint else { return }
            route.points.append(point)
            self.currentPoint = nil
            self.currentRoute = route
        case .wpt:
            guard let point = self.currentPoint else { return }
            self.foundWaypoints.append(point)
            self.currentPoint = nil
        case .ele:
            defer {
                self.currentString = nil
            }
            guard var point = self.currentPoint,
                let elevationString = self.currentString,
                let elevation = Double(elevationString) else { return }
            point.elevation = elevation
            self.currentPoint = point
        case .time:
            defer {
                self.currentString = nil
            }
            guard let dateString = self.currentString,
                let date = self.dateFormatter.date(from: dateString),
                var point = self.currentPoint else { return }
            point.date = date
            self.currentPoint = point
        case .name:
            guard let name = self.currentString else { return }
            if var point = self.currentPoint {
                point.name = name
                self.currentPoint = point
            }
            else if var track = self.currentTrack {
                track.name = name
                self.currentTrack = track
            }
            else if var route = self.currentRoute {
                route.name = name
                self.currentRoute = route
            }
            self.currentString = nil
        case .cmt:
            guard let comment = self.currentString else { return }
            if var point = self.currentPoint {
                point.comment = comment
                self.currentPoint = point
            }
            else if var track = self.currentTrack {
                track.comment = comment
                self.currentTrack = track
            }
            else if var route = self.currentRoute {
                route.comment = comment
                self.currentRoute = route
            }
            self.currentString = nil
        case .desc:
            guard let description = self.currentString else { return }
            if var point = self.currentPoint {
                point.description = description
                self.currentPoint = point
            }
            else if var track = self.currentTrack {
                track.description = description
                self.currentTrack = track
            }
            else if var route = self.currentRoute {
                route.description = description
                self.currentRoute = route
            }
            self.currentString = nil
        }
	}
	
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard let current = self.currentString else { return }
        self.currentString = current + string
	}
	
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        debugPrint("parser error \(parseError.localizedDescription)")
        guard let completion = self.delegateCompletion else { return }
        DispatchQueue.main.async {
            completion(nil, parseError)
        }
	}
}
