//
//  GPXParser.swift
//  GPXToolKit
//
//  Created by Romain Quidet on 23/03/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import Foundation

class GPXParser: NSObject, XMLParserDelegate {
	
	typealias GPXParserCompletion = (_ gpx: GPX?, _ error: Error?) -> Void
	
	private let xmlParser: XMLParser
	private var delegateCompletion: GPXParserCompletion?
	private enum GPXParserState {
		case initial, parsing, done
	}
	private var state: GPXParserState = .initial
	private enum GPXKey: String {
		case trk, trkpt, trkseg
		case wpt
		case rte, rtept
		case ele, time, desc, cmt, name
	}
    
    private let dateFormatter = ISO8601DateFormatter()
	
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
	
	func parse(completion: @escaping GPXParserCompletion) {
		guard state == .initial else {
			completion(nil, nil)
			return
		}
		state = .parsing
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			let start = self?.xmlParser.parse()
			if start == false {
				let error = NSError(domain: "com.xdappfactory.GPXToolKit", code: -1, userInfo: nil)
				DispatchQueue.main.async {
					completion(nil, error)
				}
			}
			else {
				self?.delegateCompletion = completion
			}
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
	
	func parserDidStartDocument(_ parser: XMLParser) {
		//
	}
	
	func parserDidEndDocument(_ parser: XMLParser) {
		state = .done
	}
	
	func parser(_ parser: XMLParser, didStartElement elementName: String,
				namespaceURI: String?, qualifiedName qName: String?,
				attributes attributeDict: [String : String] = [:]) {
        guard let gpxKey = GPXKey(rawValue: elementName) else { return }
        switch gpxKey {
        case .trk:
            self.currentTrack = GPXTrack()
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
	
	func parser(_ parser: XMLParser, didEndElement elementName: String,
				namespaceURI: String?, qualifiedName qName: String?) {
        guard let gpxKey = GPXKey(rawValue: elementName) else { return }
        switch gpxKey {
        case .trk:
            guard let track = self.currentTrack else { return }
            self.foundTracks.append(track)
            self.currentTrack = nil
        case .trkseg:
            guard let track = self.currentTrack,
                let segment = self.currentTrackSegment else { return }
            track.segments.append(segment)
            self.currentTrackSegment = nil
        case .trkpt:
            guard let segment = self.currentTrackSegment,
                let point = self.currentPoint else { return }
            segment.points.append(point)
            self.currentPoint = nil
        case .rte:
            guard let route = self.currentRoute else { return }
            self.foundRoutes.append(route)
            self.currentRoute = nil
        case .rtept:
            guard let route = self.currentRoute,
                let point = self.currentPoint else { return }
            route.points.append(point)
            self.currentPoint = nil
        case .wpt:
            guard let point = self.currentPoint else { return }
            self.foundWaypoints.append(point)
            self.currentPoint = nil
        case .ele:
            defer {
                self.currentString = nil
            }
            guard let point = self.currentPoint,
                let elevationString = self.currentString,
                let elevation = Double(elevationString) else { return }
            point.elevation = elevation
        case .time:
            defer {
                self.currentString = nil
            }
            guard let dateString = self.currentString,
                let date = self.dateFormatter.date(from: dateString),
                let point = self.currentPoint else { return }
            point.date = date
        case .name:
            guard let name = self.currentString else { return }
            if let point = self.currentPoint {
                point.name = name
            }
            else if let track = self.currentTrack {
                track.name = name
            }
            else if let route = self.currentRoute {
                route.name = name
            }
            self.currentString = nil
        case .cmt:
            guard let comment = self.currentString else { return }
            if let point = self.currentPoint {
                point.comment = comment
            }
            else if let track = self.currentTrack {
                track.comment = comment
            }
            else if let route = self.currentRoute {
                route.comment = comment
            }
            self.currentString = nil
        case .desc:
            guard let description = self.currentString else { return }
            if let point = self.currentPoint {
                point.description = description
            }
            else if let track = self.currentTrack {
                track.description = description
            }
            else if let route = self.currentRoute {
                route.description = description
            }
            self.currentString = nil
        }
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard let current = self.currentString else { return }
        self.currentString = current + string
	}
	
	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
		//
	}
}
