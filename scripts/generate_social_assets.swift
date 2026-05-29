import AppKit
import CoreImage
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDir = root.appending(path: "docs/app-store/social/current")
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let appStoreURL = "https://apps.apple.com/gb/app/blacktop-basketball/id6769562571"
let landingURL = "https://acewang377.github.io/Blacktop-App/"
let downloadURL = "https://acewang377.github.io/Blacktop-App/download/?src=qr"
let logoURL = root.appending(path: "docs/app-store/blacktop-promo-video/assets/logo.png")
let mapShotURL = root.appending(path: "docs/app-store/screenshots/current/v1.1.0-build3-2026-05-26/marketing/iphone-6-9/01-find-courts.jpg")
let detailShotURL = root.appending(path: "docs/app-store/screenshots/current/v1.1.0-build3-2026-05-26/marketing/iphone-6-9/04-court-details.jpg")

guard let logo = NSImage(contentsOf: logoURL) else {
    fatalError("Missing logo at \(logoURL.path)")
}

guard let mapShot = NSImage(contentsOf: mapShotURL) else {
    fatalError("Missing map screenshot at \(mapShotURL.path)")
}

guard let detailShot = NSImage(contentsOf: detailShotURL) else {
    fatalError("Missing detail screenshot at \(detailShotURL.path)")
}

let appStoreQR = makeQRCode(appStoreURL, size: CGSize(width: 900, height: 900))
let landingQR = makeQRCode(landingURL, size: CGSize(width: 900, height: 900))
let downloadQR = makeQRCode(downloadURL, size: CGSize(width: 900, height: 900))

try writePNG(appStoreQR, to: outputDir.appending(path: "qr-app-store.png"))
try writePNG(landingQR, to: outputDir.appending(path: "qr-landing-page.png"))
try writePNG(downloadQR, to: outputDir.appending(path: "qr-download-page.png"))
try writePNG(renderStory(logo: logo, screenshot: mapShot, qr: appStoreQR), to: outputDir.appending(path: "instagram-story.png"))
try writePNG(renderSquarePost(logo: logo, screenshot: detailShot, qr: appStoreQR), to: outputDir.appending(path: "square-post.png"))
try writePNG(renderFlyer(logo: logo, mapShot: mapShot, detailShot: detailShot, qr: appStoreQR), to: outputDir.appending(path: "print-flyer.png"))

print("Wrote social assets to \(outputDir.path)")

private func renderStory(logo: NSImage, screenshot: NSImage, qr: NSImage) -> NSImage {
    render(size: CGSize(width: 1080, height: 1920)) { canvas in
        drawBackground(canvas)
        drawBrand(logo: logo, x: 80, y: 78, size: 82, canvas: canvas)
        drawPill("FREE IOS APP", x: 760, y: 86, width: 230, height: 56, canvas: canvas)
        drawText(
            "Find basketball\ncourts before\nyou leave.",
            rect: topRect(x: 80, y: 230, width: 850, height: 380, canvas: canvas),
            font: .systemFont(ofSize: 88, weight: .black),
            color: .white,
            lineHeight: 0.95
        )
        drawText(
            "Map, filters, saved courts, directions, and player-backed court details.",
            rect: topRect(x: 84, y: 635, width: 840, height: 110, canvas: canvas),
            font: .systemFont(ofSize: 35, weight: .bold),
            color: .white,
            lineHeight: 1.18
        )
        drawImageCropped(screenshot, in: topRect(x: 112, y: 790, width: 520, height: 815, canvas: canvas), radius: 34)
        drawQRCodeCard(qr, title: "Scan to download", subtitle: "Blacktop Basketball", rect: topRect(x: 665, y: 1070, width: 320, height: 438, canvas: canvas))
        drawButton("Download on the App Store", rect: topRect(x: 80, y: 1670, width: 620, height: 86, canvas: canvas))
        drawText(
            "apps.apple.com/gb/app/blacktop-basketball/id6769562571",
            rect: topRect(x: 80, y: 1780, width: 900, height: 44, canvas: canvas),
            font: .systemFont(ofSize: 22, weight: .semibold),
            color: .white
        )
    }
}

