import UIKit
import PhotosUI
import StoreKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, PHPickerViewControllerDelegate {
    private var webView: WKWebView!
    private let catalogAccessProductID = "batal.catalog.unlock"
    private let allowedProductIDs: Set<String> = [
        "batal.catalog.unlock",
        "batal.parts.request.basic",
        "batal.parts.request.urgent",
        "batal.parts.request.rare"
    ]
    private lazy var privacyShield: UIView = {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.02, green: 0.03, blue: 0.03, alpha: 1)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isHidden = true

        let title = UILabel()
        title.text = "المحتوى محمي"
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = .white
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()
        subtitle.text = "تم حجب الكتالوج أثناء تسجيل الشاشة أو العرض الخارجي."
        subtitle.font = .systemFont(ofSize: 16, weight: .semibold)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.72)
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -28)
        ])

        return container
    }()

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController.add(self, name: "batalStore")
        configuration.userContentController.add(self, name: "batalMedia")
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        installPrivacyShield()
        installCaptureObservers()
        loadBundledApp()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "batalStore")
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "batalMedia")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            return
        }

        if message.name == "batalMedia", action == "choosePhoto" {
            presentPhotoPicker()
            return
        }

        guard message.name == "batalStore" else { return }

        if action == "purchaseAccess" {
            let productID = (body["productId"] as? String) ?? catalogAccessProductID
            guard allowedProductIDs.contains(productID) else {
                sendPurchaseResult(status: "unavailable", message: "Unsupported product")
                return
            }
            Task { await purchaseProduct(productID: productID) }
        }
    }

    private func presentPhotoPicker() {
        guard presentedViewController == nil else { return }

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .formSheet
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else {
            sendJavaScriptCallback("window.BatalNativeMedia?.cancelled?.()")
            return
        }

        let photoName = provider.suggestedName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeName = (photoName?.isEmpty == false ? photoName : nil) ?? "part-photo"
        guard let data = try? JSONSerialization.data(withJSONObject: safeName),
              let json = String(data: data, encoding: .utf8) else {
            return
        }
        sendJavaScriptCallback("window.BatalNativeMedia?.receivePhotoName?.(\(json))")
    }

    private func installPrivacyShield() {
        view.addSubview(privacyShield)
        NSLayoutConstraint.activate([
            privacyShield.topAnchor.constraint(equalTo: view.topAnchor),
            privacyShield.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            privacyShield.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            privacyShield.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func installCaptureObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: UIScreen.main
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showPrivacyShield),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        updatePrivacyShield(isCaptured: UIScreen.main.isCaptured)
    }

    @objc private func screenCaptureChanged() {
        updatePrivacyShield(isCaptured: UIScreen.main.isCaptured)
    }

    @objc private func screenshotTaken() {
        sendJavaScriptCallback("window.BatalNativeStore?.screenshotTaken?.()")
        temporarilyShowPrivacyShield()
    }

    @objc private func showPrivacyShield() {
        privacyShield.isHidden = false
    }

    @objc private func appBecameActive() {
        updatePrivacyShield(isCaptured: UIScreen.main.isCaptured)
    }

    private func updatePrivacyShield(isCaptured: Bool) {
        privacyShield.isHidden = !isCaptured
        sendJavaScriptCallback("window.BatalNativeStore?.screenCaptureChanged?.(\(isCaptured ? "true" : "false"))")
    }

    private func temporarilyShowPrivacyShield() {
        privacyShield.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.updatePrivacyShield(isCaptured: UIScreen.main.isCaptured)
        }
    }

    @MainActor
    private func purchaseProduct(productID: String) async {
        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first else {
                sendPurchaseResult(status: "unavailable", message: "Product not found")
                return
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    sendPurchaseResult(status: "success", message: "Purchased")
                case .unverified:
                    sendPurchaseResult(status: "failed", message: "Transaction verification failed")
                }
            case .userCancelled:
                sendPurchaseResult(status: "cancelled", message: "Cancelled")
            case .pending:
                sendPurchaseResult(status: "pending", message: "Pending")
            @unknown default:
                sendPurchaseResult(status: "failed", message: "Unknown purchase result")
            }
        } catch {
            sendPurchaseResult(status: "failed", message: error.localizedDescription)
        }
    }

    @MainActor
    private func sendPurchaseResult(status: String, message: String) {
        let payload: [String: String] = ["status": status, "message": message]
        guard
            let data = try? JSONSerialization.data(withJSONObject: payload),
            let json = String(data: data, encoding: .utf8)
        else {
            return
        }
        sendJavaScriptCallback("window.BatalNativeStore?.receive?.(\(json))")
    }

    private func sendJavaScriptCallback(_ script: String) {
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(script)
        }
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
