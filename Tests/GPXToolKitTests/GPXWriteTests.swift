//
//  GPXWriteTests.swift
//  GPXToolKitTests
//
//  Created by Romain Quidet on 01/05/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import XCTest
@testable import GPXToolKit

class GPXWriteTests: XCTestCase {
    func testSingleWaypoint() {
        var gpx = GPX(version: "1.1")
        guard let waypoint = GPXWaypoint(lat: 44, lon: 2) else {
            XCTFail("waypoint must be created")
            return
        }
        gpx.waypoints = [waypoint]
        let url = writeUrl()
        let expectation = self.expectation(description: "SingleWaypoint")
        gpx.write(to: url) { (success) in
            if success == true {
                expectation.fulfill()
            }
            else {
                XCTFail("write error")
            }
        }
        wait(for: [expectation], timeout: 2)
        
        guard let parser = GPXParser.init(contentsOf: url) else {
            XCTFail("parser must find a file")
            return
        }
        let parsingExpectation = self.expectation(description: "SingleWaypointParsing")
        parser.parse(completion: { (gpx, error) in
            if let error = error {
                XCTFail("parser must work... \(error)")
                return
            }
            
            guard let gpx = gpx else {
                XCTFail("gpx must be read")
                return
            }
            
            guard let readWpt = gpx.waypoints?.first else {
                XCTFail("must read one waypoint")
                return
            }
            
            XCTAssertEqual(waypoint.lat, readWpt.lat, accuracy: 0.000001)
            XCTAssertEqual(waypoint.lon, readWpt.lon, accuracy: 0.00001)
            parsingExpectation.fulfill()
        })
        wait(for: [parsingExpectation], timeout: 2)
        
        try? FileManager.default.removeItem(at: url)
    }
    
    func testSingleRouteWaypoint() {
        var gpx = GPX(version: "1.1")
        guard let waypoint = GPXWaypoint(lat: 44, lon: 2) else {
            XCTFail("waypoint must be created")
            return
        }
        var route = GPXRoute()
        route.points = [waypoint]
        gpx.routes = [route]
        let url = writeUrl()
        let expectation = self.expectation(description: "SingleRouteWaypoint")
        gpx.write(to: url) { (success) in
            if success == true {
                expectation.fulfill()
            }
            else {
                XCTFail("write error")
            }
        }
        wait(for: [expectation], timeout: 2)
        
        guard let parser = GPXParser.init(contentsOf: url) else {
            XCTFail("parser must find a file")
            return
        }
        let parsingExpectation = self.expectation(description: "SingleRouteWaypointParsing")
        parser.parse(completion: { (gpx, error) in
            if let error = error {
                XCTFail("parser must work... \(error)")
                return
            }
            
            guard let gpx = gpx else {
                XCTFail("gpx must be read")
                return
            }
            
            guard let route = gpx.routes?.first else {
                XCTFail("must read one route")
                return
            }
            guard let readWpt = route.points.first else {
                XCTFail("must read one waypoint")
                return
            }
            XCTAssertEqual(waypoint.lat, readWpt.lat, accuracy: 0.000001)
            XCTAssertEqual(waypoint.lon, readWpt.lon, accuracy: 0.00001)
            parsingExpectation.fulfill()
        })
        wait(for: [parsingExpectation], timeout: 2)
        
        try? FileManager.default.removeItem(at: url)
    }
    
    func testSingleTrackWaypoint() {
        var gpx = GPX(version: "1.1")
        guard let waypoint = GPXWaypoint(lat: 44, lon: 2) else {
            XCTFail("waypoint must be created")
            return
        }
        var track = GPXTrack(name: "unitTestTrack")
        let trackSegment = GPXTrackSegment(points: [waypoint])
        track.segments = [trackSegment]
        gpx.tracks = [track]
        let url = writeUrl()
        let expectation = self.expectation(description: "SingleRouteWaypoint")
        gpx.write(to: url) { (success) in
            if success == true {
                expectation.fulfill()
            }
            else {
                XCTFail("write error")
            }
        }
        wait(for: [expectation], timeout: 2)
        
        guard let parser = GPXParser.init(contentsOf: url) else {
            XCTFail("parser must find a file")
            return
        }
        let parsingExpectation = self.expectation(description: "SingleRouteWaypointParsing")
        parser.parse(completion: { (gpx, error) in
            if let error = error {
                XCTFail("parser must work... \(error)")
                return
            }
            
            guard let gpx = gpx else {
                XCTFail("gpx must be read")
                return
            }
            
            guard let track = gpx.tracks?.first else {
                XCTFail("must read one track")
                return
            }
            XCTAssertEqual(track.name, "unitTestTrack")
            guard let trackSegment = track.segments.first else {
                XCTFail("must read one track segment")
                return
            }
            guard let readWpt = trackSegment.points.first else {
                XCTFail("must read one waypoint")
                return
            }
            XCTAssertEqual(waypoint.lat, readWpt.lat, accuracy: 0.000001)
            XCTAssertEqual(waypoint.lon, readWpt.lon, accuracy: 0.00001)
            parsingExpectation.fulfill()
        })
        wait(for: [parsingExpectation], timeout: 2)
        
        try? FileManager.default.removeItem(at: url)
    }
    
    func testCoupleTrackWaypoint() {
        var gpx = GPX(version: "1.1")
        gpx.tracks = []
        for i in 1...2 {
            guard let waypoint = GPXWaypoint(lat: 44, lon: 2 + Double(i)) else {
                XCTFail("waypoint must be created")
                return
            }
            var track = GPXTrack(name: "unitTestTrack\(i)")
            let trackSegment = GPXTrackSegment(points: [waypoint])
            track.segments = [trackSegment]
            gpx.tracks?.append(track)
        }
        
        let url = writeUrl()
        let expectation = self.expectation(description: "SingleRouteWaypoint")
        gpx.write(to: url) { (success) in
            if success == true {
                expectation.fulfill()
            }
            else {
                XCTFail("write error")
            }
        }
        wait(for: [expectation], timeout: 2)
        
        guard let parser = GPXParser.init(contentsOf: url) else {
            XCTFail("parser must find a file")
            return
        }
        let parsingExpectation = self.expectation(description: "SingleRouteWaypointParsing")
        parser.parse(completion: { (gpx, error) in
            if let error = error {
                XCTFail("parser must work... \(error)")
                return
            }
            
            guard let gpx = gpx else {
                XCTFail("gpx must be read")
                return
            }
            
            for i in 1...2 {
                guard let track = gpx.tracks?[i - 1] else {
                    XCTFail("must read one track")
                    return
                }
                XCTAssertEqual(track.name, "unitTestTrack\(i)")
                guard let trackSegment = track.segments.first else {
                    XCTFail("must read one track segment")
                    return
                }
                guard let readWpt = trackSegment.points.first else {
                    XCTFail("must read one waypoint")
                    return
                }
                XCTAssertEqual(44, readWpt.lat, accuracy: 0.000001)
                XCTAssertEqual(2 + Double(i), readWpt.lon, accuracy: 0.00001)
            }
            
            parsingExpectation.fulfill()
        })
        wait(for: [parsingExpectation], timeout: 2)
        
        try? FileManager.default.removeItem(at: url)
    }
    
    //MARK: - Helper
    
    private func writeUrl() -> URL {
        let directory = FileManager.default.temporaryDirectory
        let testFile = directory.appendingPathComponent("unitTestGPX").appendingPathExtension("gpx")
        return testFile
    }
}
