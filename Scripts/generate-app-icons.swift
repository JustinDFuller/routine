import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let sRGBColorSpace: CGColorSpace = {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        preconditionFailure("Failed to create the sRGB color space.")
    }
    return colorSpace
}()

struct RGBA {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(hex: UInt32, alpha: CGFloat = 1) {
        red = CGFloat((hex >> 16) & 0xFF) / 255
        green = CGFloat((hex >> 8) & 0xFF) / 255
        blue = CGFloat(hex & 0xFF) / 255
        self.alpha = alpha
    }

    var cgColor: CGColor {
        guard
            let color = CGColor(
                colorSpace: sRGBColorSpace,
                components: [red, green, blue, alpha]
            )
        else {
            preconditionFailure("Failed to create a CGColor from RGBA components.")
        }
        return color
    }
}

struct IconPalette {
    let backgroundTop: RGBA
    let backgroundBottom: RGBA
    let backgroundGlow: RGBA
    let baseRing: RGBA
    let progressSweep: RGBA
    let check: RGBA
    let ringShadow: RGBA
    let checkShadow: RGBA
}

struct IconVariant {
    let filename: String
    let palette: IconPalette
}

enum AppIconError: Error, CustomStringConvertible {
    case invalidContext
    case invalidImage
    case invalidDestination(URL)
    case writeFailed(URL)

    var description: String {
        switch self {
        case .invalidContext:
            return "Failed to create the bitmap drawing context."
        case .invalidImage:
            return "Failed to create an image from the drawing context."
        case .invalidDestination(let url):
            return "Failed to create a PNG destination for \(url.path)."
        case .writeFailed(let url):
            return "Failed to finalize the PNG destination for \(url.path)."
        }
    }
}

let canvasSize = 1024
let center = CGPoint(x: 512, y: 512)
let ringRadius: CGFloat = 292
let ringLineWidth: CGFloat = 112

// In the rendered PNG, -90 is 12 o'clock, 0 is 3 o'clock, 90 is 6 o'clock,
// and increasing degrees move clockwise.
let progressSweepStartDegrees: CGFloat = -94
let progressSweepEndDegrees: CGFloat = 122

let iconVariants = [
    IconVariant(
        filename: "AppIcon-default.png",
        palette: IconPalette(
            backgroundTop: RGBA(hex: 0x342F2B),
            backgroundBottom: RGBA(hex: 0x171513),
            backgroundGlow: RGBA(hex: 0x463B31, alpha: 0.28),
            baseRing: RGBA(hex: 0x3A403B),
            progressSweep: RGBA(hex: 0xAED2B8),
            check: RGBA(hex: 0xF5DEB8),
            ringShadow: RGBA(hex: 0x090807, alpha: 0.34),
            checkShadow: RGBA(hex: 0x0E0B09, alpha: 0.24)
        )
    ),
    IconVariant(
        filename: "AppIcon-dark.png",
        palette: IconPalette(
            backgroundTop: RGBA(hex: 0x20201F),
            backgroundBottom: RGBA(hex: 0x0B0C0B),
            backgroundGlow: RGBA(hex: 0x2C2822, alpha: 0.24),
            baseRing: RGBA(hex: 0x303632),
            progressSweep: RGBA(hex: 0xB7E1C2),
            check: RGBA(hex: 0xFFE7BF),
            ringShadow: RGBA(hex: 0x000000, alpha: 0.42),
            checkShadow: RGBA(hex: 0x000000, alpha: 0.28)
        )
    ),
    IconVariant(
        filename: "AppIcon-tinted.png",
        palette: IconPalette(
            backgroundTop: RGBA(hex: 0x352F27),
            backgroundBottom: RGBA(hex: 0x1C1915),
            backgroundGlow: RGBA(hex: 0x4A3E2D, alpha: 0.26),
            baseRing: RGBA(hex: 0x464737),
            progressSweep: RGBA(hex: 0xC5CB9F),
            check: RGBA(hex: 0xF8E8C4),
            ringShadow: RGBA(hex: 0x080604, alpha: 0.34),
            checkShadow: RGBA(hex: 0x0A0805, alpha: 0.24)
        )
    )
]

