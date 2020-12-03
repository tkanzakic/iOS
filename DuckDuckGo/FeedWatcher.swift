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
import FeedKit

class FeedWatcher {

    struct Feed {

        let domain: String
        let url: URL
        let info: FeedInfo?

    }

    struct FeedInfo {

        let lastId: String
        let count: Int

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
        feeds[domain] = Feed(domain: domain, url: feedURL, info: nil)
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

        func complete(count: Int?) {
            DispatchQueue.main.async {
                completion(count)
            }
        }

        let task = URLSession.shared.dataTask(with: feed.url) { data, _, _ in
            guard let data = data,
                  let feedInfo = data.parse(withLastId: feed.info?.lastId),
                  feedInfo.lastId != feed.info?.lastId else {
                complete(count: nil)
                return
            }

            self.feeds[domain] = Feed(domain: domain, url: feed.url, info: feedInfo)
            complete(count: feedInfo.count)
        }
        task.resume()
    }

}

extension Data {

    func parse(withLastId lastId: String?) -> FeedWatcher.FeedInfo? {
        switch FeedParser(data: self).parse() {
        case .success(let feed):
            return process(feed: feed, withId: lastId)
        default: return nil
        }
    }

    private func process(feed: Feed, withId lastId: String?) -> FeedWatcher.FeedInfo? {
        switch feed {
        case .json(let jsonFeed):
            return processJSON(feed: jsonFeed, withId: lastId)

        case .atom(let atomFeed):
            return processAtom(feed: atomFeed, withId: lastId)

        case .rss(let rssFeed):
            return processRSS(feed: rssFeed, withId: lastId)
        }
    }

    private func processJSON(feed: JSONFeed, withId lastId: String?) -> FeedWatcher.FeedInfo? {
        guard let ids = feed.items?.compactMap({ $0.id }) else { return nil }
        return processIds(ids, withId: lastId)
    }

    private func processAtom(feed: AtomFeed, withId lastId: String?) -> FeedWatcher.FeedInfo? {
        guard let ids = feed.entries?.compactMap({ $0.id }) else { return nil }
        return processIds(ids, withId: lastId)
    }

    private func processRSS(feed: RSSFeed, withId lastId: String?) -> FeedWatcher.FeedInfo? {
        guard let ids = feed.items?.compactMap({ $0.guid?.value }) else { return nil }
        return processIds(ids, withId: lastId)
    }

    private func processIds(_ ids: [String], withId lastId: String?) -> FeedWatcher.FeedInfo? {
        guard let id = ids.first else { return nil }

        var count = 0
        while lastId != ids[count] {
            count += 1
            if count >= ids.count {
                break
            }
        }

        return .init(lastId: id, count: count)
    }

}
