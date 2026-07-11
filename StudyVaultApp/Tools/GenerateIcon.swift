import AppKit

struct IconSlot {
    let filename: String
    let pixels: Int
}

let appIconDirectory = CommandLine.arguments.dropFirst().first
    ?? "StudyVaultApp/StudyVault/Assets.xcassets/AppIcon.appiconset"

let slots: [IconSlot] = [
    .init(filename: "AppIcon-20@2x.png", pixels: 40),
    .init(filename: "AppIcon-20@3x.png", pixels: 60),
    .init(filename: "AppIcon-29@2x.png", pixels: 58),
    .init(filename: "AppIcon-29@3x.png", pixels: 87),
    .init(filename: "AppIcon-40@2x.png", pixels: 80),
    .init(filename: "AppIcon-40@3x.png", pixels: 120),
    .init(filename: "AppIcon-60@2x.png", pixels: 120),
    .init(filename: "AppIcon-60@3x.png", pixels: 180),
    .init(filename: "AppIcon-20-ipad@1x.png", pixels: 20),
    .init(filename: "AppIcon-20-ipad@2x.png", pixels: 40),
    .init(filename: "AppIcon-29-ipad@1x.png", pixels: 29),
    .init(filename: "AppIcon-29-ipad@2x.png", pixels: 58),
    .init(filename: "AppIcon-40-ipad@1x.png", pixels: 40),
    .init(filename: "AppIcon-40-ipad@2x.png", pixels: 80),
    .init(filename: "AppIcon-76@1x.png", pixels: 76),
    .init(filename: "AppIcon-76@2x.png", pixels: 152),
    .init(filename: "AppIcon-83.5@2x.png", pixels: 167),
    .init(filename: "AppIcon-1024.png", pixels: 1024)
]

func drawIcon(size: CGFloat) {
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSGraphicsContext.current?.imageInterpolation = .high

    let background = NSGradient(colors: [
        NSColor(calibratedRed: 0.025, green: 0.035, blue: 0.085, alpha: 1),
        NSColor(calibratedRed: 0.02, green: 0.17, blue: 0.28, alpha: 1),
        NSColor(calibratedRed: 0.08, green: 0.47, blue: 0.58, alpha: 1)
    ])
    background?.draw(in: rect, angle: 125)

    let glowPath = NSBezierPath(ovalIn: rect.insetBy(dx: size * 0.11, dy: size * 0.18))
    NSColor(calibratedRed: 0.0, green: 0.78, blue: 0.9, alpha: 0.20).setFill()
    glowPath.fill()

    let glassRect = rect.insetBy(dx: size * 0.16, dy: size * 0.16)
    let glass = NSBezierPath(roundedRect: glassRect, xRadius: size * 0.18, yRadius: size * 0.18)
    NSColor(calibratedRed: 0.95, green: 1.0, blue: 1.0, alpha: 0.16).setFill()
    glass.fill()

    let glassGradient = NSGradient(colors: [
        NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.30),
        NSColor(calibratedRed: 0.0, green: 0.7, blue: 0.95, alpha: 0.10),
        NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.12, alpha: 0.26)
    ])
    glassGradient?.draw(in: glass, angle: 55)

    NSColor.white.withAlphaComponent(0.45).setStroke()
    glass.lineWidth = max(1.4, size * 0.010)
    glass.stroke()

    let cardWidth = size * 0.31
    let cardHeight = size * 0.40
    let leftCard = NSRect(x: size * 0.23, y: size * 0.33, width: cardWidth, height: cardHeight)
    let rightCard = NSRect(x: size * 0.46, y: size * 0.25, width: cardWidth, height: cardHeight)

    func drawChoiceCard(_ card: NSRect, color: NSColor) {
        let path = NSBezierPath(roundedRect: card, xRadius: size * 0.055, yRadius: size * 0.055)
        color.withAlphaComponent(0.62).setFill()
        path.fill()
        NSColor.white.withAlphaComponent(0.50).setStroke()
        path.lineWidth = max(1, size * 0.008)
        path.stroke()

        let lineInset = size * 0.045
        for index in 0..<3 {
            let y = card.maxY - size * 0.11 - CGFloat(index) * size * 0.075
            let line = NSBezierPath()
            line.lineWidth = max(2, size * 0.014)
            line.lineCapStyle = .round
            line.move(to: NSPoint(x: card.minX + lineInset, y: y))
            line.line(to: NSPoint(x: card.maxX - lineInset - CGFloat(index) * size * 0.03, y: y))
            NSColor.white.withAlphaComponent(0.70 - CGFloat(index) * 0.12).setStroke()
            line.stroke()
        }
    }

    drawChoiceCard(leftCard, color: NSColor(calibratedRed: 0.0, green: 0.70, blue: 0.86, alpha: 1))
    drawChoiceCard(rightCard, color: NSColor(calibratedRed: 0.16, green: 0.24, blue: 0.88, alpha: 1))

    let markCenter = NSPoint(x: size * 0.50, y: size * 0.53)
    let markRadius = size * 0.14
    let mark = NSBezierPath(ovalIn: NSRect(x: markCenter.x - markRadius, y: markCenter.y - markRadius, width: markRadius * 2, height: markRadius * 2))
    NSColor(calibratedRed: 0.02, green: 0.95, blue: 0.92, alpha: 0.92).setFill()
    mark.fill()
    NSColor.white.withAlphaComponent(0.76).setStroke()
    mark.lineWidth = max(2, size * 0.011)
    mark.stroke()

    let check = NSBezierPath()
    check.lineWidth = max(4, size * 0.035)
    check.lineCapStyle = .round
    check.lineJoinStyle = .round
    check.move(to: NSPoint(x: size * 0.42, y: size * 0.53))
    check.line(to: NSPoint(x: size * 0.49, y: size * 0.45))
    check.line(to: NSPoint(x: size * 0.61, y: size * 0.61))
    NSColor.white.setStroke()
    check.stroke()

    let spark = NSBezierPath()
    spark.lineWidth = max(2, size * 0.012)
    spark.lineCapStyle = .round
    NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.27, alpha: 0.95).setStroke()
    let sparkCenter = NSPoint(x: size * 0.68, y: size * 0.70)
    spark.move(to: NSPoint(x: sparkCenter.x, y: sparkCenter.y - size * 0.055))
    spark.line(to: NSPoint(x: sparkCenter.x, y: sparkCenter.y + size * 0.055))
    spark.move(to: NSPoint(x: sparkCenter.x - size * 0.055, y: sparkCenter.y))
    spark.line(to: NSPoint(x: sparkCenter.x + size * 0.055, y: sparkCenter.y))
    spark.stroke()

    let highlight = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.08, dy: size * 0.08), xRadius: size * 0.20, yRadius: size * 0.20)
    NSColor.white.withAlphaComponent(0.13).setStroke()
    highlight.lineWidth = max(1, size * 0.006)
    highlight.stroke()
}

func renderPNG(pixels: Int) -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Could not allocate bitmap \(pixels)x\(pixels)")
    }

    bitmap.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    drawIcon(size: CGFloat(pixels))
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [.compressionFactor: 0.92]) else {
        fatalError("Could not encode \(pixels)x\(pixels)")
    }
    return png
}

let destination = URL(fileURLWithPath: appIconDirectory)
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

for slot in slots {
    let png = renderPNG(pixels: slot.pixels)
    try png.write(to: destination.appendingPathComponent(slot.filename))
}

print("Generated \(slots.count) app icon files in \(destination.path)")
