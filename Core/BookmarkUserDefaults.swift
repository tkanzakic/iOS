//
//  BookmarkUserDefaults.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
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

public class BookmarkUserDefaults: BookmarkStore {

    public struct Constants {
        public static let groupName = "\(Global.groupIdPrefix).bookmarks"
    }

    private struct Keys {
        static let bookmarkKey = "com.duckduckgo.bookmarks.bookmarkKey"
        static let favoritesKey = "com.duckduckgo.bookmarks.favoritesKey"
    }

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = UserDefaults(suiteName: Constants.groupName)!) {
        self.userDefaults = userDefaults
    }

    struct JsonBookmark: Codable {

        let title: String?
        let url: String
        let favorite: Bool

    }

    public var json: String? {
        let jsonBookmarks = bookmarks.map { JsonBookmark(title: $0.displayTitle, url: $0.url.absoluteString, favorite: false)}
        let jsonFavorites = favorites.map { JsonBookmark(title: $0.displayTitle, url: $0.url.absoluteString, favorite: true)}
        guard let data = try? JSONEncoder().encode(jsonBookmarks + jsonFavorites) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public var bookmarks: [Link] {
        get {
            if let data = userDefaults.data(forKey: Keys.bookmarkKey) {
                return NSKeyedUnarchiver.unarchiveObject(with: data) as? [Link] ?? []
            }
            return []
        }
        set(newBookmarks) {
            let data = NSKeyedArchiver.archivedData(withRootObject: newBookmarks)
            userDefaults.set(data, forKey: Keys.bookmarkKey)
        }
    }

    public var favorites: [Link] {
        get {
            if let data = userDefaults.data(forKey: Keys.favoritesKey) {
                return NSKeyedUnarchiver.unarchiveObject(with: data) as? [Link] ?? []
            }
            return []
        }
        set(newFavorites) {
            let data = NSKeyedArchiver.archivedData(withRootObject: newFavorites)
            userDefaults.set(data, forKey: Keys.favoritesKey)
        }
    }

    public func addBookmark(_ bookmark: Link) {
        var newBookmarks = bookmarks
        newBookmarks.append(bookmark)
        bookmarks = newBookmarks
    }
    
    public func addFavorite(_ favorite: Link) {
        var newFavorites = favorites
        newFavorites.append(favorite)
        favorites = newFavorites
    }

    public func importJson(json: String) {
        guard let data = json.data(using: .utf8) else { return }
        guard let bookmarks = try? JSONDecoder().decode([JsonBookmark].self, from: data) else { return }

        bookmarks.forEach { bookmark in
            guard let url = URL(string: bookmark.url) else { return }
            let link = Link(title: bookmark.title, url: url)
            if bookmark.favorite {
                addFavorite(link)
            } else {
                addBookmark(link)
            }
        }

    }

}
