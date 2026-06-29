import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView!

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadBundledApp()
    }

    private func loadBundledApp() {
        guard
            let webDirectory = Bundle.main.url(forResource: "Web", withExtension: nil),
            let indexURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web")
        else {
            showMissingBundleMessage()
            return
        }

        webView.loadFileURL(indexURL, allowingReadAccessTo: webDirectory)
    }

    private func showMissingBundleMessage() {
        let html = """
        <html dir="rtl" lang="ar">
          <body style="font-family: -apple-system; padding: 24px;">
            <h1>بطل الدروب</h1>
            <p>تعذر تحميل ملفات التطبيق المضمنة.</p>
          </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
