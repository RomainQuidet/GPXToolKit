//
//  GPXParser.swift
//  GPXToolKit
//
//  Created by Romain Quidet on 23/03/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import UIKit

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
	
	private var currentTrack: GPXTrack?
	private var currentTrackSegment: GPXTrackSegment?
	private var currentPoint: GPXWaypoint?
	private var currentRoute: GPXRoute?

	//MARK: - Lifecycle
	
	init?(contentsOf url: URL) {
		guard let parser = XMLParser(contentsOf: url) else { return nil }
		self.xmlParser = parser
		self.xmlParser.shouldResolveExternalEntities = true
		
		super.init()
		
		self.xmlParser.delegate = self
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
		//
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String,
				namespaceURI: String?, qualifiedName qName: String?) {
		//
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String) {
		//
	}
	
	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
		//
	}
}
