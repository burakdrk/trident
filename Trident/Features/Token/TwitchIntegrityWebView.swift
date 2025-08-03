//
//  TwitchIntegrityWebView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-28.
//

import SwiftUI
import WebKit

typealias TokenReceiveHandler = (Result<IntegrityResponse, Error>) -> Void

struct TwitchIntegrityWebView: UIViewRepresentable {
    let onTokenReceived: TokenReceiveHandler
    let endpoint = "https://www.twitch.tv/settings"
    let integrityEndpoint = "https://gql.twitch.tv/integrity"
    let scriptSrc =
        "https://k.twitchcdn.net/149e9513-01fa-4fb0-aad4-566afd725d1b/2d206a39-8ed7-437e-a3be-862e0f06eea3/p.js"
    let clientID = "kimne78kx3ncx6brgo4mv6wki5h1ko"

    var deviceID: String {
        let charset = Array(
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        )
        return String(
            (0..<32).compactMap { _ in charset.randomElement() }
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onTokenReceived: onTokenReceived,
            clientID: clientID,
            deviceID: deviceID,
            scriptSrc: scriptSrc,
            integrityEndpoint: integrityEndpoint
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        config.userContentController = contentController

        let contentRulesList = """
                [{"trigger": { "url-filter": ".*" }, "action": { "type": "block" }},
                {"trigger": { "url-filter": "\(endpoint)" }, "action": { "type": "ignore-previous-rules" }},
                {"trigger": { "url-filter": "\(scriptSrc)" }, "action": { "type": "ignore-previous-rules" }},
                {"trigger": { "url-filter": "\(integrityEndpoint)" }, "action": { "type": "ignore-previous-rules" }}]
            """

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "TwitchRules",
            encodedContentRuleList: contentRulesList
        ) { ruleList, error in
            if let ruleList = ruleList {
                config.userContentController.add(ruleList)
            }
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isInspectable = true

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let url = URL(string: endpoint)!
        let request = URLRequest(url: url)
        uiView.load(request)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onTokenReceived: TokenReceiveHandler
        let clientID: String
        let deviceID: String
        let scriptSrc: String
        let integrityEndpoint: String

        init(
            onTokenReceived: @escaping TokenReceiveHandler,
            clientID: String,
            deviceID: String,
            scriptSrc: String,
            integrityEndpoint: String
        ) {
            self.onTokenReceived = onTokenReceived
            self.clientID = clientID
            self.deviceID = deviceID
            self.scriptSrc = scriptSrc
            self.integrityEndpoint = integrityEndpoint
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
        {
            let js = """
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
                        const headers = Object.assign({"Client-ID": "\(self.clientID)"}, {"x-device-id": "\(self.deviceID)"});
                        const resp = await window.fetch("\(self.integrityEndpoint)", {
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
                    script.src = "\(self.scriptSrc)";
                    document.body.appendChild(script);
                });
                await p;
                return p;
                """

            webView.callAsyncJavaScript(
                js,
                in: nil,
                in: .page,
                completionHandler: { result in
                    switch result {
                    case .success(let val):
                        do {
                            guard let jsonString = val as? String else {
                                return
                            }
                            guard let data = jsonString.data(using: .utf8)
                            else { return }

                            let integrityResponse = try JSONDecoder().decode(
                                IntegrityResponse.self,
                                from: data
                            )

                            self.onTokenReceived(.success(integrityResponse))
                        } catch let err {
                            self.onTokenReceived(.failure(err))
                        }
                    case .failure(let err):
                        self.onTokenReceived(.failure(err))
                    }
                }
            )

        }
    }
}

#Preview {
    TwitchIntegrityWebView(onTokenReceived: { _ in
        // noop
    })
}
