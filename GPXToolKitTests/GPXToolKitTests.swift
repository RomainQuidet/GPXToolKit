//
//  GPXToolKitTests.swift
//  GPXToolKitTests
//
//  Created by Romain Quidet on 23/03/2019.
//  Copyright © 2019 Romain Quidet. All rights reserved.
//

import XCTest
@testable import GPXToolKit

class GPXToolKitTests: XCTestCase {

    private var bundle: Bundle?
    
    override func setUp() {
        bundle = Bundle(for: self.classForCoder)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSingleWaypoint() {
        guard let url = self.bundle?.url(forResource: "SingleWaypoint", withExtension: "gpx") else {
            XCTFail("can't find file")
            return
        }
        let expectation = self.expectation(description: "SingleWaypoint")
        GPXParser.parse(contentsOf: url) { (gpx, error) in
            guard let gpx = gpx else {
                XCTFail("gpx not created")
                return
            }
            XCTAssertEqual(gpx.version, "1.1")
            XCTAssertEqual(gpx.creator, "Xcode")
            XCTAssertTrue(gpx.waypoints?.count == 1, "wrong waypoints count")
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 2)
    }
    
    func testSingleTrack1_0() {
        guard let url = self.bundle?.url(forResource: "SingleTrack-1.0", withExtension: "gpx") else {
            XCTFail("can't find file")
            return
        }
        let expectation = self.expectation(description: "SingleTrack-1.0")
        GPXParser.parse(contentsOf: url) { (gpx, error) in
            guard let gpx = gpx else {
                XCTFail("gpx not created")
                return
            }
            XCTAssertEqual(gpx.version, "1.0")
            XCTAssertTrue(gpx.tracks?.count == 1, "wrong tracks count")
            guard let track = gpx.tracks?[0] else {
                XCTFail("wrong tracks count")
                return
            }
            XCTAssertTrue(track.segments.count == 1, "wrong segment count")
            let segment = track.segments[0]
            XCTAssertTrue(segment.points.count == 7, "wrong points count")
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 2)
    }
    
    func testGPSBabel1_0() {
        guard let url = self.bundle?.url(forResource: "GPSBabel-1.0", withExtension: "gpx") else {
            XCTFail("can't find file")
            return
        }
        let expectation = self.expectation(description: "GPSBabel-1.0")
        GPXParser.parse(contentsOf: url) { (gpx, error) in
            guard let gpx = gpx else {
                XCTFail("gpx not created")
                return
            }
            XCTAssertEqual(gpx.version, "1.0")
            XCTAssertEqual(gpx.creator, "GPSBabel - http://www.gpsbabel.org")
            XCTAssertTrue(gpx.tracks?.count == 1, "wrong tracks count")
            guard let track = gpx.tracks?[0] else {
                XCTFail("wrong tracks count")
                return
            }
            XCTAssertEqual(track.name, "ACTIVE LOG")
            XCTAssertTrue(track.segments.count == 1, "wrong segment count")
            let segment = track.segments[0]
            XCTAssertTrue(segment.points.count == 1, "wrong points count")
            let point = segment.points[0]
            XCTAssertEqual(point.lat, 52.564001083, accuracy: 0.000001)
            XCTAssertEqual(point.lon, -1.826841831, accuracy: 0.000001)
            guard let elevation = point.elevation else {
                XCTFail("missing elevation")
                return
            }
            XCTAssertEqual(elevation, 115.976196, accuracy: 0.001)
            guard let date = point.date else {
                XCTFail("missing date")
                return
            }
            let year = Calendar.current.component(.year, from: date)
            XCTAssertTrue(year == 2005, "wrong year")
            let month = Calendar.current.component(.month, from: date)
            XCTAssertTrue(month == 11, "wrong month")
            let day = Calendar.current.component(.day, from: date)
            XCTAssertTrue(day == 7, "wrong day")
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 2)
    }
    
    func testEMTAC_BTGPS() {
        guard let url = self.bundle?.url(forResource: "EMTAC-BTGPS", withExtension: "gpx") else {
            XCTFail("can't find file")
            return
        }
        let expectation = self.expectation(description: "EMTAC-BTGPS")
        GPXParser.parse(contentsOf: url) { (gpx, error) in
            guard let gpx = gpx else {
                XCTFail("gpx not created")
                return
            }
            XCTAssertEqual(gpx.version, "1.1")
            XCTAssertEqual(gpx.creator, "EMTAC BTGPS Trine II DataLog Dump 1.0 - http://www.ayeltd.biz")
            XCTAssertTrue(gpx.tracks?.count == 1, "wrong tracks count")
            guard let track = gpx.tracks?[0] else {
                XCTFail("wrong tracks count")
                return
            }
            XCTAssertTrue(track.segments.count == 1, "wrong segment count")
            let segment = track.segments[0]
            XCTAssertTrue(segment.points.count == 1, "wrong points count")
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 2)
    }
    
    func testRunkeeper() {
        guard let url = self.bundle?.url(forResource: "Runkeeper-waypoints-1.1", withExtension: "gpx") else {
            XCTFail("can't find file")
            return
        }
        let expectation = self.expectation(description: "Runkeeper")
        GPXParser.parse(contentsOf: url) { (gpx, error) in
            guard let gpx = gpx else {
                XCTFail("gpx not created")
                return
            }
            XCTAssertEqual(gpx.version, "1.1")
            XCTAssertEqual(gpx.creator, "Runkeeper - http://www.runkeeper.com")
            guard let waypoints = gpx.waypoints else {
                XCTFail("must have waypoints")
                return
            }
            XCTAssertTrue(waypoints.count == 6, "wrong waypoints count")
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 2)
    }
}
