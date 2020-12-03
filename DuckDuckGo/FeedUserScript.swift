//
//  FeedUserScript.swift
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

import WebKit
import Core

class FeedUserScript: NSObject, UserScript {

    public var source: String = """

(function() {

    function findFeeds() {

         var selectors = [
            "link[type='application/json']",
            "link[type='application/atom+xml']"
        ];

        var feeds = [];
        while (selectors.length > 0) {
            var selector = selectors.pop()
            var feedLinks = document.head.querySelectorAll(selector);
            for (var i = 0; i < feedLinks.length; i++) {
                var href = feedLinks[i].href;
                feeds.push(href)
            }
        }
        return feeds;
    };

    try {
        webkit.messageHandlers.feedsFound.postMessage(findFeeds());
    } catch(error) {
        // webkit might not be defined
    }

}) ();

"""

    var injectionTime: WKUserScriptInjectionTime = .atDocumentEnd

    var forMainFrameOnly: Bool = true

    var messageNames: [String] = [ "feedsFound" ]

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("***", #function, message.body)
        guard let feeds = message.body as? [String],
              !feeds.isEmpty,
              let feedUrl = URL(string: feeds[0]),
              let domain = message.webView?.url?.host else { return }

        print("***", #function, feeds)
        FeedWatcher.shared.registerFeed(forDomain: domain, atLocation: feedUrl)
    }

}