private func renderSquarePost(logo: NSImage, screenshot: NSImage, qr: NSImage) -> NSImage {
    render(size: CGSize(width: 1080, height: 1080)) { canvas in
        drawBackground(canvas)
        drawBrand(logo: logo, x: 70, y: 64, size: 70, canvas: canvas)
        drawPill("BASKETBALL COURT FINDER", x: 676, y: 72, width: 334, height: 50, canvas: canvas)
        drawText(
            "Know the court\nbefore you go.",
            rect: topRect(x: 70, y: 178, width: 590, height: 210, canvas: canvas),
            font: .systemFont(ofSize: 64, weight: .black),
            color: .white,
            lineHeight: 0.98
        )
        drawText(
            "Filter lights, nets, indoor/outdoor, dry surface, rim height, and more.",
            rect: topRect(x: 72, y: 408, width: 570, height: 100, canvas: canvas),
            font: .systemFont(ofSize: 27, weight: .bold),
            color: .white,
            lineHeight: 1.18
        )
        drawImageCropped(screenshot, in: topRect(x: 70, y: 548, width: 420, height: 420, canvas: canvas), radius: 28)
        drawQRCodeCard(qr, title: "Scan to download", subtitle: "Free on iPhone and iPad", rect: topRect(x: 620, y: 560, width: 320, height: 398, canvas: canvas))
    }
}

private func renderFlyer(logo: NSImage, mapShot: NSImage, detailShot: NSImage, qr: NSImage) -> NSImage {
    render(size: CGSize(width: 1240, height: 1754)) { canvas in
        drawBackground(canvas)
        drawBrand(logo: logo, x: 88, y: 82, size: 76, canvas: canvas)
        drawPill("FREE IPHONE AND IPAD APP", x: 802, y: 90, width: 334, height: 54, canvas: canvas)
        drawText(
            "Blacktop Basketball",
            rect: topRect(x: 88, y: 230, width: 950, height: 100, canvas: canvas),
            font: .systemFont(ofSize: 78, weight: .black),
            color: .white
        )
        drawText(
            "Find courts nearby, check practical court details, save regular spots, and open directions.",
            rect: topRect(x: 92, y: 350, width: 860, height: 96, canvas: canvas),
            font: .systemFont(ofSize: 32, weight: .bold),
            color: .white,
            lineHeight: 1.18
        )
        drawImageCropped(mapShot, in: topRect(x: 88, y: 510, width: 460, height: 780, canvas: canvas), radius: 30)
        drawImageCropped(detailShot, in: topRect(x: 588, y: 510, width: 460, height: 780, canvas: canvas), radius: 30)
        drawFeature("No login needed to browse", x: 104, y: 1350, canvas: canvas)
        drawFeature("Filter lights, nets, indoor/outdoor", x: 104, y: 1414, canvas: canvas)
        drawFeature("Save courts and open Apple Maps", x: 104, y: 1478, canvas: canvas)
        drawQRCodeCard(qr, title: "Scan to download", subtitle: "Blacktop Basketball", rect: topRect(x: 790, y: 1320, width: 290, height: 374, canvas: canvas))
    }
}

private let panel = NSColor(srgbRed: 0.025, green: 0.032, blue: 0.030, alpha: 0.96)
private let accent = NSColor(srgbRed: 0.66, green: 0.965, blue: 0.365, alpha: 1)
private let night = NSColor(srgbRed: 0.018, green: 0.050, blue: 0.045, alpha: 1)

private func render(size: CGSize, drawing: (CGSize) -> Void) -> NSImage {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Could not create bitmap")
    }

    bitmap.size = size

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    drawing(size)
    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: size)
    image.addRepresentation(bitmap)
    return image
}

private func drawBackground(_ canvas: CGSize) {
    let context = NSGraphicsContext.current!.cgContext
    let colors = [
        NSColor(red: 0.016, green: 0.047, blue: 0.043, alpha: 1).cgColor,
        NSColor(red: 0.025, green: 0.095, blue: 0.080, alpha: 1).cgColor,
        NSColor(red: 0.010, green: 0.020, blue: 0.032, alpha: 1).cgColor
    ] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.52, 1])!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: canvas.height),
        end: CGPoint(x: canvas.width, y: 0),
        options: []
    )

    NSColor(red: 0.62, green: 0.95, blue: 0.30, alpha: 0.12).setFill()
    NSBezierPath(ovalIn: CGRect(x: canvas.width * 0.60, y: canvas.height * 0.68, width: canvas.width * 0.66, height: canvas.width * 0.66)).fill()

    let line = NSBezierPath()
    line.lineWidth = 4
    NSColor.white.withAlphaComponent(0.065).setStroke()
    line.move(to: CGPoint(x: -80, y: canvas.height * 0.36))
    line.line(to: CGPoint(x: canvas.width + 120, y: canvas.height * 0.66))
    line.stroke()
}

private func drawBrand(logo: NSImage, x: CGFloat, y: CGFloat, size: CGFloat, canvas: CGSize) {
    drawImageCropped(logo, in: topRect(x: x, y: y, width: size, height: size, canvas: canvas), radius: size * 0.22)
    drawText(
        "Blacktop",
        rect: topRect(x: x + size + 18, y: y + 12, width: 300, height: 48, canvas: canvas),
        font: .systemFont(ofSize: 28, weight: .black),
        color: .white
    )
}

