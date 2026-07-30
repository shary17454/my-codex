import AppKit

struct IconSlot {
    let filename: String
    let pixels: Int
}

let appIconDirectory = CommandLine.arguments.dropFirst().first
    ?? "StudyVaultApp/StudyVault/Assets.xcassets/AppIcon.appiconset"
let sourceImagePath = CommandLine.arguments.dropFirst(2).first

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
        NSColor(calibratedRed: 0.02, green: 0.025, blue: 0.035, alpha: 1),
        NSColor(calibratedRed: 0.055, green: 0.075, blue: 0.105, alpha: 1),
        NSColor(calibratedRed: 0.11, green: 0.085, blue: 0.045, alpha: 1)
    ])
    background?.draw(in: rect, angle: 135)

    let glowPath = NSBezierPath(ovalIn: rect.insetBy(dx: size * 0.16, dy: size * 0.18))
    NSColor(calibratedRed: 0.92, green: 0.67, blue: 0.32, alpha: 0.18).setFill()
    glowPath.fill()

    let glassRect = rect.insetBy(dx: size * 0.13, dy: size * 0.13)
    let glass = NSBezierPath(roundedRect: glassRect, xRadius: size * 0.20, yRadius: size * 0.20)
    NSColor(calibratedRed: 1.0, green: 0.96, blue: 0.86, alpha: 0.10).setFill()
    glass.fill()

    let glassGradient = NSGradient(colors: [
        NSColor(calibratedRed: 1.0, green: 0.92, blue: 0.68, alpha: 0.22),
        NSColor(calibratedRed: 0.04, green: 0.12, blue: 0.13, alpha: 0.12),
        NSColor(calibratedRed: 0.01, green: 0.015, blue: 0.025, alpha: 0.36)
    ])
    glassGradient?.draw(in: glass, angle: 45)

    NSColor(calibratedRed: 0.94, green: 0.74, blue: 0.42, alpha: 0.55).setStroke()
    glass.lineWidth = max(1.4, size * 0.010)
    glass.stroke()

    let center = NSPoint(x: size * 0.50, y: size * 0.54)
    let compassRadius = size * 0.27
    let compassRect = NSRect(
        x: center.x - compassRadius,
        y: center.y - compassRadius,
        width: compassRadius * 2,
        height: compassRadius * 2
    )

    let outerCompass = NSBezierPath(ovalIn: compassRect)
    NSColor(calibratedRed: 0.04, green: 0.07, blue: 0.10, alpha: 0.88).setFill()
    outerCompass.fill()
    NSColor(calibratedRed: 0.96, green: 0.75, blue: 0.42, alpha: 0.95).setStroke()
    outerCompass.lineWidth = max(2, size * 0.013)
    outerCompass.stroke()

    let innerCompass = NSBezierPath(ovalIn: compassRect.insetBy(dx: size * 0.045, dy: size * 0.045))
    NSColor(calibratedRed: 0.96, green: 0.75, blue: 0.42, alpha: 0.28).setStroke()
    innerCompass.lineWidth = max(1, size * 0.006)
    innerCompass.stroke()

    for index in 0..<8 {
        let angle = CGFloat(index) * .pi / 4
        let length = index % 2 == 0 ? size * 0.060 : size * 0.035
        let start = NSPoint(
            x: center.x + cos(angle) * (compassRadius - length),
            y: center.y + sin(angle) * (compassRadius - length)
        )
        let end = NSPoint(
            x: center.x + cos(angle) * (compassRadius - size * 0.018),
            y: center.y + sin(angle) * (compassRadius - size * 0.018)
        )
        let tick = NSBezierPath()
        tick.lineWidth = max(1, size * 0.007)
        tick.lineCapStyle = .round
        tick.move(to: start)
        tick.line(to: end)
        NSColor(calibratedRed: 0.96, green: 0.75, blue: 0.42, alpha: 0.72).setStroke()
        tick.stroke()
    }

    func drawNeedle(angle: CGFloat, length: CGFloat, width: CGFloat, color: NSColor) {
        let tip = NSPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
        let left = NSPoint(x: center.x + cos(angle + .pi * 0.72) * width, y: center.y + sin(angle + .pi * 0.72) * width)
        let right = NSPoint(x: center.x + cos(angle - .pi * 0.72) * width, y: center.y + sin(angle - .pi * 0.72) * width)
        let needle = NSBezierPath()
        needle.move(to: tip)
        needle.line(to: left)
        needle.line(to: right)
        needle.close()
        color.setFill()
        needle.fill()
    }

    drawNeedle(
        angle: .pi * 0.25,
        length: size * 0.22,
        width: size * 0.052,
        color: NSColor(calibratedRed: 0.98, green: 0.90, blue: 0.72, alpha: 1)
    )
    drawNeedle(
        angle: .pi * 1.25,
        length: size * 0.17,
        width: size * 0.042,
        color: NSColor(calibratedRed: 0.46, green: 0.31, blue: 0.17, alpha: 1)
    )

    let hub = NSBezierPath(ovalIn: NSRect(x: center.x - size * 0.035, y: center.y - size * 0.035, width: size * 0.07, height: size * 0.07))
    NSColor(calibratedRed: 0.95, green: 0.75, blue: 0.40, alpha: 1).setFill()
    hub.fill()

    let shieldPath = NSBezierPath()
    shieldPath.move(to: NSPoint(x: size * 0.50, y: size * 0.84))
    shieldPath.curve(to: NSPoint(x: size * 0.70, y: size * 0.75), controlPoint1: NSPoint(x: size * 0.58, y: size * 0.82), controlPoint2: NSPoint(x: size * 0.67, y: size * 0.80))
    shieldPath.curve(to: NSPoint(x: size * 0.58, y: size * 0.62), controlPoint1: NSPoint(x: size * 0.70, y: size * 0.68), controlPoint2: NSPoint(x: size * 0.65, y: size * 0.64))
    shieldPath.curve(to: NSPoint(x: size * 0.50, y: size * 0.58), controlPoint1: NSPoint(x: size * 0.54, y: size * 0.60), controlPoint2: NSPoint(x: size * 0.51, y: size * 0.59))
    shieldPath.curve(to: NSPoint(x: size * 0.42, y: size * 0.62), controlPoint1: NSPoint(x: size * 0.49, y: size * 0.59), controlPoint2: NSPoint(x: size * 0.46, y: size * 0.60))
    shieldPath.curve(to: NSPoint(x: size * 0.30, y: size * 0.75), controlPoint1: NSPoint(x: size * 0.35, y: size * 0.64), controlPoint2: NSPoint(x: size * 0.30, y: size * 0.68))
    shieldPath.curve(to: NSPoint(x: size * 0.50, y: size * 0.84), controlPoint1: NSPoint(x: size * 0.33, y: size * 0.80), controlPoint2: NSPoint(x: size * 0.42, y: size * 0.82))
    shieldPath.close()
    NSColor(calibratedRed: 0.93, green: 0.69, blue: 0.34, alpha: 0.26).setFill()
    shieldPath.fill()
    NSColor(calibratedRed: 0.98, green: 0.82, blue: 0.52, alpha: 0.90).setStroke()
    shieldPath.lineWidth = max(1, size * 0.010)
    shieldPath.stroke()

    let check = NSBezierPath()
    check.lineWidth = max(3, size * 0.026)
    check.lineCapStyle = .round
    check.lineJoinStyle = .round
    check.move(to: NSPoint(x: size * 0.42, y: size * 0.73))
    check.line(to: NSPoint(x: size * 0.48, y: size * 0.67))
    check.line(to: NSPoint(x: size * 0.61, y: size * 0.78))
    NSColor(calibratedRed: 1.0, green: 0.90, blue: 0.66, alpha: 1).setStroke()
    check.stroke()

    let choiceWidth = size * 0.19
    let choiceHeight = size * 0.15
    let leftChoice = NSBezierPath(roundedRect: NSRect(x: size * 0.22, y: size * 0.19, width: choiceWidth, height: choiceHeight), xRadius: size * 0.04, yRadius: size * 0.04)
    let rightChoice = NSBezierPath(roundedRect: NSRect(x: size * 0.59, y: size * 0.19, width: choiceWidth, height: choiceHeight), xRadius: size * 0.04, yRadius: size * 0.04)
    NSColor(calibratedRed: 0.62, green: 0.78, blue: 0.95, alpha: 0.12).setFill()
    leftChoice.fill()
    NSColor(calibratedRed: 0.92, green: 0.62, blue: 0.36, alpha: 0.12).setFill()
    rightChoice.fill()
    NSColor(calibratedRed: 0.96, green: 0.75, blue: 0.42, alpha: 0.35).setStroke()
    leftChoice.lineWidth = max(1, size * 0.006)
    rightChoice.lineWidth = max(1, size * 0.006)
    leftChoice.stroke()
    rightChoice.stroke()

    func drawLetter(_ letter: String, x: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size * 0.085, weight: .bold),
            .foregroundColor: NSColor(calibratedRed: 0.98, green: 0.86, blue: 0.58, alpha: 0.95)
        ]
        let text = NSAttributedString(string: letter, attributes: attributes)
        let textSize = text.size()
        text.draw(at: NSPoint(x: x - textSize.width / 2, y: size * 0.225))
    }

    drawLetter("A", x: size * 0.315)
    drawLetter("B", x: size * 0.685)

    let highlight = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.08, dy: size * 0.08), xRadius: size * 0.20, yRadius: size * 0.20)
    NSColor.white.withAlphaComponent(0.10).setStroke()
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
    if let sourceImagePath,
       let sourceImage = NSImage(contentsOfFile: sourceImagePath) {
        drawSourceIcon(sourceImage, size: CGFloat(pixels))
    } else {
        drawIcon(size: CGFloat(pixels))
    }
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [.compressionFactor: 0.92]) else {
        fatalError("Could not encode \(pixels)x\(pixels)")
    }
    return png
}

func drawSourceIcon(_ image: NSImage, size: CGFloat) {
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSGraphicsContext.current?.imageInterpolation = .high

    NSColor(calibratedRed: 0.02, green: 0.018, blue: 0.022, alpha: 1).setFill()
    rect.fill()

    let imageSize = image.size
    let cropSide = min(imageSize.width, imageSize.height)
    let cropRect = NSRect(
        x: (imageSize.width - cropSide) / 2,
        y: (imageSize.height - cropSide) / 2,
        width: cropSide,
        height: cropSide
    )

    image.draw(
        in: rect,
        from: cropRect,
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )
}

let destination = URL(fileURLWithPath: appIconDirectory)
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

for slot in slots {
    let png = renderPNG(pixels: slot.pixels)
    try png.write(to: destination.appendingPathComponent(slot.filename))
}

print("Generated \(slots.count) app icon files in \(destination.path)")
