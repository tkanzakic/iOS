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

    struct Feed {

        let domain: String
        let url: URL
        let lastId: String?

    }

    struct FeedInfo {

        let lastId: String
        let itemCount: Int

    }

    static let shared = FeedWatcher()

    private var temporary = [String: URL]()

    private var feeds = [String: Feed]()

    private init() { }

    /// Keep the feed URL in memory only.
    func registerFeed(forDomain domain: String, atLocation feedLocation: URL) {
        print("***", #function, domain, feedLocation)
        guard !feeds.keys.contains(domain) else { return }
        temporary[domain] = feedLocation
    }

    /// Persist any feed URL for this domain
    func commitFeed(forDomain domain: String) {
        guard let feedURL = temporary[domain] else { return }
        temporary.removeValue(forKey: domain)
        feeds[domain] = Feed(domain: domain, url: feedURL, lastId: nil)
    }

    /// Remove any feed URL for this domain
    func unregisterFeed(forDomain domain: String) {
        temporary.removeValue(forKey: domain)
        feeds.removeValue(forKey: domain)
    }

    /// Quickly check if there's a feed URL for this domain
    func hasFeed(forDomain domain: String) -> Bool {
        return temporary.keys.contains(domain) || feeds.keys.contains(domain)
    }

    /// Start checking the feed to see if there's new content
    func checkFeed(forDomain domain: String, completion: @escaping (Int?) -> Void) {
        guard let feed = feeds[domain] else { return }
        let task = URLSession.shared.dataTask(with: feed.url) { data, _, _ in
            guard let data = data,
                  let feedInfo = data.parse(lastId: feed.lastId),
                  feedInfo.lastId != feed.lastId else {
                completion(nil)
                return
            }

            completion(feedInfo.itemCount)
        }
        task.resume()
    }

}

extension Data {

    func parse(lastId: String?) -> FeedWatcher.FeedInfo? {

        if let info = decodeJson(lastId) {
            return info
        }

//        if let info = decodeAtom(lastId) {
//            return info
//        }

        return nil
    }

    private func decodeJson(_ lastId: String?) -> FeedWatcher.FeedInfo? {

        // assume they are in order, newest first
        // swiftlint:disable nesting
        struct JSONFeed: Decodable {
            struct Item: Decodable {
                let id: String
            }
            let items: [Item]
        }
        // swiftlint:enable nesting

        guard let feed = try? JSONDecoder().decode(JSONFeed.self, from: self),
              let firstId = feed.items.first?.id else { return nil }

        var count = 0
        while lastId != feed.items[count].id {
            count += 1

            if count >= feed.items.count {
                break   
            }
        }

        return .init(lastId: firstId, itemCount: count)
    }

}
