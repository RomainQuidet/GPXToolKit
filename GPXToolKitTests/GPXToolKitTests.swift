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
        
        self.wait(for: [expectation], timeout: 5)
    }
}
