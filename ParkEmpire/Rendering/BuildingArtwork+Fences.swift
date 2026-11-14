import SpriteKit
import UIKit

/// The fences and the cash machine.
///
/// A fence is drawn from a post at the middle of its tile with an arm running
/// out to each side that has another fence against it, so a row of them reads
/// as one continuous fence. `mask` carries those sides: 1 up the screen, 2
/// right, 4 down, 8 left, the same bits the walkway uses. Texture space runs
/// y downward from the top-left.
extension BuildingArtwork {

    private static func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> UIBezierPath {
        UIBezierPath(rect: CGRect(x: x, y: y, width: w, height: h))
    }

    private static func pill(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ corner: CGFloat) -> UIBezierPath {
        UIBezierPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: corner)
    }

    private static func disc(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> UIBezierPath {
        UIBezierPath(ovalIn: CGRect(x: x, y: y, width: w, height: h))
    }

    private struct FenceArm {
        let rect: CGRect
        let horizontal: Bool
    }

    /// A fence on its own is drawn as a short run left to right, so it still
    /// looks like a fence.
    private static func fenceSides(_ mask: Int) -> Int {
        mask & 15 == 0 ? (2 | 8) : (mask & 15)
    }

    /// The strip from the middle of the tile to one edge, `thickness` across.
    private static func fenceArms(_ size: CGSize, _ mask: Int, _ thickness: CGFloat) -> [FenceArm] {
        let cx = size.width / 2
        let cy = size.height / 2
        let t = size.width * thickness
        let sides = fenceSides(mask)
        var result: [FenceArm] = []
        if sides & 1 != 0 { result.append(FenceArm(rect: CGRect(x: cx - t / 2, y: 0, width: t, height: cy + t / 2), horizontal: false)) }
        if sides & 4 != 0 { result.append(FenceArm(rect: CGRect(x: cx - t / 2, y: cy - t / 2, width: t, height: size.height - (cy - t / 2)), horizontal: false)) }
        if sides & 2 != 0 { result.append(FenceArm(rect: CGRect(x: cx - t / 2, y: cy - t / 2, width: size.width - (cx - t / 2), height: t), horizontal: true)) }
        if sides & 8 != 0 { result.append(FenceArm(rect: CGRect(x: 0, y: cy - t / 2, width: cx + t / 2, height: t), horizontal: true)) }
        return result
    }

    static func drawFence(_ context: CGContext, _ size: CGSize, _ motif: BuildingMotif,
                          _ primary: UIColor, _ secondary: UIColor, _ accent: UIColor, _ mask: Int) {
        switch motif {
        case .picketFence: drawPicketFence(context, size, primary, secondary, accent, mask)
        case .rusticFence: drawRusticFence(context, size, primary, secondary, accent, mask)
        case .ironFence: drawIronFence(context, size, primary, secondary, accent, mask)
        default: drawStoneWall(context, size, primary, secondary, accent, mask)
        }
    }

    private static func drawPicketFence(_ context: CGContext, _ size: CGSize,
                                        _ white: UIColor, _ cream: UIColor, _ wood: UIColor, _ mask: Int) {
        let w = size.width
        let h = size.height
        let strips = fenceArms(size, mask, 0.12)
        withShadow(context) {
            for arm in strips { fill(UIBezierPath(rect: arm.rect), white) }
        }
        // The pickets stand across the rail.
        for arm in strips {
            let r = arm.rect
            let count = 4
            for index in 0..<count {
                let t = (CGFloat(index) + 0.5) / CGFloat(count)
                if arm.horizontal {
                    let x = r.minX + r.width * t - w * 0.035
                    fill(pill(x, r.minY - h * 0.10, w * 0.07, r.height + h * 0.20, w * 0.03), white)
                    fill(box(x + w * 0.01, r.minY - h * 0.10, w * 0.02, r.height + h * 0.20), cream)
                } else {
                    let y = r.minY + r.height * t - h * 0.035
                    fill(pill(r.minX - w * 0.10, y, r.width + w * 0.20, h * 0.07, h * 0.03), white)
                    fill(box(r.minX - w * 0.10, y + h * 0.01, r.width + w * 0.20, h * 0.02), cream)
                }
            }
        }
        // The post, with a cap.
        withShadow(context) { fill(pill(w * 0.40, h * 0.40, w * 0.20, h * 0.20, w * 0.04), white) }
        fill(pill(w * 0.37, h * 0.37, w * 0.26, h * 0.26, w * 0.05), cream)
        fill(pill(w * 0.42, h * 0.42, w * 0.16, h * 0.16, w * 0.03), wood)
    }

    private static func drawRusticFence(_ context: CGContext, _ size: CGSize,
                                        _ bark: UIColor, _ light: UIColor, _ shade: UIColor, _ mask: Int) {
        let w = size.width
        let h = size.height
        // Two rails, side by side along each arm.
        for arm in fenceArms(size, mask, 0.22) {
            let r = arm.rect
            let rail = (arm.horizontal ? r.height : r.width) * 0.34
            withShadow(context) {
                if arm.horizontal {
                    fill(pill(r.minX, r.minY, r.width, rail, rail * 0.5), bark)
                    fill(pill(r.minX, r.maxY - rail, r.width, rail, rail * 0.5), bark)
                } else {
                    fill(pill(r.minX, r.minY, rail, r.height, rail * 0.5), bark)
                    fill(pill(r.maxX - rail, r.minY, rail, r.height, rail * 0.5), bark)
                }
            }
            // A lit edge on each rail.
            if arm.horizontal {
                fill(pill(r.minX, r.minY, r.width, rail * 0.4, rail * 0.2), light)
                fill(pill(r.minX, r.maxY - rail, r.width, rail * 0.4, rail * 0.2), light)
            } else {
                fill(pill(r.minX, r.minY, rail * 0.4, r.height, rail * 0.2), light)
                fill(pill(r.maxX - rail, r.minY, rail * 0.4, r.height, rail * 0.2), light)
            }
        }
        // A log post with a cut end.
        withShadow(context) { fill(disc(w * 0.36, h * 0.36, w * 0.28, h * 0.28), bark) }
        fill(disc(w * 0.40, h * 0.40, w * 0.20, h * 0.20), light)
        fill(disc(w * 0.46, h * 0.46, w * 0.08, h * 0.08), shade)
    }

    private static func drawIronFence(_ context: CGContext, _ size: CGSize,
                                      _ iron: UIColor, _ sheen: UIColor, _ gold: UIColor, _ mask: Int) {
        let w = size.width
        let h = size.height
        for arm in fenceArms(size, mask, 0.20) {
            let r = arm.rect
            let bars = 4
            withShadow(context) {
                if arm.horizontal {
                    fill(box(r.minX, r.minY + r.height * 0.18, r.width, r.height * 0.10), iron)
                    fill(box(r.minX, r.maxY - r.height * 0.28, r.width, r.height * 0.10), iron)
                } else {
                    fill(box(r.minX + r.width * 0.18, r.minY, r.width * 0.10, r.height), iron)
                    fill(box(r.maxX - r.width * 0.28, r.minY, r.width * 0.10, r.height), iron)
                }
            }
            for index in 0..<bars {
                let t = (CGFloat(index) + 0.5) / CGFloat(bars)
                if arm.horizontal {
                    let x = r.minX + r.width * t - w * 0.016
                    fill(box(x, r.minY, w * 0.032, r.height), iron)
                    // Spear tip.
                    let tip = UIBezierPath()
                    tip.move(to: CGPoint(x: x - w * 0.02, y: r.minY))
                    tip.addLine(to: CGPoint(x: x + w * 0.016, y: r.minY - h * 0.07))
                    tip.addLine(to: CGPoint(x: x + w * 0.052, y: r.minY))
                    tip.close()
                    fill(tip, iron)
                } else {
                    let y = r.minY + r.height * t - h * 0.016
                    fill(box(r.minX, y, r.width, h * 0.032), iron)
                    let tip = UIBezierPath()
                    tip.move(to: CGPoint(x: r.minX, y: y - h * 0.02))
                    tip.addLine(to: CGPoint(x: r.minX - w * 0.07, y: y + h * 0.016))
                    tip.addLine(to: CGPoint(x: r.minX, y: y + h * 0.052))
                    tip.close()
                    fill(tip, iron)
                }
            }
            // A glint along the top rail.
            if arm.horizontal {
                fill(box(r.minX, r.minY + r.height * 0.18, r.width, r.height * 0.03), sheen)
            } else {
                fill(box(r.minX + r.width * 0.18, r.minY, r.width * 0.03, r.height), sheen)
            }
        }
        // Heavy post with a gilded ball.
        withShadow(context) { fill(pill(w * 0.38, h * 0.38, w * 0.24, h * 0.24, w * 0.03), iron) }
        fill(pill(w * 0.42, h * 0.42, w * 0.16, h * 0.16, w * 0.02), sheen)
        fill(disc(w * 0.43, h * 0.43, w * 0.14, h * 0.14), gold)
    }

    private static func drawStoneWall(_ context: CGContext, _ size: CGSize,
                                      _ stone: UIColor, _ mortar: UIColor, _ shade: UIColor, _ mask: Int) {
        let w = size.width
        let h = size.height
        let strips = fenceArms(size, mask, 0.30)
        withShadow(context) {
            for arm in strips {
                fill(pill(arm.rect.minX, arm.rect.minY, arm.rect.width, arm.rect.height, w * 0.04), stone)
            }
            fill(pill(w * 0.33, h * 0.33, w * 0.34, h * 0.34, w * 0.05), stone)
        }
        // A pale cap on top, and the joints between blocks.
        for arm in strips {
            let r = arm.rect
            fill(pill(r.minX + w * 0.015, r.minY + h * 0.015, r.width - w * 0.03, r.height - h * 0.03, w * 0.03),
                 mortar.withAlphaComponent(0.55))
            let blocks = 3
            for index in 1..<blocks {
                let t = CGFloat(index) / CGFloat(blocks)
                if arm.horizontal {
                    fill(box(r.minX + r.width * t, r.minY + h * 0.02, w * 0.014, r.height - h * 0.04),
                         shade.withAlphaComponent(0.7))
                } else {
                    fill(box(r.minX + w * 0.02, r.minY + r.height * t, r.width - w * 0.04, h * 0.014),
                         shade.withAlphaComponent(0.7))
                }
            }
        }
        fill(pill(w * 0.355, h * 0.355, w * 0.29, h * 0.29, w * 0.04), mortar.withAlphaComponent(0.6))
        fill(box(w * 0.40, h * 0.49, w * 0.20, h * 0.014), shade.withAlphaComponent(0.7))
    }

    /// A free-standing cash machine: a steel kiosk with a lit screen, a keypad
    /// and a slot.
    static func drawCashMachine(_ context: CGContext, _ size: CGSize,
                                _ body: UIColor, _ panel: UIColor, _ glow: UIColor) {
        let w = size.width
        let h = size.height
        fill(disc(w * 0.12, h * 0.84, w * 0.76, h * 0.12), UIColor.black.withAlphaComponent(0.18))
        withShadow(context) { fill(pill(w * 0.20, h * 0.08, w * 0.60, h * 0.80, w * 0.06), body) }
        // Header sign.
        fill(pill(w * 0.24, h * 0.11, w * 0.52, h * 0.12, w * 0.03), glow)
        fill(pill(w * 0.30, h * 0.145, w * 0.40, h * 0.04, w * 0.015), UIColor.white.withAlphaComponent(0.85))
        // Screen.
        fill(pill(w * 0.28, h * 0.27, w * 0.44, h * 0.22, w * 0.03), UIColor(red: 0.07, green: 0.12, blue: 0.16, alpha: 1))
        fill(pill(w * 0.31, h * 0.30, w * 0.38, h * 0.16, w * 0.02), panel)
        fill(pill(w * 0.34, h * 0.33, w * 0.20, h * 0.03, w * 0.01), UIColor.white.withAlphaComponent(0.7))
        // Keypad.
        for row in 0..<3 {
            for column in 0..<3 {
                fill(pill(w * (0.30 + CGFloat(column) * 0.085), h * (0.54 + CGFloat(row) * 0.060),
                          w * 0.07, h * 0.045, w * 0.01),
                     UIColor.white.withAlphaComponent(0.78))
            }
        }
        // Cash slot, with notes poking out.
        fill(pill(w * 0.30, h * 0.74, w * 0.40, h * 0.05, w * 0.015), UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 1))
        fill(pill(w * 0.36, h * 0.72, w * 0.28, h * 0.04, w * 0.01), UIColor(red: 0.55, green: 0.84, blue: 0.56, alpha: 1))
    }
}
