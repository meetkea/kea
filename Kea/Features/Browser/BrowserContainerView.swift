import AppKit
import SwiftUI
import WebKit

struct BrowserContainerView: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WebViewHost {
        let host = WebViewHost()
        host.attach(webView)
        return host
    }

    func updateNSView(_ host: WebViewHost, context: Context) {
        host.attach(webView)
    }

    static func dismantleNSView(_ host: WebViewHost, coordinator: Void) {
        host.detach()
    }
}

final class WebViewHost: NSView {
    private weak var hostedWebView: WKWebView?

    func attach(_ webView: WKWebView) {
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
    let session: BrowserSession

    var body: some View {
        ZStack(alignment: .top) {
            BrowserContainerView(webView: session.webView)

            if session.state.isLoading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .controlSize(.small)
                    .transition(.opacity)
            }

            if let error = session.state.errorMessage, !session.state.isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                    Text(error)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        session.webView.reload()
                    }
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
