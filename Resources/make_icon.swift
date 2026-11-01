// Renders the Knurl app icon with CoreGraphics and builds Knurl.icns.
// Usage: swift Resources/make_icon.swift [output dir]
import AppKit

let size: CGFloat = 1024
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources"

let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(colorSpace: cs, components: [r, g, b, a])! }
func gradient(_ colors: [CGColor], _ locs: [CGFloat]) -> CGGradient { CGGradient(colorsSpace: cs, colors: colors as CFArray, locations: locs)! }

let center = CGPoint(x: size / 2, y: size / 2)

// macOS icon grid: the squircle fills 824/1024 with transparent margin.
let inset: CGFloat = 100
let tile = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let tilePath = CGPath(roundedRect: tile, cornerWidth: tile.width * 0.2237, cornerHeight: tile.height * 0.2237, transform: nil)

// Tile shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 40, color: rgb(0, 0, 0, 0.45))
ctx.addPath(tilePath); ctx.setFillColor(rgb(0.10, 0.10, 0.11)); ctx.fillPath()
ctx.restoreGState()

// Tile background: dark charcoal, slightly lighter at the top
ctx.saveGState()
ctx.addPath(tilePath); ctx.clip()
ctx.drawLinearGradient(gradient([rgb(0.20, 0.21, 0.23), rgb(0.09, 0.09, 0.10)], [0, 1]),
                       start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

// Blue LED glow from the base, the PowerMate's signature
let glowCenter = CGPoint(x: center.x, y: center.y - 30)
ctx.drawRadialGradient(gradient([rgb(0.30, 0.65, 1.0, 1.0), rgb(0.30, 0.65, 1.0, 1.0), rgb(0.20, 0.50, 1.0, 0.55), rgb(0.1, 0.3, 0.9, 0.0)], [0, 0.60, 0.74, 1]),
                       startCenter: glowCenter, startRadius: 0, endCenter: glowCenter, endRadius: 430, options: [])
ctx.restoreGState()

// Knob geometry
let knobR: CGFloat = 272
let knobCenter = CGPoint(x: center.x, y: center.y + 10)

// Knob drop shadow onto the glow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 50, color: rgb(0, 0, 0, 0.75))
ctx.setFillColor(rgb(0.2, 0.2, 0.2))
ctx.fillEllipse(in: CGRect(x: knobCenter.x - knobR, y: knobCenter.y - knobR, width: 2 * knobR, height: 2 * knobR))
ctx.restoreGState()

// Knurled rim: alternating light/dark wedges around the outer ring
let ridges = 96
ctx.saveGState()
for i in 0..<ridges {
    let a0 = CGFloat(i) / CGFloat(ridges) * 2 * .pi
    let a1 = CGFloat(i + 1) / CGFloat(ridges) * 2 * .pi
    // Light from top-left: ridges facing the light are brighter
    let facing = cos(a0 + .pi / 4 - .pi / 2)
    let base: CGFloat = 0.52 + 0.22 * facing
    let shade = i % 2 == 0 ? base + 0.14 : base - 0.14
    ctx.setFillColor(rgb(shade, shade, shade + 0.01))
    ctx.move(to: knobCenter)
    ctx.addArc(center: knobCenter, radius: knobR, startAngle: a0, endAngle: a1, clockwise: false)
    ctx.closePath()
    ctx.fillPath()
}
ctx.restoreGState()

// Rim bevel: darken toward the edge
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: knobCenter.x - knobR, y: knobCenter.y - knobR, width: 2 * knobR, height: 2 * knobR)); ctx.clip()
ctx.drawRadialGradient(gradient([rgb(0, 0, 0, 0), rgb(0, 0, 0, 0), rgb(0, 0, 0, 0.55)], [0, 0.86, 1]),
                       startCenter: knobCenter, startRadius: 0, endCenter: knobCenter, endRadius: knobR, options: [])
ctx.restoreGState()

// Top face: brushed aluminium disc inside the knurl
let faceR: CGFloat = 212
let faceRect = CGRect(x: knobCenter.x - faceR, y: knobCenter.y - faceR, width: 2 * faceR, height: 2 * faceR)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 14, color: rgb(0, 0, 0, 0.7))
ctx.setFillColor(rgb(0.75, 0.76, 0.78)); ctx.fillEllipse(in: faceRect)
ctx.restoreGState()

