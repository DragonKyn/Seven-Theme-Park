import UIKit

/// Small pictures of whole maps, for choosing between them.
///
/// Flat colours, one per kind of ground, rather than the tile artwork: at the
/// size of a menu card a map is sixty tiles across a hundred points, and what
/// matters is the shape of the land, not the texture of the grass.
enum MapArtwork {

    static func colour(for ground: MapGround) -> UIColor {
        switch ground {
        case .grass: return ParkPalette.grass
        case .water: return ParkPalette.water
        case .rock: return ParkPalette.rock
        case .forest: return ParkPalette.forest
        }
    }

    static let gate = ParkPalette.colour(.amber)

    /// The map with its gate marked. Row 0, where the gate is, is drawn at
    /// the bottom, the same way up the park is on screen.
    static func thumbnail(for layout: MapLayout, side: CGFloat) -> UIImage {
        let key = "\(layout.hashValue)-\(Int(side))"
        if let cached = cache[key] { return cached }

        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { renderer in
            draw(layout, in: renderer.cgContext, size: CGSize(width: side, height: side))
        }

        if cache.count > cacheLimit { cache.removeAll() }
        cache[key] = image
        return image
    }

    /// Draws a layout into any context: the thumbnails above, and the editor's
    /// canvas through the same colours.
    ///
    /// Runs of the same ground along a row are filled as one rectangle, which
    /// turns three and a half thousand fills into a few hundred.
    static func draw(_ layout: MapLayout, in context: CGContext, size: CGSize) {
        let cellWidth = size.width / CGFloat(layout.width)
        let cellHeight = size.height / CGFloat(layout.height)

        for y in 0..<layout.height {
            let top = size.height - CGFloat(y + 1) * cellHeight
            var runStart = 0
            var runGround = layout.ground(atX: 0, y: y)
            for x in 1...layout.width {
                let ground = x < layout.width ? layout.ground(atX: x, y: y) : nil
                guard ground != runGround else { continue }
                context.setFillColor(colour(for: runGround).cgColor)
                // A hair over, so neighbouring runs never show a seam.
                context.fill(CGRect(x: CGFloat(runStart) * cellWidth,
                                    y: top,
                                    width: CGFloat(x - runStart) * cellWidth + 0.5,
                                    height: cellHeight + 0.5))
                if let ground {
                    runStart = x
                    runGround = ground
                }
            }
        }

        // The gate, a notch bigger than one tile so it can be found.
        let gateWidth = max(cellWidth * 3, 4)
        let gateHeight = max(cellHeight * 2, 3)
        context.setFillColor(gate.cgColor)
        context.fill(CGRect(x: (CGFloat(layout.entranceX) + 0.5) * cellWidth - gateWidth / 2,
                            y: size.height - gateHeight,
                            width: gateWidth,
                            height: gateHeight))
    }

    private static var cache: [String: UIImage] = [:]
    private static let cacheLimit = 40
}