private func drawPill(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, canvas: CGSize) {
    let rect = topRect(x: x, y: y, width: width, height: height, canvas: canvas)
    accent.setFill()
    roundedPath(rect, radius: 8).fill()
    drawText(
        text,
        rect: rect.insetBy(dx: 14, dy: 13),
        font: .systemFont(ofSize: 17, weight: .black),
        color: night,
        alignment: .center
    )
}

private func drawButton(_ text: String, rect: CGRect) {
    NSColor.white.setFill()
    roundedPath(rect, radius: 10).fill()
    drawText(
        text,
        rect: rect.insetBy(dx: 20, dy: 25),
        font: .systemFont(ofSize: 25, weight: .black),
        color: night,
        alignment: .center
    )
}

private func drawQRCodeCard(_ qr: NSImage, title: String, subtitle: String, rect: CGRect) {
    NSColor.white.setFill()
    roundedPath(rect, radius: 18).fill()
    NSColor.black.withAlphaComponent(0.10).setStroke()
    roundedPath(rect, radius: 18).stroke()

    let qrSide = min(rect.width - 56, rect.height - 146)
    let qrRect = CGRect(x: rect.midX - qrSide / 2, y: rect.maxY - qrSide - 36, width: qrSide, height: qrSide)
    NSColor.white.setFill()
    roundedPath(qrRect.insetBy(dx: -12, dy: -12), radius: 12).fill()
    qr.draw(in: qrRect, from: .zero, operation: .sourceOver, fraction: 1)

    drawText(
        title,
        rect: CGRect(x: rect.minX + 22, y: rect.minY + 58, width: rect.width - 44, height: 34),
        font: .systemFont(ofSize: 24, weight: .black),
        color: night,
        alignment: .center
    )
    drawText(
        subtitle,
        rect: CGRect(x: rect.minX + 22, y: rect.minY + 26, width: rect.width - 44, height: 28),
        font: .systemFont(ofSize: 17, weight: .bold),
        color: night,
        alignment: .center
    )
}

private func drawFeature(_ text: String, x: CGFloat, y: CGFloat, canvas: CGSize) {
    let dot = topRect(x: x, y: y + 12, width: 20, height: 20, canvas: canvas)
    NSColor.white.setFill()
    NSBezierPath(ovalIn: dot).fill()
    drawText(
        text,
        rect: topRect(x: x + 38, y: y, width: 620, height: 50, canvas: canvas),
        font: .systemFont(ofSize: 27, weight: .bold),
        color: .white
    )
}

private func drawText(
    _ text: String,
    rect: CGRect,
    font: NSFont,
    color: NSColor,
    alignment: NSTextAlignment = .left,
    lineHeight: CGFloat = 1.0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.minimumLineHeight = font.pointSize * lineHeight
    paragraph.maximumLineHeight = font.pointSize * lineHeight

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]

    NSString(string: text).draw(in: rect, withAttributes: attributes)
}

private func drawImageCropped(_ image: NSImage, in rect: CGRect, radius: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    roundedPath(rect, radius: radius).addClip()

    let source = image.size
    let sourceRatio = source.width / source.height
    let destRatio = rect.width / rect.height
    var drawRect = rect
    if sourceRatio > destRatio {
        let width = rect.height * sourceRatio
        drawRect = CGRect(x: rect.midX - width / 2, y: rect.minY, width: width, height: rect.height)
    } else {
        let height = rect.width / sourceRatio
        drawRect = CGRect(x: rect.minX, y: rect.midY - height / 2, width: rect.width, height: height)
    }

    image.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.14).setStroke()
    roundedPath(rect, radius: radius).stroke()
}

private func makeQRCode(_ string: String, size: CGSize) -> NSImage {
    let filter = CIFilter(name: "CIQRCodeGenerator")!
    filter.setValue(Data(string.utf8), forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")

    guard let output = filter.outputImage else {
        fatalError("Could not create QR code")
    }

    let scale = min(size.width / output.extent.width, size.height / output.extent.height)
    let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    let context = CIContext(options: [.useSoftwareRenderer: false])

    guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
        fatalError("Could not render QR code")
    }

    return NSImage(cgImage: cgImage, size: size)
}

private func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Could not encode PNG for \(url.path)")
    }

    try data.write(to: url)
    print("Wrote \(url.path)")
}

private func topRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, canvas: CGSize) -> CGRect {
    CGRect(x: x, y: canvas.height - y - height, width: width, height: height)
}

private func roundedPath(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}
