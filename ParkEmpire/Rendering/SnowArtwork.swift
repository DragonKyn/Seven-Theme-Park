import SpriteKit
import UIKit

/// The seasonal dusting of snow over the ground. It is drawn over the
/// ordinary tile, not instead of it, so grass is still grass and the layout is
/// as easy to read as ever. Placement is fixed by where the tile is, so the
/// same tile always has the same snow on it.
enum SnowArtwork {

    private static let white = UIColor(red: 0.97, green: 0.98, blue: 1.0, alpha: 1)
    private static let shade = UIColor(red: 0.78, green: 0.85, blue: 0.94, alpha: 1)

    static func takesSnow(_ terrain: TerrainType) -> Bool {
        switch terrain {
        case .grass, .path, .bridge, .rock, .forest, .water: return true
        default: return false
        }
    }

    /// The tile with snow on it, or the tile itself for ground that does not take any.
    static func dust(_ base: SKTexture, terrain: TerrainType, seed: Int, mask: Int, style: Int, side: CGFloat) -> SKTexture {
        guard takesSnow(terrain) else { return base }
        let key = "snow-\(terrain)-\(style)-\(seed)-\(mask)-\(Int(side))"
        let size = CGSize(width: side, height: side)
        return SpriteFactory.texture(key: key, size: size) { _, size in
            UIImage(cgImage: base.cgImage()).draw(in: CGRect(origin: .zero, size: size))
            overlay(terrain, seed: seed, mask: mask, size: size)
        }
    }

    /// A little deterministic number generator, so snow never moves about
    /// between frames or runs.
    private struct Lcg {
        var state: UInt64
        init(seed: Int) { state = (UInt64(truncatingIfNeeded: seed) &* 2_654_435_761 &+ 12_345) & 0x7fff_ffff }
        mutating func next() -> CGFloat {
            state = (state &* 1_103_515_245 &+ 12_345) & 0x7fff_ffff
            return CGFloat(state % 10_000) / 10_000
        }
    }

    private static func patch(_ size: CGSize, _ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat, _ alpha: CGFloat) {
        let rect = CGRect(x: size.width * cx - size.width * w / 2, y: size.height * cy - size.height * h / 2,
                          width: size.width * w, height: size.height * h)
        white.withAlphaComponent(alpha).setFill()
        UIBezierPath(ovalIn: rect).fill()
    }

    private static func frost(_ size: CGSize, _ alpha: CGFloat) {
        white.withAlphaComponent(alpha).setFill()
        UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
    }

    private static func overlay(_ terrain: TerrainType, seed: Int, mask: Int, size: CGSize) {
        var rng = Lcg(seed: terrain.hashValueForSnow * 131 + seed * 17 + mask * 3)
        switch terrain {
        case .grass:
            frost(size, 0.74)
            for _ in 0..<3 {
                let w = 0.22 + rng.next() * 0.30
                patch(size, rng.next(), rng.next(), w, w * (0.5 + rng.next() * 0.3), 0.55)
            }
            shade.withAlphaComponent(0.22).setFill()
            for _ in 0..<2 {
                UIBezierPath(ovalIn: CGRect(x: size.width * (0.1 + rng.next() * 0.7), y: size.height * (0.1 + rng.next() * 0.7),
                                            width: size.width * 0.14, height: size.height * 0.06)).fill()
            }
        case .path, .bridge:
            frost(size, 0.28)
            for _ in 0..<3 {
                let w = 0.12 + rng.next() * 0.16
                patch(size, 0.10 + rng.next() * 0.80, 0.10 + rng.next() * 0.80, w, w * 0.7, 0.55)
            }
        case .rock:
            frost(size, 0.40)
            for _ in 0..<3 {
                let w = 0.22 + rng.next() * 0.2
                patch(size, rng.next(), 0.1 + rng.next() * 0.5, w, w * 0.6, 0.85)
            }
        case .forest:
            frost(size, 0.34)
            for _ in 0..<4 {
                let w = 0.16 + rng.next() * 0.2
                patch(size, rng.next(), rng.next(), w, w * 0.7, 0.75)
            }
        case .water:
            white.withAlphaComponent(0.55).setFill()
            for _ in 0..<3 {
                let w = 0.14 + rng.next() * 0.12
                UIBezierPath(ovalIn: CGRect(x: size.width * (0.10 + rng.next() * 0.70), y: size.height * (0.10 + rng.next() * 0.78),
                                            width: size.width * w, height: size.height * w * 0.45)).fill()
            }
        default:
            break
        }
    }
}

private extension TerrainType {
    /// A stable small number per terrain, since `hashValue` changes between runs.
    var hashValueForSnow: Int {
        switch self {
        case .grass: return 0
        case .path: return 1
        case .bridge: return 2
        case .rock: return 3
        case .forest: return 4
        case .water: return 5
        default: return 9
        }
    }
}
