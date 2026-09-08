import AppKit
import SwiftUI
import WebKit

@MainActor
final class WeakWebViewReference {
    weak var webView: WKWebView?

    init(_ webView: WKWebView) {
        self.webView = webView
    }
}

struct BrowserContainerView: NSViewRepresentable {
    let reference: WeakWebViewReference

    init(webView: WKWebView) {
        reference = WeakWebViewReference(webView)
    }

    init(reference: WeakWebViewReference) {
        self.reference = reference
    }

    func makeNSView(context: Context) -> WebViewHost {
        let host = WebViewHost()
        host.attach(reference.webView)
        return host
    }

    func updateNSView(_ host: WebViewHost, context: Context) {
        host.attach(reference.webView)
    }

    static func dismantleNSView(_ host: WebViewHost, coordinator: Void) {
        host.detach()
    }
}

final class WebViewHost: NSView {
    private weak var hostedWebView: WKWebView?

    func attach(_ webView: WKWebView?) {
        guard let webView else {
            detach()
            return
        }
        guard hostedWebView !== webView else { return }
        detach()

        hostedWebView = webView
        webView.removeFromSuperview()
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func detach() {
        hostedWebView?.removeFromSuperview()
        hostedWebView = nil
    }
}

struct BrowserPane: View {
    let state: BrowserState
    private let webViewReference: WeakWebViewReference

    init(session: BrowserSession) {
        state = session.state
        webViewReference = WeakWebViewReference(session.webView)
    }

    var body: some View {
        ZStack(alignment: .top) {
            BrowserContainerView(reference: webViewReference)

            if state.isLoading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .controlSize(.small)
                    .transition(.opacity)
            }

            if let error = state.errorMessage, !state.isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                    Text(error)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        webViewReference.webView?.reload()
                    }
                    .accessibilityHint("Reloads X for this account")
                }
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                .shadow(radius: 18, y: 6)
                .frame(maxWidth: 360)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
