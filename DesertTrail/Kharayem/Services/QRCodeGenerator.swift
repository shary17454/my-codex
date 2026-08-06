import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

enum QRCodeGenerator {
    static func image(from string: String) -> Image {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else {
            return Image(systemName: "qrcode")
        }

        let scaledOutput = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = context.createCGImage(scaledOutput, from: scaledOutput.extent) else {
            return Image(systemName: "qrcode")
        }

        return Image(uiImage: UIImage(cgImage: cgImage))
    }
}
