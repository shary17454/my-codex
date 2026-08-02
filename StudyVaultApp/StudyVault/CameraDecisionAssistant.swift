import SwiftUI
import UIKit
import Vision

struct CameraDecisionDraft: Equatable {
    var title: String
    var details: String
    var primaryOption: String
    var optionSuggestions: [String]
    var suggestedCriteria: [String]
    var tags: [String]
    var category: AskCategory
    var confidence: Double
    var recognizedText: [String]

    init(
        title: String,
        details: String,
        primaryOption: String,
        optionSuggestions: [String] = [],
        suggestedCriteria: [String] = [],
        tags: [String],
        category: AskCategory,
        confidence: Double,
        recognizedText: [String]
    ) {
        self.title = title
        self.details = details
        self.primaryOption = primaryOption
        self.optionSuggestions = optionSuggestions
        self.suggestedCriteria = suggestedCriteria
        self.tags = tags
        self.category = category
        self.confidence = confidence
        self.recognizedText = recognizedText
    }
}

@MainActor
final class CameraDecisionAssistant: ObservableObject {
    @Published private(set) var isAnalyzing = false
    @Published var errorMessage: String?
    @Published private(set) var usedBackend = false

    private let backendClient: WeshAlrayAPIClient?

    init(backendClient: WeshAlrayAPIClient? = nil) {
        self.backendClient = backendClient
    }

    func analyze(_ image: UIImage) async -> CameraDecisionDraft? {
        guard !isAnalyzing else { return nil }
        isAnalyzing = true
        errorMessage = nil
        usedBackend = false
        defer { isAnalyzing = false }

        do {
            let recognizedText = try await CameraDecisionAnalyzer.recognizeText(from: image)
            let localDraft = CameraDecisionAnalyzer.makeDraft(fromRecognizedText: recognizedText)
            guard let backendClient else {
                return localDraft
            }

            do {
                let remoteDraft = try await backendClient.createCameraDecisionDraft(
                    recognizedText: localDraft.recognizedText,
                    fallbackDraft: localDraft
                )
                usedBackend = true
                return remoteDraft
            } catch {
                errorMessage = "تعذر الاتصال بتحليل Backend، استخدمنا التحليل المحلي بدلًا منه."
                return localDraft
            }
        } catch {
            errorMessage = "تعذر تحليل الصورة. حاول بإضاءة أوضح أو قرّب الكاميرا من النص."
            return nil
        }
    }
}

enum CameraDecisionAnalyzer {
    static func analyze(_ image: UIImage) async throws -> CameraDecisionDraft {
        let recognizedText = try await recognizeText(from: image)
        return makeDraft(fromRecognizedText: recognizedText)
    }

    static func recognizeText(from image: UIImage) async throws -> [String] {
        let preparedImage = image.preparingForDecisionAnalysis()
        guard let cgImage = preparedImage.cgImage else {
            throw CameraDecisionAnalyzerError.invalidImage
        }

        return try await recognizeText(in: cgImage)
    }

