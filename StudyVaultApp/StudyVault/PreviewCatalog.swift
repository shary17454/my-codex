import SwiftUI

#if DEBUG
struct ContentViewPreviews: PreviewProvider {
    @MainActor
    static var previews: some View {
        if let container = try? WeshPersistenceStore.makeContainer(inMemory: true) {
            let persistence = WeshPersistenceStore(container: container)
            Group {
                ContentView(persistence: persistence)
                    .previewDisplayName("iPhone - فاتح")

                ContentView(persistence: persistence)
                    .preferredColorScheme(.dark)
                    .previewDisplayName("iPad - داكن")
            }
            .modelContainer(container)
            .environment(\.layoutDirection, .rightToLeft)
        } else {
            Text("تعذر إنشاء بيانات المعاينة")
        }
    }
}
#endif
