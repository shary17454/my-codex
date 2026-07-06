import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "StudyVaultIcon-1024.png"
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let background = NSGradient(colors: [
    NSColor(calibratedRed: 0.03, green: 0.42, blue: 0.39, alpha: 1.0),
    NSColor(calibratedRed: 0.10, green: 0.28, blue: 0.58, alpha: 1.0)
])
background?.draw(in: rect, angle: 135)

let cardRect = NSRect(x: 170, y: 210, width: 684, height: 604)
let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 72, yRadius: 72)
NSColor.white.withAlphaComponent(0.92).setFill()
cardPath.fill()

let lineColor = NSColor(calibratedRed: 0.08, green: 0.42, blue: 0.39, alpha: 1.0)
lineColor.setStroke()
for index in 0..<5 {
    let y = 680 - CGFloat(index * 88)
    let path = NSBezierPath()
    path.lineWidth = 24
    path.lineCapStyle = .round
    path.move(to: NSPoint(x: 260, y: y))
    path.line(to: NSPoint(x: 760 - CGFloat(index * 36), y: y))
    path.stroke()
}

let badgeRect = NSRect(x: 610, y: 210, width: 244, height: 244)
let badgePath = NSBezierPath(ovalIn: badgeRect)
NSColor(calibratedRed: 0.72, green: 0.42, blue: 0.13, alpha: 1.0).setFill()
badgePath.fill()

let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 110, weight: .heavy),
    .foregroundColor: NSColor.white,
]
let text = NSString(string: "SA")
let textSize = text.size(withAttributes: attributes)
text.draw(
    at: NSPoint(
        x: badgeRect.midX - textSize.width / 2,
        y: badgeRect.midY - textSize.height / 2 + 5
    ),
    withAttributes: attributes
)

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("Could not render app icon")
}

try png.write(to: URL(fileURLWithPath: output))
