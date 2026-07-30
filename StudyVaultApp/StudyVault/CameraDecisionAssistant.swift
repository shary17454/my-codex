import SwiftUI
import UIKit
import Vision

struct CameraDecisionDraft: Equatable {
    var title: String
    var details: String
    var primaryOption: String
    var tags: [String]
    var category: AskCategory
    var confidence: Double
    var recognizedText: [String]
}

@MainActor
final class CameraDecisionAssistant: ObservableObject {
    @Published private(set) var isAnalyzing = false
    @Published var errorMessage: String?

    func analyze(_ image: UIImage) async -> CameraDecisionDraft? {
        guard !isAnalyzing else { return nil }
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        do {
            return try await CameraDecisionAnalyzer.analyze(image)
        } catch {
            errorMessage = "تعذر تحليل الصورة. حاول بإضاءة أوضح أو قرّب الكاميرا من النص."
            return nil
        }
    }
}

enum CameraDecisionAnalyzer {
    static func analyze(_ image: UIImage) async throws -> CameraDecisionDraft {
        let preparedImage = image.preparingForDecisionAnalysis()
        guard let cgImage = preparedImage.cgImage else {
            throw CameraDecisionAnalyzerError.invalidImage
        }

        let recognizedText = try await recognizeText(in: cgImage)
        let cleanText = recognizedText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let keywords = extractKeywords(from: cleanText)
        let category = inferCategory(from: cleanText + keywords)
        let primaryOption = bestOptionName(from: cleanText, category: category)
        let title = makeTitle(primaryOption: primaryOption, category: category)
        let details = makeDetails(text: cleanText, category: category)
        let confidence = min(0.95, max(0.35, Double(cleanText.count) / 12.0))

        return CameraDecisionDraft(
            title: title,
            details: details,
            primaryOption: primaryOption,
            tags: Array(keywords.prefix(5)),
            category: category,
            confidence: confidence,
            recognizedText: Array(cleanText.prefix(8))
        )
    }

    private static func recognizeText(in image: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ar-SA", "en-US"]
            request.minimumTextHeight = 0.018

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func extractKeywords(from lines: [String]) -> [String] {
        let stopWords: Set<String> = [
            "من", "في", "على", "الى", "إلى", "عن", "هذا", "هذه", "مع", "او", "أو",
            "the", "and", "for", "with", "this", "that"
        ]

        let words = lines
            .joined(separator: " ")
            .replacingOccurrences(of: "[^\\p{Arabic}A-Za-z0-9\\s]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 3 && !stopWords.contains($0) }

        var counts: [String: Int] = [:]
        for word in words {
            counts[KnowledgeSearchIndex.normalize(word), default: 0] += 1
        }

        return counts
            .sorted {
                if $0.value == $1.value { return $0.key < $1.key }
                return $0.value > $1.value
            }
            .map(\.key)
    }

    private static func bestOptionName(from text: [String], category: AskCategory) -> String {
        let candidates = text
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 3 && $0.count <= 42 }

        if let candidate = candidates.first {
            return candidate
        }

        switch category {
        case .phones: return "الجهاز المصوّر"
        case .cars: return "السيارة المصوّرة"
        case .restaurants: return "الخيار المصوّر"
        case .laptops: return "الجهاز المصوّر"
        case .subscriptions: return "الاشتراك المصوّر"
        case .services: return "الخدمة المصوّرة"
        default: return "الخيار المصوّر"
        }
    }

    private static func makeTitle(primaryOption: String, category: AskCategory) -> String {
        switch category {
        case .phones, .laptops:
            return "\(primaryOption) أم بديل أفضل؟"
        case .cars:
            return "\(primaryOption) أم سيارة بديلة؟"
        case .restaurants:
            return "\(primaryOption) أم خيار مطعم آخر؟"
        case .subscriptions, .services:
            return "\(primaryOption) أم خدمة بديلة؟"
        default:
            return "\(primaryOption) أم خيار آخر؟"
        }
    }

    private static func makeDetails(text: [String], category: AskCategory) -> String {
        let detected = text.prefix(4).joined(separator: "، ")
        let base = "تم إنشاء هذه المسودة من صورة التقطتها بالكاميرا. عدّل العنوان والخيارات قبل النشر."
        guard !detected.isEmpty else {
            return "\(base) أحتاج مقارنة \(category.title) بناءً على السعر والجودة والتجربة."
        }
        return "\(base) النصوص المقروءة من الصورة: \(detected)."
    }

    private static func inferCategory(from values: [String]) -> AskCategory {
        let normalized = KnowledgeSearchIndex.normalize(values.joined(separator: " "))

        if normalized.contains("ايفون") || normalized.contains("سامسونج") || normalized.contains("جوال") || normalized.contains("هاتف") {
            return .phones
        }
        if normalized.contains("سياره") || normalized.contains("كامري") || normalized.contains("اكورد") || normalized.contains("تويوتا") {
            return .cars
        }
        if normalized.contains("مطعم") || normalized.contains("وجبه") || normalized.contains("قهوه") || normalized.contains("برجر") {
            return .restaurants
        }
        if normalized.contains("لابتوب") || normalized.contains("ماك") || normalized.contains("ويندوز") || normalized.contains("كمبيوتر") {
            return .laptops
        }
        if normalized.contains("اشتراك") || normalized.contains("باقه") || normalized.contains("نتفلكس") {
            return .subscriptions
        }
        if normalized.contains("خدمه") || normalized.contains("ضمان") || normalized.contains("صيانة") {
            return .services
        }

        return .other
    }
}

private enum CameraDecisionAnalyzerError: Error {
    case invalidImage
}

private extension UIImage {
    func preparingForDecisionAnalysis(maxDimension: CGFloat = 1280) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return self }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

struct WeshCameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onCapture: (UIImage) -> Void
        let onCancel: () -> Void

        init(onCapture: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let image = info[.originalImage] as? UIImage else {
                onCancel()
                return
            }
            onCapture(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

struct CameraDecisionAssistantCard: View {
    let isAnalyzing: Bool
    let errorMessage: String?
    let lastDraft: CameraDecisionDraft?
    let openCamera: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                WeshIconTile(systemImage: "camera.viewfinder", color: WeshTheme.gold, size: 48)

                VStack(alignment: .leading, spacing: 5) {
                    Text("كاميرا القرار")
                        .font(.headline)
                        .foregroundStyle(WeshTheme.primaryText)
                    Text("صوّر منتجًا أو إعلانًا أو قائمة، وسنقترح مسودة مقارنة قابلة للتعديل بتحليل محلي على الجهاز.")
                        .font(.subheadline)
                        .foregroundStyle(WeshTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let lastDraft {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("اقتراح جاهز")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WeshTheme.goldBright)
                        Spacer()
                        Text("\(Int((lastDraft.confidence * 100).rounded()))%")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WeshTheme.secondaryText)
                    }
                    Text(lastDraft.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WeshTheme.primaryText)
                }
                .padding(12)
                .background(WeshTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: WeshTheme.compactRadius))
            }

            if let errorMessage {
                WeshStatusBanner(text: errorMessage, kind: .warning)
            }

            Button {
                openCamera()
            } label: {
                if isAnalyzing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label("التقط وحلّل", systemImage: "sparkles")
                }
            }
            .buttonStyle(WeshGoldButtonStyle())
            .disabled(isAnalyzing)
            .accessibilityLabel("فتح كاميرا القرار وتحليل الصورة")
        }
        .weshSurface(goldAccent: true)
    }
}