func drawBackground(context: CGContext, size: CGFloat, palette: IconPalette) throws {
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    context.setFillColor(palette.backgroundBottom.cgColor)
    context.fill(rect)

    let gradientColors = [palette.backgroundTop.cgColor, palette.backgroundBottom.cgColor] as CFArray
    guard let gradient = CGGradient(colorsSpace: sRGBColorSpace, colors: gradientColors, locations: [0, 1]) else {
        throw AppIconError.invalidContext
    }

    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: size / 2, y: 0),
        end: CGPoint(x: size / 2, y: size),
        options: []
    )

    let glowCenter = CGPoint(x: 512, y: 430)
    let glowColors =
        [
            palette.backgroundGlow.cgColor,
            RGBA(
                red: palette.backgroundGlow.red,
                green: palette.backgroundGlow.green,
                blue: palette.backgroundGlow.blue,
                alpha: 0
            ).cgColor
        ] as CFArray

    guard let glowGradient = CGGradient(colorsSpace: sRGBColorSpace, colors: glowColors, locations: [0, 1]) else {
        throw AppIconError.invalidContext
    }

    context.drawRadialGradient(
        glowGradient,
        startCenter: glowCenter,
        startRadius: 0,
        endCenter: glowCenter,
        endRadius: 410,
        options: .drawsAfterEndLocation
    )
}

func drawRing(
    context: CGContext,
    center: CGPoint,
    radius: CGFloat,
    lineWidth: CGFloat,
    palette: IconPalette
) {
    let circleRect = CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
    )

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 18), blur: 28, color: palette.ringShadow.cgColor)
    context.setStrokeColor(palette.baseRing.cgColor)
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    context.strokeEllipse(in: circleRect)
    context.restoreGState()

    context.saveGState()
    context.setStrokeColor(palette.progressSweep.cgColor)
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.addPath(
        makeArcPath(
            center: center,
            radius: radius,
            startDegrees: progressSweepStartDegrees,
            endDegrees: progressSweepEndDegrees
        )
    )
    context.strokePath()
    context.restoreGState()
}

func drawCheckmark(context: CGContext, center: CGPoint, palette: IconPalette) {
    let points = [
        CGPoint(x: center.x - 117, y: center.y + 13),
        CGPoint(x: center.x - 22, y: center.y + 108),
        CGPoint(x: center.x + 123, y: center.y - 57)
    ]

    let path = CGMutablePath()
    path.move(to: points[0])
    path.addLine(to: points[1])
    path.addLine(to: points[2])

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 10), blur: 14, color: palette.checkShadow.cgColor)
    context.setStrokeColor(palette.check.cgColor)
    context.setLineWidth(58)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.addPath(path)
    context.strokePath()
    context.restoreGState()
}

func writePNG(image: CGImage, url: URL) throws {
    let directoryURL = url.deletingLastPathComponent()
    if !FileManager.default.fileExists(atPath: directoryURL.path) {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    guard
        let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        )
    else {
        throw AppIconError.invalidDestination(url)
    }

    CGImageDestinationAddImage(destination, image, nil)

    guard CGImageDestinationFinalize(destination) else {
        throw AppIconError.writeFailed(url)
    }
}

func makeArcPath(center: CGPoint, radius: CGFloat, startDegrees: CGFloat, endDegrees: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let step: CGFloat = 0.5
    let startPoint = pointOnCircle(center: center, radius: radius, degrees: startDegrees)

    path.move(to: startPoint)

    var degrees = startDegrees + step
    while degrees < endDegrees {
        path.addLine(to: pointOnCircle(center: center, radius: radius, degrees: degrees))
        degrees += step
    }

    path.addLine(to: pointOnCircle(center: center, radius: radius, degrees: endDegrees))
    return path
}

func pointOnCircle(center: CGPoint, radius: CGFloat, degrees: CGFloat) -> CGPoint {
    let radians = degrees * .pi / 180
    return CGPoint(
        x: center.x + radius * cos(radians),
        y: center.y + radius * sin(radians)
    )
}

func renderIcon(variant: IconVariant, outputDirectory: URL) throws {
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard
        let context = CGContext(
            data: nil,
            width: canvasSize,
            height: canvasSize,
            bitsPerComponent: 8,
            bytesPerRow: canvasSize * 4,
            space: sRGBColorSpace,
            bitmapInfo: bitmapInfo
        )
    else {
        throw AppIconError.invalidContext
    }

    context.interpolationQuality = .high
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.translateBy(x: 0, y: CGFloat(canvasSize))
    context.scaleBy(x: 1, y: -1)

    try drawBackground(context: context, size: CGFloat(canvasSize), palette: variant.palette)
    drawRing(
        context: context,
        center: center,
        radius: ringRadius,
        lineWidth: ringLineWidth,
        palette: variant.palette
    )
    drawCheckmark(context: context, center: center, palette: variant.palette)

    guard let image = context.makeImage() else {
        throw AppIconError.invalidImage
    }

    let outputURL = outputDirectory.appendingPathComponent(variant.filename)
    try writePNG(image: image, url: outputURL)
    print(outputURL.path)
}

let scriptURL = URL(fileURLWithPath: #filePath)
let repositoryRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let outputDirectory = repositoryRoot.appendingPathComponent("RoutineApp/Assets.xcassets/AppIcon.appiconset")

do {
    for variant in iconVariants {
        try renderIcon(variant: variant, outputDirectory: outputDirectory)
    }
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(1)
}
