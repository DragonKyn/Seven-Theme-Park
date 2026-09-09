import SpriteKit
import UIKit

/// Generates the placeholder artwork programmatically.
///
/// Everything the map draws is a rounded rectangle or a circle rendered once
/// and cached as an `SKTexture`, which keeps the project asset-free until real
/// art is worth making.
enum SpriteFactory {

    private static var cache: [String: SKTexture] = [:]

    static func clearCache() {
        cache.removeAll()
    }

    /// Flat tile with a subtle inset border.
    static func tileTexture(colour: UIColor, side: CGFloat) -> SKTexture {
        texture(key: "tile-\(colour.hashValue)-\(side)", size: CGSize(width: side, height: side)) { context, size in
            colour.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

            context.setStrokeColor(UIColor.black.withAlphaComponent(0.05).cgColor)
            context.setLineWidth(1)
            context.stroke(CGRect(origin: .zero, size: size))
        }
    }

    /// Rounded block used for rides, shops and facilities.
    static func buildingTexture(colour: UIColor, size: CGSize) -> SKTexture {
        texture(key: "building-\(colour.hashValue)-\(size.width)x\(size.height)", size: size) { context, size in
            let inset = min(size.width, size.height) * 0.07
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            let radius = min(rect.width, rect.height) * 0.18

            context.setShadow(offset: CGSize(width: 0, height: -2),
                              blur: 4,
                              color: UIColor.black.withAlphaComponent(0.25).cgColor)

            colour.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()

            context.setShadow(offset: .zero, blur: 0, color: nil)

            // Light top face to give a hint of depth without going isometric.
            let highlight = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.12)
            UIColor.white.withAlphaComponent(0.22).setFill()
            UIBezierPath(roundedRect: CGRect(x: highlight.minX,
                                             y: highlight.midY,
                                             width: highlight.width,
                                             height: highlight.height / 2),
                         cornerRadius: radius * 0.6).fill()
        }
    }

    static func circleTexture(colour: UIColor, diameter: CGFloat) -> SKTexture {
        texture(key: "circle-\(colour.hashValue)-\(diameter)",
                size: CGSize(width: diameter, height: diameter)) { _, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            UIColor.white.withAlphaComponent(0.85).setFill()
            UIBezierPath(ovalIn: rect).fill()
            colour.setFill()
            UIBezierPath(ovalIn: rect.insetBy(dx: 1.5, dy: 1.5)).fill()
        }
    }

    /// Scattered specks of rubbish. Three intensity steps are enough to read
    /// the difference at a glance, and it keeps the texture cache tiny.
    static func litterTexture(intensity: Int, side: CGFloat) -> SKTexture {
        texture(key: "litter-\(intensity)-\(side)", size: CGSize(width: side, height: side)) { _, size in
            let count = 2 + intensity * 3
            // Fixed offsets rather than randomness so the same tile always
            // draws the same way between frames.
            let offsets: [(CGFloat, CGFloat)] = [
                (0.22, 0.31), (0.68, 0.19), (0.44, 0.62), (0.81, 0.71),
                (0.14, 0.77), (0.57, 0.42), (0.33, 0.12), (0.72, 0.51),
                (0.09, 0.48), (0.90, 0.36), (0.51, 0.86)
            ]
            ParkPalette.litter.setFill()
            for index in 0..<min(count, offsets.count) {
                let offset = offsets[index]
                let dotSize = size.width * (index % 2 == 0 ? 0.10 : 0.07)
                let rect = CGRect(x: offset.0 * size.width - dotSize / 2,
                                  y: offset.1 * size.height - dotSize / 2,
                                  width: dotSize,
                                  height: dotSize)
                UIBezierPath(ovalIn: rect).fill()
            }
        }
    }

    static func outlineTexture(colour: UIColor, size: CGSize, lineWidth: CGFloat = 3) -> SKTexture {
        texture(key: "outline-\(colour.hashValue)-\(size.width)x\(size.height)-\(lineWidth)", size: size) { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
            context.setStrokeColor(colour.cgColor)
            context.setLineWidth(lineWidth)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 6)
            path.lineWidth = lineWidth
            path.stroke()
        }
    }

    // MARK: - Rendering helper

    private static func texture(key: String,
                                size: CGSize,
                                draw: (CGContext, CGSize) -> Void) -> SKTexture {
        if let cached = cache[key] { return cached }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { rendererContext in
            draw(rendererContext.cgContext, size)
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        cache[key] = texture
        return texture
    }
}
