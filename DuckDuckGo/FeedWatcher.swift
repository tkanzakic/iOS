//
//  FeedWatcher.swift
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

import Foundation

class FeedWatcher {

    static let shared = FeedWatcher()

    private init() { }

    /// Keep the feed URL in memory only.
    func registerFeed(forDomain domain: String, atLocation feedLocation: URL) {
        print("***", #function, domain, feedLocation)
    }

    /// Persist any feed URL for this domain
    func commitFeed(forDomain domain: String) {
    }

    /// Remove any feed URL for this domain
    func unregisterFeed(forDomain domain: String) {
    }

    /// Quickly check if there's a feed URL for this domain
    func hasFeed(forDomain domain: String) -> Bool {
        return false
    }

    /// Start checking the feed to see if there's new content
    func checkFeed(forDomain domain: String, completion: @escaping (Int) -> Void) {
    }

}
