//
//  ContentView.swift
//  HeartModel
//
//  Created by 陈源 on 10/15/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    /// 记住上次输入的网址
    @AppStorage("lastURL") private var urlText: String = ""
    @State private var loadRequest: WebLoadRequest?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isURLFieldFocused: Bool

    /// 当前设备的 iOS 版本号，例如 "17.5"
    private var iosVersion: String {
        UIDevice.current.systemVersion
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("iOS 版本：\(iosVersion)")
                    .font(.headline)
                Spacer()
                if isLoading {
                    ProgressView()
                }
            }

            HStack {
                TextField("输入网址，例如 https://example.com", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.go)
                    .focused($isURLFieldFocused)
                    .onSubmit(load)

                Button("加载", action: load)
                    .buttonStyle(.borderedProminent)
                    .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        if let loadRequest {
            WebView(
                request: loadRequest,
                iosVersion: iosVersion,
                isLoading: $isLoading,
                errorMessage: $errorMessage
            )
        } else {
            VStack {
                Spacer()
                Text("输入网址后点击「加载」")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func load() {
        guard let url = Self.normalizedURL(from: urlText) else {
            errorMessage = "网址格式不正确，仅支持 http / https"
            return
        }
        errorMessage = nil
        urlText = url.absoluteString
        isURLFieldFocused = false
        loadRequest = WebLoadRequest(url: url)
    }

    /// 补全协议头并校验网址，只允许 http / https
    static func normalizedURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let withScheme = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard
            let url = URL(string: withScheme),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            url.host != nil
        else {
            return nil
        }
        return url
    }
}

#Preview {
    ContentView()
}
