import Foundation
import SwiftUI
import UIKit

#if canImport(ActivityKit)
import ActivityKit
#endif

struct WeshPlusFeature: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
}

enum WeshPlusCatalog {
    static let productIdentifiers = [
        "com.shary17454.esal.plus.monthly",
        "com.shary17454.esal.plus.yearly"
    ]

    static let features: [WeshPlusFeature] = [
        WeshPlusFeature(id: "private_rooms", title: "غرف خاصة غير محدودة", detail: "مقارنات خاصة بالرابط أو رمز الدعوة عند ربط Backend إنتاجي.", systemImage: "lock.shield.fill"),
        WeshPlusFeature(id: "advanced_reports", title: "تقارير موسعة", detail: "ملخص قرار أوسع مع جودة الأدلة، الأسباب المؤيدة والمعاكسة، واحتياجك الشخصي.", systemImage: "doc.text.magnifyingglass"),
        WeshPlusFeature(id: "exports", title: "تصدير PDF وCSV", detail: "CSV متاح للجميع، وPDF جاهز كقيمة Plus عند تفعيل StoreKit.", systemImage: "square.and.arrow.down"),
        WeshPlusFeature(id: "share_cards", title: "بطاقات بدون علامة مائية", detail: "بطاقات مشاركة احترافية مستقبلًا بدون علامة وش الرأي عند الاشتراك.", systemImage: "photo.on.rectangle.angled"),
        WeshPlusFeature(id: "teams", title: "نسخة فرق عمل", detail: "مساحات عمل وصلاحيات وتقارير جماعية في مرحلة لاحقة.", systemImage: "person.3.fill")
    ]
}

struct PremiumAccessPolicy {
    static func hasPlus(ownerAccess: Bool) -> Bool {
        ownerAccess
    }

    static func limitDescription(ownerAccess: Bool) -> String {
        hasPlus(ownerAccess: ownerAccess)
            ? "حساب المالك: كل مزايا Plus مفتوحة."
            : "الاشتراك التجاري يحتاج منتجات App Store Connect قبل تفعيل الشراء."
    }
}

enum DecisionPDFExporter {
    @MainActor
    static func createPDF(question: AskQuestion, watermark: Bool) throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("wesh-alray-\(question.id.uuidString).pdf")
        let summary = DecisionSummaryService.makeSummary(for: question)

        try renderer.writePDF(to: url) { context in
            context.beginPage()
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .right
            paragraph.baseWritingDirection = .rightToLeft
            paragraph.lineSpacing = 6

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 30),
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraph
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle: paragraph
            ]
            let strongAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraph
            ]

            "وش الرأي".draw(in: CGRect(x: 40, y: 36, width: 515, height: 40), withAttributes: titleAttributes)
            question.title.draw(in: CGRect(x: 40, y: 92, width: 515, height: 70), withAttributes: titleAttributes)
            question.details.draw(in: CGRect(x: 40, y: 170, width: 515, height: 80), withAttributes: bodyAttributes)
            "ملخص القرار: \(summary.recommendationText)".draw(in: CGRect(x: 40, y: 265, width: 515, height: 110), withAttributes: strongAttributes)

            var y = 395.0
            for option in question.options.sorted(by: { $0.votes > $1.votes }) {
                let percentage = question.totalVotes > 0 ? Int((Double(option.votes) / Double(question.totalVotes)) * 100) : 0
                "\(option.title): \(option.votes) صوت، \(percentage)%"
                    .draw(in: CGRect(x: 40, y: y, width: 515, height: 28), withAttributes: bodyAttributes)
                y += 34
            }

            "جودة الأدلة: \(summary.evidenceQuality.level.rawValue) · \(summary.evidenceQuality.score) من 100"
                .draw(in: CGRect(x: 40, y: y + 20, width: 515, height: 32), withAttributes: strongAttributes)

            if watermark {
                let watermarkAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.tertiaryLabel,
                    .paragraphStyle: paragraph
                ]
                "تم إنشاؤه بواسطة وش الرأي".draw(in: CGRect(x: 40, y: 780, width: 515, height: 24), withAttributes: watermarkAttributes)
            }
        }
        return url
    }
}

