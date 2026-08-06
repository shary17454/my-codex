import PDFKit
import SwiftUI

struct PDFMapView: UIViewRepresentable {
    let documentURLs: [URL]
    @Binding var selectedDocumentIndex: Int

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        pdfView.minScaleFactor = 0.35
        pdfView.maxScaleFactor = 8
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        guard !documentURLs.isEmpty else {
            pdfView.document = nil
            return
        }

        let safeIndex = min(max(selectedDocumentIndex, 0), documentURLs.count - 1)
        let documentURL = documentURLs[safeIndex]
        guard context.coordinator.currentDocumentURL != documentURL else { return }

        pdfView.document = PDFDocument(url: documentURL)
        context.coordinator.currentDocumentURL = documentURL

        DispatchQueue.main.async {
            configureInitialZoom(for: pdfView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func configureInitialZoom(for pdfView: PDFView) {
        guard
            let page = pdfView.document?.page(at: 0),
            pdfView.bounds.width > 0,
            pdfView.bounds.height > 0
        else { return }

        pdfView.autoScales = true
        let fitScale = pdfView.scaleFactorForSizeToFit
        let pageBounds = page.bounds(for: .mediaBox)
        let fittedPageHeight = pageBounds.height * fitScale
        let fillHeightScale = pdfView.bounds.height / max(fittedPageHeight, 1)
        let initialScale = pageBounds.width > pageBounds.height ? min(fitScale * fillHeightScale, fitScale * 3.0) : fitScale

        pdfView.autoScales = false
        pdfView.minScaleFactor = max(fitScale * 0.8, 0.2)
        pdfView.maxScaleFactor = max(fitScale * 8.0, 8.0)
        pdfView.scaleFactor = max(initialScale, pdfView.minScaleFactor)
        pdfView.go(to: page)

        if let scrollView = firstScrollView(in: pdfView) {
            let centeredX = max((scrollView.contentSize.width - scrollView.bounds.width) / 2, 0)
            scrollView.setContentOffset(CGPoint(x: centeredX, y: 0), animated: false)
        }
    }

    private func firstScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        for subview in view.subviews {
            if let scrollView = firstScrollView(in: subview) {
                return scrollView
            }
        }
        return nil
    }

    final class Coordinator {
        var currentDocumentURL: URL?
    }
}
