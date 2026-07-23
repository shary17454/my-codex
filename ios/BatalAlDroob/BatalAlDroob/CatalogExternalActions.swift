import UIKit

extension CatalogViewModel {
    func categoryCount(_ category: CatalogCategory) -> Int {
        guard category != .all else { return parts.count }
        return parts.lazy.filter { $0.categoryValue == category }.count
    }

    func openStore(_ store: VerifiedStore, part: Part?) {
        let url = store.searchURL(partNumber: part?.partNumber ?? "") ?? URL(string: store.website ?? "")
        guard let url, isAllowedExternalURL(url, for: store) else {
            errorMessage = text(ar: "رابط المتجر غير صالح.", en: "The store link is invalid.")
            return
        }
        #if os(iOS)
            Task {
                let opened = await UIApplication.shared.open(url)
                if !opened {
                    errorMessage = text(ar: "تعذر فتح رابط المتجر.", en: "The store link could not be opened.")
                }
            }
        #endif
    }
}