#if canImport(ActivityKit)
@available(iOS 16.2, *)
struct WeshComparisonActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var leaderName: String
        var leaderPercentage: Int
        var totalVotes: Int
    }

    let comparisonID: UUID
    let title: String
    let closesAt: Date?
}

@available(iOS 16.2, *)
enum WeshLiveActivityManager {
    static func startIfSupported(for question: AskQuestion) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let leader = question.winningOption
        let percentage = leader.flatMap { option -> Int? in
            guard question.totalVotes > 0 else { return nil }
            return Int((Double(option.votes) / Double(question.totalVotes)) * 100)
        } ?? 0
        _ = try Activity.request(
            attributes: WeshComparisonActivityAttributes(
                comparisonID: question.id,
                title: question.title,
                closesAt: question.closesAt
            ),
            content: ActivityContent(
                state: WeshComparisonActivityAttributes.ContentState(
                    leaderName: leader?.title ?? "لا يوجد متصدر",
                    leaderPercentage: percentage,
                    totalVotes: question.totalVotes
                ),
                staleDate: question.closesAt
            ),
            pushType: nil
        )
    }
}
#endif

struct WeshAppleFeaturesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeshSectionHeader(
                "ميزات Apple",
                subtitle: "جاهزية التطبيق للمنظومة، مع متطلبات واضحة للميزات التي تحتاج Targets خارجية.",
                systemImage: "apple.logo"
            )
            AppleFeatureRow(title: "Siri Shortcuts", detail: "مقارنة جديدة، فتح اكتشف، مكتبتي، وآخر نتيجة.", state: "مفعلة", color: WeshTheme.accent)
            AppleFeatureRow(title: "Live Activities", detail: "طبقة ActivityKit جاهزة، وتحتاج Widget Extension لواجهة شاشة القفل.", state: "تحتاج Extension", color: WeshTheme.gold)
            AppleFeatureRow(title: "Widgets", detail: "تحتاج Widget Extension وBundle ID مستقل قبل الإرسال.", state: "خارجي", color: WeshTheme.gold)
            AppleFeatureRow(title: "iPad", detail: "NavigationSplitView وتخطيط متكيف للشاشات الكبيرة.", state: "مدعوم", color: WeshTheme.accent)
            AppleFeatureRow(title: "VoiceOver وDynamic Type", detail: "تسميات ومكونات ديناميكية، ويبقى فحص Accessibility Inspector يدويًا قبل الرفع.", state: "محسن", color: WeshTheme.accent)
        }
        .weshSurface()
    }
}

private struct AppleFeatureRow: View {
    let title: String
    let detail: String
    let state: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Text(state)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
                .padding(.horizontal, 9)
                .frame(minHeight: 28)
                .background(color.opacity(0.12), in: Capsule())
        }
        .accessibilityElement(children: .combine)
    }
}

struct WeshPlusCard: View {
    let hasOwnerAccess: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            WeshSectionHeader(
                "وش الرأي Plus",
                subtitle: PremiumAccessPolicy.limitDescription(ownerAccess: hasOwnerAccess),
                systemImage: "crown.fill"
            )
            ForEach(WeshPlusCatalog.features) { feature in
                HStack(alignment: .top, spacing: 10) {
                    WeshIconTile(systemImage: feature.systemImage, color: WeshTheme.gold, size: 38)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(feature.title)
                            .font(.subheadline.weight(.bold))
                        Text(feature.detail)
                            .font(.caption)
                            .foregroundStyle(WeshTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            if !hasOwnerAccess {
                WeshStatusBanner(
                    text: "لم يتم تفعيل الشراء بعد؛ يلزم إنشاء المنتجات في App Store Connect وربط StoreKit قبل فتح الاشتراك للمستخدمين.",
                    kind: .information
                )
            }
        }
        .weshSurface(goldAccent: true)
    }
}
