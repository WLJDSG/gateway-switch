import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "AppResources/Assets.xcassets/AppIcon.appiconset")

let iconFiles: [(filename: String, pixels: Int)] = [
    ("icon-16.png", 16),
    ("icon-16@2x.png", 32),
    ("icon-32.png", 32),
    ("icon-32@2x.png", 64),
    ("icon-128.png", 128),
    ("icon-128@2x.png", 256),
    ("icon-256.png", 256),
    ("icon-256@2x.png", 512),
    ("icon-512.png", 512),
    ("icon-1024.png", 1024)
]

func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, scale: CGFloat) -> NSRect {
    NSRect(x: x * scale, y: y * scale, width: width * scale, height: height * scale)
}

func point(_ x: CGFloat, _ y: CGFloat, scale: CGFloat) -> NSPoint {
    NSPoint(x: x * scale, y: y * scale)
}

func drawLine(from start: NSPoint, to end: NSPoint, color: NSColor, width: CGFloat) {
    let path = NSBezierPath()
    path.move(to: start)
    path.line(to: end)
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.lineWidth = width
    color.setStroke()
    path.stroke()
}

func drawCircle(center: NSPoint, radius: CGFloat, fill: NSGradient, stroke: NSColor, strokeWidth: CGFloat) {
    let circleRect = NSRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
    )
    let path = NSBezierPath(ovalIn: circleRect)
    fill.draw(in: path, angle: -55)
    stroke.setStroke()
    path.lineWidth = strokeWidth
    path.stroke()
}

func drawIcon(size: Int, destination: URL) throws {
    let scale = CGFloat(size) / 1024
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "IconGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create \(size)x\(size) bitmap"])
    }
    bitmap.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let outer = rect(64, 64, 896, 896, scale: scale)
    let corner = 208 * scale

    NSGraphicsContext.saveGraphicsState()
    NSShadow()
        .with(blurRadius: 34 * scale, offset: NSSize(width: 0, height: -18 * scale), color: NSColor.black.withAlphaComponent(0.28))
        .set()
    let basePath = NSBezierPath(roundedRect: outer, xRadius: corner, yRadius: corner)
    NSGradient(
        colors: [
            NSColor(calibratedRed: 0.08, green: 0.16, blue: 0.22, alpha: 1),
            NSColor(calibratedRed: 0.04, green: 0.09, blue: 0.14, alpha: 1),
            NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.09, alpha: 1)
        ]
    )!.draw(in: basePath, angle: -35)
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.20).setStroke()
    basePath.lineWidth = 5 * scale
    basePath.stroke()

    let insetPath = NSBezierPath(roundedRect: outer.insetBy(dx: 22 * scale, dy: 22 * scale), xRadius: corner * 0.86, yRadius: corner * 0.86)
    NSColor(calibratedRed: 0.30, green: 0.90, blue: 1.00, alpha: 0.18).setStroke()
    insetPath.lineWidth = 3 * scale
    insetPath.stroke()

    let glow = NSColor(calibratedRed: 0.18, green: 0.92, blue: 1.00, alpha: 0.58)
    let lineColor = NSColor(calibratedRed: 0.42, green: 0.96, blue: 1.00, alpha: 0.92)
    let coreCenter = point(512, 482, scale: scale)
    let nodeY: CGFloat = 722
    let nodeCenters = [
        point(292, nodeY, scale: scale),
        point(512, nodeY + 38, scale: scale),
        point(732, nodeY, scale: scale)
    ]

    if size >= 64 {
        for center in nodeCenters {
            drawLine(from: coreCenter, to: center, color: glow.withAlphaComponent(0.20), width: 30 * scale)
            drawLine(from: coreCenter, to: center, color: lineColor, width: 12 * scale)
        }
    } else {
        drawLine(from: point(270, 730, scale: scale), to: point(754, 730, scale: scale), color: lineColor, width: 64 * scale)
    }

    let coreRect = rect(344, 298, 336, 336, scale: scale)
    let corePath = NSBezierPath(roundedRect: coreRect, xRadius: 94 * scale, yRadius: 94 * scale)
    NSGraphicsContext.saveGraphicsState()
    NSShadow()
        .with(blurRadius: 24 * scale, offset: .zero, color: glow.withAlphaComponent(0.58))
        .set()
    NSGradient(
        colors: [
            NSColor(calibratedRed: 0.13, green: 0.34, blue: 0.43, alpha: 1),
            NSColor(calibratedRed: 0.05, green: 0.14, blue: 0.21, alpha: 1)
        ]
    )!.draw(in: corePath, angle: -45)
    NSGraphicsContext.restoreGraphicsState()
    NSColor(calibratedRed: 0.61, green: 0.98, blue: 1.00, alpha: 0.96).setStroke()
    corePath.lineWidth = 9 * scale
    corePath.stroke()

    let arrow = NSBezierPath()
    arrow.move(to: point(462, 398, scale: scale))
    arrow.line(to: point(544, 482, scale: scale))
    arrow.line(to: point(462, 566, scale: scale))
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    arrow.lineWidth = 46 * scale
    NSColor(calibratedRed: 0.66, green: 1.00, blue: 1.00, alpha: 1).setStroke()
    arrow.stroke()

    drawLine(
        from: point(574, 560, scale: scale),
        to: point(642, 560, scale: scale),
        color: NSColor(calibratedRed: 0.66, green: 1.00, blue: 1.00, alpha: 1),
        width: 42 * scale
    )

    let nodeGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.74, green: 1.00, blue: 1.00, alpha: 1),
        NSColor(calibratedRed: 0.11, green: 0.30, blue: 0.38, alpha: 1)
    ])!

    if size >= 32 {
        for center in nodeCenters {
            drawCircle(
                center: center,
                radius: 72 * scale,
                fill: nodeGradient,
                stroke: NSColor(calibratedRed: 0.65, green: 1.00, blue: 1.00, alpha: 0.95),
                strokeWidth: 7 * scale
            )
        }
    }

    if size >= 128 {
        let highlight = NSBezierPath(roundedRect: rect(170, 154, 684, 134, scale: scale), xRadius: 67 * scale, yRadius: 67 * scale)
        NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.16),
            NSColor.white.withAlphaComponent(0.00)
        ])!.draw(in: highlight, angle: 90)

        for x in stride(from: CGFloat(250), through: CGFloat(770), by: 130) {
            drawLine(
                from: point(x, 232, scale: scale),
                to: point(x + 58, 232, scale: scale),
                color: NSColor.white.withAlphaComponent(0.12),
                width: 8 * scale
            )
        }
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to render \(destination.lastPathComponent)"])
    }

    try png.write(to: destination, options: .atomic)
}

extension NSShadow {
    func with(blurRadius: CGFloat, offset: NSSize, color: NSColor) -> NSShadow {
        self.shadowBlurRadius = blurRadius
        self.shadowOffset = offset
        self.shadowColor = color
        return self
    }

}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for file in iconFiles {
    try drawIcon(size: file.pixels, destination: outputDirectory.appendingPathComponent(file.filename))
}

print("Generated \(iconFiles.count) app icon images in \(outputDirectory.path)")
