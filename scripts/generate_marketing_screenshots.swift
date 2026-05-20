import AppKit
import Foundation

struct ScreenshotSpec {
    let fileName: String
    let source: String
    let headline: String
    let subtitle: String
    let badge: String
}

struct ScreenshotSet {
    let name: String
    let canvas: CGSize
    let sourceRoot: String
    let outputRoot: String
    let logoSize: CGFloat
    let specs: [ScreenshotSpec]
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputBase = root.appending(path: "docs/app-store/screenshots/marketing")

let iphoneSpecs = [
    ScreenshotSpec(
        fileName: "01-find-courts.jpg",
        source: "01-map.png",
        headline: "Find courts\nnear you",
        subtitle: "A fast basketball court map for quick decisions.",
        badge: "MAP"
    ),
    ScreenshotSpec(
        fileName: "02-filter-facts.jpg",
        source: "02-filters.png",
        headline: "Filter by\ncourt facts",
        subtitle: "Outdoor, indoor, lights, nets, dry surface and more.",
        badge: "FILTER"
    ),
    ScreenshotSpec(
        fileName: "03-check-before-you-go.jpg",
        source: "03-court-card.png",
        headline: "Know before\nyou go",
        subtitle: "Open the court card before you make the trip.",
        badge: "DETAILS"
    ),
    ScreenshotSpec(
        fileName: "04-court-details.jpg",
        source: "04-details.png",
        headline: "Court details\nin one place",
        subtitle: "Location, practical facts, save and directions.",
        badge: "FACTS"
    ),
    ScreenshotSpec(
        fileName: "05-save-sync.jpg",
        source: "05-profile.png",
        headline: "Save your\nfavorite courts",
        subtitle: "Sign in with Apple to keep saved courts with you.",
        badge: "PROFILE"
    )
]

let ipadSpecs = [
    ScreenshotSpec(fileName: "01-find-courts.jpg", source: "01-map.png", headline: "Find courts\nnear you", subtitle: "A wider court map built for quick discovery.", badge: "MAP"),
    ScreenshotSpec(fileName: "02-filter-facts.jpg", source: "02-filters.png", headline: "Filter by\ncourt facts", subtitle: "Outdoor, indoor, lights, nets, dry surface and more.", badge: "FILTER"),
    ScreenshotSpec(fileName: "03-check-before-you-go.jpg", source: "03-court-card.png", headline: "Know before\nyou go", subtitle: "Open the court card before you travel.", badge: "DETAILS"),
    ScreenshotSpec(fileName: "04-court-details.jpg", source: "04-details.png", headline: "Court details\nin one place", subtitle: "Practical info, save and directions.", badge: "FACTS"),
    ScreenshotSpec(fileName: "05-save-sync.jpg", source: "05-profile.png", headline: "Save your\nfavorite courts", subtitle: "Sign in with Apple to keep saved courts with you.", badge: "PROFILE")
]

let sets = [
    ScreenshotSet(
        name: "iPhone 6.9-inch",
        canvas: CGSize(width: 1320, height: 2868),
        sourceRoot: "docs/app-store/screenshots/iphone-6-9",
        outputRoot: "iphone-6-9",
        logoSize: 92,
        specs: iphoneSpecs
    ),
    ScreenshotSet(
        name: "iPad 13-inch",
        canvas: CGSize(width: 2064, height: 2752),
        sourceRoot: "docs/app-store/screenshots/real/ipad-13",
        outputRoot: "ipad-13",
        logoSize: 104,
        specs: ipadSpecs
    )
]

let logoURL = root.appending(path: "Blacktop/Assets.xcassets/BlacktopSplashMark.imageset/blacktop-splash-mark.png")
guard let logo = NSImage(contentsOf: logoURL) else {
    fatalError("Missing logo at \(logoURL.path)")
}

for set in sets {
    let outputDir = outputBase.appending(path: set.outputRoot)
    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

    for spec in set.specs {
        let sourceURL = root.appending(path: set.sourceRoot).appending(path: spec.source)
        guard let source = NSImage(contentsOf: sourceURL) else {
            print("Skipping \(spec.fileName): missing \(sourceURL.path)")
            continue
        }

        let image = renderMarketingScreenshot(set: set, spec: spec, source: source, logo: logo)
        let outputURL = outputDir.appending(path: spec.fileName)
        try writeJPEG(image, to: outputURL)
        print("Wrote \(outputURL.path)")
    }
}

private func renderMarketingScreenshot(set: ScreenshotSet, spec: ScreenshotSpec, source: NSImage, logo: NSImage) -> NSImage {
    let canvas = set.canvas
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvas.width),
        pixelsHigh: Int(canvas.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Could not create bitmap context")
    }
    bitmap.size = canvas

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer {
        NSGraphicsContext.restoreGraphicsState()
    }

