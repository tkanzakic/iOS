//
//  FeedWatcherTests.swift
//  DuckDuckGo
//
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
@testable import DuckDuckGo

class FeedWatcherTests: XCTestCase {

    func test() {

        let domain = "daringfireball.net"
        let url = URL(string: "https://daringfireball.net/feeds/json")!
        FeedWatcher.shared.registerFeed(forDomain: domain, atLocation: url)
        FeedWatcher.shared.commitFeed(forDomain: domain)

        let ex = expectation(description: "checkFeed")
        FeedWatcher.shared.checkFeed(forDomain: domain) {
            XCTAssertTrue($0 ?? 0 > 0)
            ex.fulfill()
        }

        wait(for: [ex], timeout: 10)
    }

}
