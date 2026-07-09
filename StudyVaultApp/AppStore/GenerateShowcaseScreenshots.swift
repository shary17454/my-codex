import AppKit

struct Canvas {
    let width: CGFloat
    let height: CGFloat
    let output: URL
    let source: NSImage

    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
        NSRect(x: x, y: height - y - h, width: w, height: h)
    }

    func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
        NSColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    func rounded(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat, _ fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 2) {
        let path = NSBezierPath(roundedRect: rect(x, y, w, h), xRadius: radius, yRadius: radius)
        fill.setFill()
        path.fill()
        if let stroke {
            stroke.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
    }

    func text(_ value: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular, fill: NSColor = .white, align: NSTextAlignment = .right) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = align
        paragraph.lineSpacing = 10
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: fill,
            .paragraphStyle: paragraph
        ]
        value.draw(in: rect(x, y, w, h), withAttributes: attrs)
    }

    func drawSource(in frame: NSRect) {
        let path = NSBezierPath(roundedRect: frame, xRadius: 54, yRadius: 54)
        NSGraphicsContext.current?.saveGraphicsState()
        path.addClip()
        source.draw(in: frame, from: NSRect(origin: .zero, size: source.size), operation: .sourceOver, fraction: 1)
        NSGraphicsContext.current?.restoreGraphicsState()

        NSColor.white.withAlphaComponent(0.22).setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    func save(_ image: NSImage, _ filename: String) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else { return }
        try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let fileURL = output.appendingPathComponent(filename)
        try? data.write(to: fileURL)

        let resize = Process()
        resize.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        resize.arguments = ["-z", "\(Int(height))", "\(Int(width))", fileURL.path, "--out", fileURL.path]
        try? resize.run()
        resize.waitUntilExit()
    }

    func makeShowcase(filename: String, titleSize: CGFloat, subtitleSize: CGFloat) {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()

        NSGradient(
            starting: color(4, 16, 24),
            ending: color(30, 9, 38)
        )?.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)

        color(190, 145, 70, 0.20).setFill()
        NSBezierPath(ovalIn: rect(-width * 0.22, height * 0.08, width * 0.70, width * 0.70)).fill()
        color(18, 175, 160, 0.14).setFill()
        NSBezierPath(ovalIn: rect(width * 0.58, height * 0.03, width * 0.58, width * 0.58)).fill()

        let side: CGFloat = width * 0.72
        let imageX = (width - side) / 2
        drawSource(in: rect(imageX, height * 0.12, side, side))

        text("وش الراي", x: width * 0.10, y: height * 0.51, w: width * 0.80, h: height * 0.07, size: titleSize, weight: .black, align: .center)
        text("اسأل قبل القرار", x: width * 0.10, y: height * 0.585, w: width * 0.80, h: height * 0.055, size: subtitleSize, weight: .bold, fill: color(244, 210, 132), align: .center)
        text("قارن بين المنتجات والخدمات، واجمع آراء الناس قبل الشراء أو الاختيار.", x: width * 0.12, y: height * 0.655, w: width * 0.76, h: height * 0.105, size: subtitleSize * 0.74, fill: color(224, 233, 232), align: .center)

        rounded(width * 0.16, height * 0.805, width * 0.68, height * 0.065, height * 0.025, color(244, 210, 132), stroke: color(255, 255, 255, 0.24), lineWidth: 2)
        text("تصويتات، تعليقات، ومقارنة ذكية", x: width * 0.18, y: height * 0.823, w: width * 0.64, h: height * 0.032, size: subtitleSize * 0.66, weight: .bold, fill: color(20, 24, 28), align: .center)

        image.unlockFocus()
        save(image, filename)
    }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceURL = root.appendingPathComponent("AppStore/SourceImages/wesh-alray-showcase.jpg")
guard let source = NSImage(contentsOf: sourceURL) else {
    fputs("Missing source image at \(sourceURL.path)\n", stderr)
    Foundation.exit(1)
}

Canvas(
    width: 1284,
    height: 2778,
    output: root.appendingPathComponent("AppStore/Screenshots/iphone65"),
    source: source
).makeShowcase(filename: "wesh-alray-00-showcase.png", titleSize: 90, subtitleSize: 48)

Canvas(
    width: 2048,
    height: 2732,
    output: root.appendingPathComponent("AppStore/Screenshots/ipad13"),
    source: source
).makeShowcase(filename: "wesh-alray-ipad-00-showcase.png", titleSize: 112, subtitleSize: 56)

print("Created App Store showcase screenshots.")