ctx.saveGState()
ctx.addEllipse(in: faceRect); ctx.clip()
// Base metal gradient, lit from top-left
ctx.drawLinearGradient(gradient([rgb(0.93, 0.94, 0.95), rgb(0.72, 0.73, 0.76), rgb(0.58, 0.59, 0.62)], [0, 0.55, 1]),
                       start: CGPoint(x: faceRect.minX, y: faceRect.maxY), end: CGPoint(x: faceRect.maxX, y: faceRect.minY), options: [])
// Circular brushing: faint concentric rings
ctx.setLineWidth(1.2)
var seed: UInt32 = 12345
for r in stride(from: CGFloat(6), to: faceR, by: 3.0) {
    seed = seed &* 1103515245 &+ 12345
    let v = CGFloat((seed >> 16) & 0xFF) / 255
    ctx.setStrokeColor(rgb(1, 1, 1, 0.05 + 0.10 * v))
    ctx.strokeEllipse(in: CGRect(x: knobCenter.x - r, y: knobCenter.y - r, width: 2 * r, height: 2 * r))
}
// Anisotropic highlight sweep
ctx.drawLinearGradient(gradient([rgb(1, 1, 1, 0), rgb(1, 1, 1, 0.35), rgb(1, 1, 1, 0), rgb(0, 0, 0, 0.12), rgb(0, 0, 0, 0)], [0.1, 0.3, 0.45, 0.7, 0.9]),
                       start: CGPoint(x: faceRect.minX, y: faceRect.maxY), end: CGPoint(x: faceRect.maxX, y: faceRect.minY), options: [])
ctx.restoreGState()

// Face edge ring
ctx.setStrokeColor(rgb(0.35, 0.36, 0.38, 0.9)); ctx.setLineWidth(3); ctx.strokeEllipse(in: faceRect)

// Indicator: a short blue-lit notch near the rim at 1 o'clock
let notchAngle: CGFloat = .pi / 2 - .pi / 7
let notchStart = CGPoint(x: knobCenter.x + cos(notchAngle) * (faceR - 90), y: knobCenter.y + sin(notchAngle) * (faceR - 90))
let notchEnd = CGPoint(x: knobCenter.x + cos(notchAngle) * (faceR - 28), y: knobCenter.y + sin(notchAngle) * (faceR - 28))
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 18, color: rgb(0.3, 0.6, 1.0, 0.9))
ctx.setStrokeColor(rgb(0.45, 0.72, 1.0)); ctx.setLineWidth(22); ctx.setLineCap(.round)
ctx.move(to: notchStart); ctx.addLine(to: notchEnd); ctx.strokePath()
ctx.restoreGState()
ctx.setStrokeColor(rgb(0.85, 0.93, 1.0)); ctx.setLineWidth(8); ctx.setLineCap(.round)
ctx.move(to: notchStart); ctx.addLine(to: notchEnd); ctx.strokePath()

// Write the master PNG and the iconset
let image = ctx.makeImage()!
let fm = FileManager.default
let iconset = "\(outDir)/Knurl.iconset"
try? fm.removeItem(atPath: iconset)
try! fm.createDirectory(atPath: iconset, withIntermediateDirectories: true)

func write(_ img: CGImage, _ path: String) {
    let rep = NSBitmapImageRep(cgImage: img)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}
write(image, "\(outDir)/Knurl-1024.png")

for (px, name) in [(16, "16x16"), (32, "16x16@2x"), (32, "32x32"), (64, "32x32@2x"), (128, "128x128"), (256, "128x128@2x"),
                   (256, "256x256"), (512, "256x256@2x"), (512, "512x512"), (1024, "512x512@2x")] {
    let c = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.interpolationQuality = .high
    c.draw(image, in: CGRect(x: 0, y: 0, width: px, height: px))
    write(c.makeImage()!, "\(iconset)/icon_\(name).png")
}

let task = Process()
task.launchPath = "/usr/bin/iconutil"
task.arguments = ["-c", "icns", iconset, "-o", "\(outDir)/Knurl.icns"]
task.launch(); task.waitUntilExit()
try? fm.removeItem(atPath: iconset)
print(task.terminationStatus == 0 ? "Wrote \(outDir)/Knurl.icns" : "iconutil failed")
