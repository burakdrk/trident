//
//  TwitchIntegrityFetcher.swift
//  TridentPlus
//
//  Created by Burak Duruk on 2025-07-28.
//

import WebKit

final class TwitchIntegrityFetcher: NSObject, WKNavigationDelegate {
  typealias TokenReceiveHandler = (Result<IntegrityResponse, Error>) -> Void

  private static let endpoint = "https://www.twitch.tv/settings"
  private static let scriptSrc =
    "https://k.twitchcdn.net/149e9513-01fa-4fb0-aad4-566afd725d1b/2d206a39-8ed7-437e-a3be-862e0f06eea3/p.js"

  private let clientID = "kimne78kx3ncx6brgo4mv6wki5h1ko"
  private var deviceID = String.randomAlphanumeric(length: 32)

  private let onTokenReceived: TokenReceiveHandler
  private let webView: WKWebView

  init(onTokenReceived: @escaping TokenReceiveHandler) {
    webView = WKWebView(
      frame: .zero,
      configuration: TwitchIntegrityFetcher.makeConfig()
    )
    self.onTokenReceived = onTokenReceived
    super.init()
    webView.navigationDelegate = self
    webView.isInspectable = true
  }

  func start() {
    guard let url = URL(string: TwitchIntegrityFetcher.endpoint) else {
      onTokenReceived(.failure(URLError(.badURL)))
      return
    }
    let request = URLRequest(url: url)
    webView.load(request)
  }

  func webView(_ webView: WKWebView, didFinish _: WKNavigation) {
    webView.callAsyncJavaScript(
      makeJS,
      in: nil,
      in: .page,
      completionHandler: { result in
        switch result {
        case let .success(val):
          do {
            guard let jsonString = val as? String else {
              return
            }
            guard let data = jsonString.data(using: .utf8) else {
              return
            }

            let integrityResponse = try JSONDecoder().decode(
              IntegrityResponse.self,
              from: data
            )

            self.onTokenReceived(.success(integrityResponse))
          } catch let err {
            self.onTokenReceived(.failure(err))
          }
        case let .failure(err):
          self.onTokenReceived(.failure(err))
        }
      }
    )
  }

  func webView(_: WKWebView, didFail _: WKNavigation, withError error: Error) {
    onTokenReceived(.failure(error))
  }

  // MARK: - Private Helpers

  private static func makeConfig() -> WKWebViewConfiguration {
    let config = WKWebViewConfiguration()
    let contentController = WKUserContentController()
    config.userContentController = contentController

    let contentRulesList = """
          [{"trigger": { "url-filter": ".*" }, "action": { "type": "block" }},
          {"trigger": { "url-filter": "\(endpoint)" }, "action": { "type": "ignore-previous-rules" }},
          {"trigger": { "url-filter": "\(scriptSrc)" }, "action": { "type": "ignore-previous-rules" }},
          {"trigger": { "url-filter": "https://gql.twitch.tv" }, "action": { "type": "ignore-previous-rules" }}]
      """

    WKContentRuleListStore.default().compileContentRuleList(
      forIdentifier: "TwitchRules",
      encodedContentRuleList: contentRulesList
    ) { ruleList, _ in
      if let ruleList = ruleList {
        config.userContentController.add(ruleList)
      }
    }

    return config
  }

  private var makeJS: String {
    """
    var p = new Promise((resolve, reject) => {
        function configureKPSDK() {
            window.KPSDK.configure([{
                "protocol": "https:",
                "method": "POST",
                "domain": "gql.twitch.tv",
                "path": "/integrity"
            }]);
        }

        async function fetchIntegrity() {
            const headers = Object.assign({"Client-ID": "\(clientID)"}, {"x-device-id": "\(deviceID)"});
            const resp = await window.fetch("https://gql.twitch.tv/integrity", {
                "headers": headers,
                "body": null,
                "method": "POST",
                "mode": "cors",
                "credentials": "omit"
            });

            if (resp.status !== 200) {
                throw new Error(`Unexpected integrity response status code ${resp.status}`);
            }

            return JSON.stringify(await resp.json());
        }


        document.addEventListener("kpsdk-load", configureKPSDK, {once: true});
        document.addEventListener("kpsdk-ready", () => fetchIntegrity().then(resolve, reject), {once: true});

        const script = document.createElement("script");
        script.addEventListener("error", reject);
        script.src = "\(TwitchIntegrityFetcher.scriptSrc)";
        document.body.appendChild(script);
    });
    await p;
    return p;
    """
  }
}