    context.imageInterpolation = .high

    drawMarketingContent(canvas: canvas, set: set, spec: spec, source: source, logo: logo)

    let image = NSImage(size: canvas)
    image.addRepresentation(bitmap)
    return image
}

private func drawMarketingContent(canvas: CGSize, set: ScreenshotSet, spec: ScreenshotSpec, source: NSImage, logo: NSImage) {
    drawBackground(canvas)
    drawCourtLines(canvas)

    let margin: CGFloat = canvas.width > 1500 ? 132 : 86
    let topLogo = rectFromTop(x: margin, y: 84, width: set.logoSize, height: set.logoSize, canvas: canvas)
    drawRoundedImage(logo, in: topLogo, radius: set.logoSize * 0.22)

    drawText(
        "Blacktop",
        rect: rectFromTop(x: margin + set.logoSize + 24, y: 92, width: canvas.width - margin * 2 - set.logoSize - 24, height: 70, canvas: canvas),
        font: .systemFont(ofSize: canvas.width > 1500 ? 42 : 38, weight: .black),
        color: .white
    )

    drawBadge(spec.badge, canvas: canvas, margin: margin)

    drawText(
        spec.headline,
        rect: rectFromTop(x: margin, y: canvas.width > 1500 ? 230 : 220, width: canvas.width - margin * 2, height: canvas.width > 1500 ? 290 : 330, canvas: canvas),
        font: .systemFont(ofSize: canvas.width > 1500 ? 108 : 104, weight: .black),
        color: .white,
        lineHeight: 1.0
    )

    drawText(
        spec.subtitle,
        rect: rectFromTop(x: margin, y: canvas.width > 1500 ? 520 : 560, width: canvas.width - margin * 2, height: 100, canvas: canvas),
        font: .systemFont(ofSize: canvas.width > 1500 ? 38 : 35, weight: .bold),
        color: NSColor.white.withAlphaComponent(0.72),
        lineHeight: 1.12
    )

    if canvas.width > 1500 {
        let frame = rectFromTop(x: 178, y: 710, width: canvas.width - 356, height: canvas.height - 840, canvas: canvas)
        drawDevice(source, in: frame, radius: 76, border: 12)
    } else {
        let frame = rectFromTop(x: 108, y: 760, width: canvas.width - 216, height: canvas.height - 900, canvas: canvas)
        drawDevice(source, in: frame, radius: 86, border: 12)
    }

}

private func drawBackground(_ canvas: CGSize) {
    let context = NSGraphicsContext.current!.cgContext
    let colors = [
        NSColor(red: 0.015, green: 0.045, blue: 0.050, alpha: 1).cgColor,
        NSColor(red: 0.020, green: 0.085, blue: 0.075, alpha: 1).cgColor,
        NSColor(red: 0.005, green: 0.013, blue: 0.018, alpha: 1).cgColor
    ] as CFArray
    let locations: [CGFloat] = [0, 0.46, 1]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: canvas.height),
        end: CGPoint(x: canvas.width, y: 0),
        options: []
    )

    NSColor(red: 0.62, green: 0.95, blue: 0.30, alpha: 0.13).setFill()
    NSBezierPath(ovalIn: CGRect(x: canvas.width * 0.58, y: canvas.height * 0.72, width: canvas.width * 0.70, height: canvas.width * 0.70)).fill()
}

