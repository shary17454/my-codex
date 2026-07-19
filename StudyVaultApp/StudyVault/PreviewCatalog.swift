import SwiftUI

#if DEBUG
struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDisplayName("iPhone - فاتح")

            ContentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("iPad - داكن")
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}
#endif
