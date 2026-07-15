import AppKit

let width: CGFloat = 2048
let height: CGFloat = 2732
let output = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("AppStore/Screenshots/ipad13")
try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
    NSRect(x: x, y: height - y - h, width: w, height: h)
}

func rounded(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat, _ fill: NSColor, stroke: NSColor? = nil) {
    let path = NSBezierPath(roundedRect: rect(x, y, w, h), xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = 3
        path.stroke()
    }
}

func text(_ value: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular, fill: NSColor = .white, align: NSTextAlignment = .right) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = align
    paragraph.lineSpacing = 12
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: fill,
        .paragraphStyle: paragraph
    ]
    value.draw(in: rect(x, y, w, h), withAttributes: attrs)
}

func option(_ title: String, percent: CGFloat, y: CGFloat, tint: NSColor) {
    rounded(260, y, 1528, 126, 30, color(255, 255, 255, 0.13), stroke: color(255, 255, 255, 0.16))
    rounded(300, y + 76, 1390, 20, 10, color(255, 255, 255, 0.14))
    rounded(300, y + 76, 1390 * percent, 20, 10, tint)
    text(title, x: 780, y: y + 24, w: 880, h: 60, size: 36, weight: .bold)
    text("\(Int(percent * 100))%", x: 320, y: y + 24, w: 220, h: 60, size: 36, weight: .bold, fill: tint, align: .left)
}

func makeBase(_ top: NSColor, _ bottom: NSColor) -> NSImage {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    NSGradient(starting: top, ending: bottom)?.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)
    color(31, 184, 170, 0.22).setFill()
    NSBezierPath(ovalIn: rect(-160, 220, 860, 820)).fill()
    color(83, 109, 221, 0.18).setFill()
    NSBezierPath(ovalIn: rect(1360, 80, 860, 820)).fill()
    rounded(140, 92, width - 280, height - 184, 92, color(7, 14, 18, 0.92), stroke: color(255, 255, 255, 0.18))
    rounded(760, 112, 528, 42, 22, color(0, 0, 0, 0.72))
    image.unlockFocus()
    return image
}

func save(_ image: NSImage, _ name: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else { return }
    let fileURL = output.appendingPathComponent(name)
    try? data.write(to: fileURL)

    let resize = Process()
    resize.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    resize.arguments = ["-z", "\(Int(height))", "\(Int(width))", fileURL.path, "--out", fileURL.path]
    try? resize.run()
    resize.waitUntilExit()
}

func home() {
    let img = makeBase(color(2, 18, 28), color(6, 50, 58))
    img.lockFocus()
    text("وش الراي", x: 260, y: 310, w: 1528, h: 100, size: 92, weight: .black)
    text("وش رأي الناس؟ قبل الشراء\nقارن بين خيارين أو أكثر بوضوح", x: 260, y: 440, w: 1528, h: 120, size: 46, fill: color(210, 239, 235))
    let stats = [("120", "عنصر معرفة"), ("0", "تصويت وهمي"), ("10", "خيارات مقارنة")]
    for (i, item) in stats.enumerated() {
        let x = CGFloat(260 + i * 526)
        rounded(x, 650, 476, 180, 34, color(255, 255, 255, 0.13), stroke: color(255, 255, 255, 0.18))
        text(item.0, x: x + 30, y: 700, w: 410, h: 64, size: 58, weight: .black, fill: i == 1 ? color(244, 185, 82) : color(50, 220, 205))
        text(item.1, x: x + 30, y: 768, w: 410, h: 48, size: 30, fill: color(220, 229, 232))
    }
    text("مقارنات جاهزة", x: 260, y: 955, w: 1528, h: 70, size: 58, weight: .black)
    let cards = [("iPhone 16 Pro Max", "أداء قوي وكاميرا متقدمة"), ("Toyota Camry", "اعتمادية وقيمة إعادة بيع"), ("مطاعم الرياض", "اختيار أسرع حسب التجربة")]
    for (i, c) in cards.enumerated() {
        let y = CGFloat(1060 + i * 246)
        rounded(260, y, 1528, 210, 38, color(255, 255, 255, 0.14), stroke: color(255, 255, 255, 0.18))
        color(33, 178, 166).setFill()
        NSBezierPath(ovalIn: rect(310, y + 48, 114, 114)).fill()
        text(c.0, x: 500, y: y + 58, w: 1160, h: 60, size: 42, weight: .bold)
        text(c.1, x: 500, y: y + 122, w: 1160, h: 52, size: 31, fill: color(199, 216, 219))
    }
    rounded(560, 2240, 928, 138, 46, color(31, 184, 170))
    text("ابدأ سؤال مقارنة", x: 610, y: 2285, w: 828, h: 60, size: 48, weight: .bold, align: .center)
    img.unlockFocus()
    save(img, "rah-tafham-ipad-01-home.png")
}