private func drawCourtLines(_ canvas: CGSize) {
    let path = NSBezierPath()
    path.lineWidth = canvas.width > 1500 ? 6 : 5
    NSColor.white.withAlphaComponent(0.07).setStroke()

    path.move(to: CGPoint(x: -80, y: canvas.height * 0.37))
    path.line(to: CGPoint(x: canvas.width + 160, y: canvas.height * 0.72))
    path.stroke()

    let center = NSBezierPath(ovalIn: CGRect(x: canvas.width * 0.45, y: canvas.height * 0.47, width: canvas.width * 0.46, height: canvas.width * 0.46))
    center.lineWidth = canvas.width > 1500 ? 5 : 4
    center.stroke()
}

private func drawDevice(_ source: NSImage, in frame: CGRect, radius: CGFloat, border: CGFloat) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
    shadow.shadowBlurRadius = 34
    shadow.shadowOffset = CGSize(width: 0, height: -18)
    shadow.set()

    NSColor(red: 0.03, green: 0.045, blue: 0.052, alpha: 1).setFill()
    NSBezierPath(roundedRect: frame, xRadius: radius, yRadius: radius).fill()
    NSShadow().set()

    let inner = frame.insetBy(dx: border, dy: border)
    drawRoundedImage(source, in: inner, radius: max(24, radius - border))

    NSColor.white.withAlphaComponent(0.16).setStroke()
    let outline = NSBezierPath(roundedRect: frame, xRadius: radius, yRadius: radius)
    outline.lineWidth = 3
    outline.stroke()
}

private func drawRoundedImage(_ image: NSImage, in rect: CGRect, radius: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
    let sourceSize = image.size
    let sourceAspect = sourceSize.width / sourceSize.height
    let rectAspect = rect.width / rect.height
    var crop = CGRect(origin: .zero, size: sourceSize)
    if sourceAspect > rectAspect {
        let width = sourceSize.height * rectAspect
        crop.origin.x = (sourceSize.width - width) / 2
        crop.size.width = width
    } else {
        let height = sourceSize.width / rectAspect
        crop.origin.y = (sourceSize.height - height) / 2
        crop.size.height = height
    }
    image.draw(in: rect, from: crop, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
}

private func drawBadge(_ text: String, canvas: CGSize, margin: CGFloat) {
    let fontSize: CGFloat = canvas.width > 1500 ? 30 : 26
    let width: CGFloat = canvas.width > 1500 ? 210 : 172
    let rect = rectFromTop(x: canvas.width - margin - width, y: 102, width: width, height: 56, canvas: canvas)
    NSColor(red: 0.62, green: 0.95, blue: 0.30, alpha: 1).setFill()
    NSBezierPath(roundedRect: rect, xRadius: 28, yRadius: 28).fill()
    drawText(
        text,
        rect: rect.insetBy(dx: 12, dy: 11),
        font: .systemFont(ofSize: fontSize, weight: .black),
        color: NSColor(red: 0.01, green: 0.02, blue: 0.02, alpha: 1),
        alignment: .center
    )
}

private func drawText(
    _ text: String,
    rect: CGRect,
    font: NSFont,
    color: NSColor,
    alignment: NSTextAlignment = .left,
    lineHeight: CGFloat = 1.08
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineHeightMultiple = lineHeight
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSAttributedString(string: text, attributes: attributes).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
}

private func rectFromTop(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, canvas: CGSize) -> CGRect {
    CGRect(x: x, y: canvas.height - y - height, width: width, height: height)
}

private func writeJPEG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
        throw NSError(domain: "BlacktopMarketingScreenshots", code: 1)
    }
    try data.write(to: url, options: [.atomic])
}
