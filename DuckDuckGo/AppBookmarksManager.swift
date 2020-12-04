//
//  AppBookmarksManager.swift
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

import Core
import WidgetKit

class AppBookmarksManager: BookmarksManager {

    override func save(favorite: Link) {
        super.save(favorite: favorite)
        reloadWidgets()
        commitFeed(forFavorite: favorite)
    }

    override func moveFavorite(at fromIndex: Int, to toIndex: Int) {
        super.moveFavorite(at: fromIndex, to: toIndex)
        reloadWidgets()
    }

    override func moveFavorite(at favoriteIndex: Int, toBookmark bookmarkIndex: Int) {
        super.moveFavorite(at: favoriteIndex, toBookmark: bookmarkIndex)
        reloadWidgets()
    }

    override func moveBookmark(at fromIndex: Int, to toIndex: Int) {
        super.moveFavorite(at: fromIndex, to: toIndex)
        reloadWidgets()
    }

    override func deleteFavorite(at index: Int) {
        super.deleteFavorite(at: index)
        reloadWidgets()
    }

    override func updateFavorite(at index: Int, with link: Link) {
        super.updateFavorite(at: index, with: link)
        reloadWidgets()
    }

    func commitFeed(forFavorite favorite: Link) {
        guard let domain = favorite.url.host else { return }
        FeedWatcher.shared.commitFeed(forDomain: domain)
    }

    func reloadWidgets() {
        if #available(iOS 14, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

}
