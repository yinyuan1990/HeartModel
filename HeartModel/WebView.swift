//
//  WebView.swift
//  HeartModel
//

import SwiftUI
import WebKit

/// 一次加载请求。每次点击「加载」都会生成新的 id，即使网址相同也会重新加载。
struct WebLoadRequest {
    let id = UUID()
    let url: URL
}

/// 包装 WKWebView 供 SwiftUI 使用
struct WebView: UIViewRepresentable {
    let request: WebLoadRequest
    let iosVersion: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // 把 iOS 版本号注入到网页中，网页可通过 window.iOSVersion 读取
        let script = WKUserScript(
            source: "window.iOSVersion = \"\(iosVersion)\";",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(script)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self

        // 只有新的加载请求才触发加载，避免 SwiftUI 刷新时重复加载
        guard context.coordinator.lastRequestID != request.id else { return }
        context.coordinator.lastRequestID = request.id
        webView.load(URLRequest(url: request.url))
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var lastRequestID: UUID?

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.errorMessage = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        private func handle(_ error: Error) {
            parent.isLoading = false
            let nsError = error as NSError
            // 新请求打断旧请求时会返回取消错误，不需要提示
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                return
            }
            parent.errorMessage = "加载失败：\(error.localizedDescription)"
        }
    }
}