func compare() {
    let img = makeBase(color(3, 15, 28), color(22, 38, 71))
    img.lockFocus()
    text("مقارنة ذكية", x: 260, y: 310, w: 1528, h: 100, size: 92, weight: .black)
    text("اختر نص أو صوت أو فيديو\nوشاهد الفروقات في بطاقة واحدة", x: 260, y: 440, w: 1528, h: 120, size: 46, fill: color(210, 232, 250))
    rounded(260, 650, 1528, 140, 36, color(255, 255, 255, 0.13))
    for (i, label) in ["نص", "صوت", "فيديو"].enumerated() {
        rounded(CGFloat(465 + i * 360), 680, 260, 80, 28, i == 0 ? color(31, 184, 170) : color(255, 255, 255, 0.12))
        text(label, x: CGFloat(490 + i * 360), y: 700, w: 210, h: 45, size: 32, weight: .bold, align: .center)
    }
    text("iPhone أم Galaxy؟", x: 260, y: 920, w: 1528, h: 70, size: 58, weight: .black)
    option("iPhone 16 Pro Max", percent: 0.64, y: 1045, tint: color(43, 211, 195))
    option("Galaxy S25 Ultra", percent: 0.52, y: 1215, tint: color(136, 154, 255))
    rounded(260, 1450, 1528, 510, 42, color(255, 255, 255, 0.14), stroke: color(255, 255, 255, 0.18))
    text("النتيجة المختصرة", x: 320, y: 1520, w: 1400, h: 60, size: 50, weight: .black)
    text("الأفضل للتصوير والفيديو: iPhone\nالأفضل للقلم والتخصيص: Galaxy\nالأفضل لمعظم المستخدمين: حسب السعر", x: 320, y: 1615, w: 1400, h: 190, size: 38, fill: color(219, 235, 235))
    rounded(260, 2070, 1528, 220, 38, color(255, 255, 255, 0.12))
    text("ثقة التحليل 86%", x: 320, y: 2140, w: 1400, h: 60, size: 50, weight: .black, fill: color(50, 220, 205))
    text("يعتمد على المواصفات، الاستخدام، والسعر", x: 320, y: 2210, w: 1400, h: 44, size: 32, fill: color(205, 220, 222))
    img.unlockFocus()
    save(img, "rah-tafham-ipad-02-compare.png")
}

func question() {
    let img = makeBase(color(11, 21, 28), color(27, 52, 44))
    img.lockFocus()
    text("وش رأي الناس؟", x: 260, y: 310, w: 1528, h: 100, size: 92, weight: .black)
    text("اكتب سؤالك، أضف الخيارات،\nواستقبل التصويتات والتعليقات", x: 260, y: 440, w: 1528, h: 120, size: 46, fill: color(210, 239, 224))
    rounded(260, 650, 1528, 540, 42, color(255, 255, 255, 0.14), stroke: color(255, 255, 255, 0.18))
    text("أشتري السيارة A أو B؟", x: 320, y: 725, w: 1400, h: 70, size: 54, weight: .black)
    text("السيارات", x: 320, y: 805, w: 1400, h: 50, size: 34, weight: .bold, fill: color(50, 220, 205))
    option("Toyota Camry", percent: 0.58, y: 905, tint: color(43, 211, 195))
    option("Honda Accord", percent: 0.42, y: 1075, tint: color(244, 185, 82))
    text("تعليقات مفيدة", x: 260, y: 1330, w: 1528, h: 70, size: 58, weight: .black)
    let comments = [("خالد", "الكامري ممتازة في الاعتمادية وسعر القطع."), ("نورة", "الأكورد أفضل إذا تهمك متعة القيادة."), ("أحمد", "قارن السعر النهائي والضمان قبل القرار.")]
    for (i, c) in comments.enumerated() {
        let y = CGFloat(1430 + i * 220)
        rounded(260, y, 1528, 190, 34, color(255, 255, 255, 0.13))
        text(c.0, x: 320, y: y + 46, w: 1400, h: 50, size: 38, weight: .bold, fill: color(50, 220, 205))
        text(c.1, x: 320, y: y + 105, w: 1400, h: 55, size: 33, fill: color(218, 232, 232))
    }
    rounded(500, 2240, 1048, 145, 48, color(31, 184, 170))
    text("نشر سؤال جديد", x: 550, y: 2288, w: 948, h: 60, size: 48, weight: .bold, align: .center)
    img.unlockFocus()
    save(img, "rah-tafham-ipad-03-question.png")
}

home()
compare()
question()
print("Created iPad screenshots in \(output.path)")