    static func makeDraft(fromRecognizedText recognizedText: [String]) -> CameraDecisionDraft {
        let cleanText = recognizedText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let keywords = extractKeywords(from: cleanText)
        let category = inferCategory(from: cleanText + keywords)
        let primaryOption = bestOptionName(from: cleanText, category: category)
        let optionSuggestions = optionSuggestions(primaryOption: primaryOption, category: category)
        let title = makeTitle(primaryOption: primaryOption, category: category)
        let criteria = suggestedCriteria(for: category, keywords: keywords)
        let details = makeDetails(text: cleanText, category: category, criteria: criteria)
        let confidence = min(0.95, max(0.35, Double(cleanText.count) / 12.0))

        return CameraDecisionDraft(
            title: title,
            details: details,
            primaryOption: primaryOption,
            optionSuggestions: optionSuggestions,
            suggestedCriteria: criteria,
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

    private static func makeDetails(text: [String], category: AskCategory, criteria: [String]) -> String {
        let detected = text.prefix(4).joined(separator: "، ")
        let base = "تم إنشاء هذه المسودة من صورة التقطتها بالكاميرا. عدّل العنوان والخيارات قبل النشر."
        let criteriaText = criteria.isEmpty ? "" : " معايير مقترحة: \(criteria.joined(separator: "، "))."
        guard !detected.isEmpty else {
            return "\(base) أحتاج مقارنة \(category.title) بناءً على السعر والجودة والتجربة.\(criteriaText)"
        }
        return "\(base) النصوص المقروءة من الصورة: \(detected).\(criteriaText)"
    }

    private static func optionSuggestions(primaryOption: String, category: AskCategory) -> [String] {
        let fallback: String
        switch category {
        case .phones: fallback = "جوال بديل"
        case .cars: fallback = "سيارة بديلة"
        case .restaurants: fallback = "مطعم بديل"
        case .laptops: fallback = "جهاز بديل"
        case .subscriptions: fallback = "اشتراك بديل"
        case .services: fallback = "خدمة بديلة"
        default: fallback = "بديل مناسب"
        }
        return [primaryOption, fallback]
    }

    static func suggestedCriteria(for category: AskCategory, keywords: [String]) -> [String] {
        let base: [String]
        switch category {
        case .phones:
            base = ["السعر", "الكاميرا", "البطارية", "سهولة الاستخدام"]
        case .cars:
            base = ["السعر", "الاعتمادية", "استهلاك الوقود", "إعادة البيع"]
        case .restaurants:
            base = ["السعر", "الطعم", "الخدمة", "الموقع"]
        case .laptops:
            base = ["السعر", "الأداء", "البطارية", "سهولة الحمل"]
        case .subscriptions:
            base = ["السعر", "المحتوى", "سهولة الاستخدام", "القيمة"]
        case .services:
            base = ["السعر", "جودة الخدمة", "الدعم", "السرعة"]
        default:
            base = ["السعر", "الجودة", "التجربة", "القيمة"]
        }
        let keywordCriteria = keywords
            .compactMap { keyword -> String? in
                switch keyword {
                case "كاميرا", "camera": return "الكاميرا"
                case "بطاريه", "battery": return "البطارية"
                case "ضمان", "warranty": return "الضمان"
                case "سعر", "price": return "السعر"
                case "جوده", "quality": return "الجودة"
                case "خدمه", "service": return "الخدمة"
                default: return nil
                }
            }
        return Array(NSOrderedSet(array: base + keywordCriteria).compactMap { $0 as? String }.prefix(6))
    }

    private static func inferCategory(from values: [String]) -> AskCategory {
        let normalized = KnowledgeSearchIndex.normalize(values.joined(separator: " "))

        if normalized.contains("ايفون") || normalized.contains("iphone") ||
            normalized.contains("samsung") || normalized.contains("galaxy") ||
            normalized.contains("سامسونج") || normalized.contains("جوال") ||
            normalized.contains("هاتف") || normalized.contains("phone") {
            return .phones
        }
        if normalized.contains("سياره") || normalized.contains("car") ||
            normalized.contains("camry") || normalized.contains("accord") ||
            normalized.contains("toyota") || normalized.contains("كامري") ||
            normalized.contains("اكورد") || normalized.contains("تويوتا") {
            return .cars
        }
        if normalized.contains("مطعم") || normalized.contains("restaurant") ||
            normalized.contains("meal") || normalized.contains("coffee") ||
            normalized.contains("burger") || normalized.contains("وجبه") ||
            normalized.contains("قهوه") || normalized.contains("برجر") {
            return .restaurants
        }
        if normalized.contains("لابتوب") || normalized.contains("laptop") ||
            normalized.contains("macbook") || normalized.contains("windows") ||
            normalized.contains("ماك") || normalized.contains("ويندوز") ||
            normalized.contains("كمبيوتر") {
            return .laptops
        }
        if normalized.contains("اشتراك") || normalized.contains("subscription") ||
            normalized.contains("netflix") || normalized.contains("باقه") ||
            normalized.contains("نتفلكس") {
            return .subscriptions
        }
        if normalized.contains("خدمه") || normalized.contains("service") ||
            normalized.contains("warranty") || normalized.contains("ضمان") ||
            normalized.contains("صيانة") {
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
    let usedBackend: Bool
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
                    Text("صوّر منتجًا أو فاتورة أو خيارًا. نستخرج النص على الجهاز، ثم نستخدم Backend آمن عند تفعيله لاقتراح مقارنة قابلة للتعديل.")
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
                    if !lastDraft.suggestedCriteria.isEmpty {
                        Text("المعايير: \(lastDraft.suggestedCriteria.joined(separator: "، "))")
                            .font(.caption)
                            .foregroundStyle(WeshTheme.secondaryText)
                    }
                    Text(usedBackend ? "تم تحسين الاقتراح عبر Backend" : "اقتراح محلي على الجهاز")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(usedBackend ? WeshTheme.accentBright : WeshTheme.secondaryText)
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
