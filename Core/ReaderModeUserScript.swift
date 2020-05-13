//
//  ReaderModeUserScript.swift
//  DuckDuckGo
//
//  Created by Christopher Brind on 12/05/2020.
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//

import Foundation
import WebKit

// swiftlint:disable type_body_length
public class ReaderModeUserScript: NSObject, UserScript {

    public var source: String {
        return loadJS("readability")
    }

    public let injectionTime: WKUserScriptInjectionTime = .atDocumentEnd

    public var forMainFrameOnly: Bool = true

    public var messageNames: [String] = [
        "canRead",
        "readableArticle"
    ]

    public private(set) var canRead: Bool = false

    public weak var webView: WKWebView?

    let css = """

    * {
        font-family: -apple-system-font;
        font-size: 1em;
    }

    img {
        margin: 0.5em auto;
        display: block;
        height: auto;
        max-width: 100%;
    }

    .title {
        font-size: 1.3em;
    }

    .info {
        font-size: 0.7em;
    }

"""

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any] else { return }

        switch message.name {

        case "canRead":
            canRead = dict["canRead"] as? Bool ?? false
            print("***", #function, canRead)

        case "readableArticle":
            guard let content = dict["content"] as? String else { return }
            guard let title = dict["title"] as? String else { return }
            guard let url = webView?.url?.absoluteString else { return }
            webView?.loadHTMLString("""
                <html>
                    <head>
                        <meta name=\"viewport\" content=\"initial-scale=1\" />
                        <base href=\"\(url)\" />
                        <style>\(css)</style>
                    </head>
                    <body>
                        <h1 class="title">\(title)</h1>
                        <span class="info">(Refresh page to leave reader mode)</span>
                        \(content)
                    </body>
                </html>
                """, baseURL: webView?.url)

        default: break
        }

    }

    public func makeReadable() {
        webView?.evaluateJavaScript("duckduckgoReadability.makeReadable()") { result, error in
            print("***", result as Any, error as Any)
        }
    }

}
// swiftlint:enable type_body_length
