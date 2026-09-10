import SpriteKit
import UIKit

/// Draws guests and the bubbles that appear over their heads.
///
/// A guest is small on screen, so the figure is built from four shapes and
/// nothing else: a mood ring, a body, a head, and whatever is on it. What
/// carries variety is the combination, not the detail.
enum GuestArtwork {

    /// How much bigger the texture is drawn than the sprite it fills, so the
    /// figure survives being zoomed in on.
    private static let supersample: CGFloat = 3

    // MARK: - Guests

    static func texture(for appearance: GuestAppearance,
                        age: AgeCategory,
                        mood: GuestMood,
                        height: CGFloat) -> SKTexture {
        let size = CGSize(width: height * 0.72 * supersample, height: height * supersample)
        let key = "guest-\(appearance.shirt.rawValue)-\(appearance.hair.rawValue)"
            + "-\(appearance.skin.rawValue)-\(appearance.hat.rawValue)"
            + "-\(age.rawValue)-\(mood.rawValue)-\(Int(size.height))"

        return SpriteFactory.texture(key: key, size: size) { context, size in
            draw(appearance, age: age, mood: mood, context: context, size: size)
        }
    }

    /// The proportion of the sprite's width to its height. Kept here so the
    /// scene sizes the node the same way the texture is drawn.
    static let aspect: CGFloat = 0.72

    private static func draw(_ appearance: GuestAppearance,
                             age: AgeCategory,
                             mood: GuestMood,
                             context: CGContext,
                             size: CGSize) {
        // Children are shorter and rounder; seniors slightly stooped. Drawn as
        // a scale rather than separate artwork.
        let scale: CGFloat
        switch age {
        case .child: scale = 0.78
        case .senior: scale = 0.92
        case .adult: scale = 1.0
        }

        let figureHeight = size.height * scale
        let bottom = size.height - (size.height - figureHeight) * 0.25
        let headSize = figureHeight * 0.42
        let centreX = size.width / 2

        // Mood ring behind everything: the one thing that has to be readable
        // when the park is zoomed out and the figure is six pixels tall.
        let ring = CGRect(x: centreX - size.width * 0.48,
                          y: bottom - figureHeight * 0.92,
                          width: size.width * 0.96,
                          height: figureHeight * 0.92)
        moodColour(mood).withAlphaComponent(0.95).setFill()
        UIBezierPath(roundedRect: ring, cornerRadius: ring.width * 0.42).fill()

        // Body.
        let bodyWidth = size.width * 0.62
        let body = CGRect(x: centreX - bodyWidth / 2,
                          y: bottom - figureHeight * 0.60,
                          width: bodyWidth,
                          height: figureHeight * 0.50)
        ParkPalette.colour(appearance.shirt).setFill()
        UIBezierPath(roundedRect: body, cornerRadius: bodyWidth * 0.30).fill()

        // Head.
        let head = CGRect(x: centreX - headSize / 2,
                          y: bottom - figureHeight * 0.60 - headSize * 0.78,
                          width: headSize,
                          height: headSize)
        skinColour(appearance.skin).setFill()
        UIBezierPath(ovalIn: head).fill()

        // Hair sits as a cap over the top half of the head, which reads at
        // this size where individual strands would not.
        let hair = UIBezierPath()
        hair.addArc(withCenter: CGPoint(x: head.midX, y: head.midY),
                    radius: head.width / 2,
                    startAngle: .pi,
                    endAngle: 0,
                    clockwise: true)
        hair.close()
        hairColour(appearance.hair).setFill()
        hair.fill()

        switch appearance.hat {
        case .none:
            break
        case .cap:
            let crown = CGRect(x: head.minX, y: head.minY - head.height * 0.10,
                               width: head.width, height: head.height * 0.46)
            ParkPalette.colour(appearance.shirt).setFill()
            UIBezierPath(roundedRect: crown, cornerRadius: crown.height * 0.5).fill()
            let peak = CGRect(x: head.midX, y: head.minY + head.height * 0.22,
                              width: head.width * 0.62, height: head.height * 0.14)
            UIBezierPath(roundedRect: peak, cornerRadius: peak.height / 2).fill()
        case .sunHat:
            let brim = CGRect(x: head.minX - head.width * 0.28,
                              y: head.minY + head.height * 0.16,
                              width: head.width * 1.56, height: head.height * 0.20)
            ParkPalette.colour(.cream).setFill()
            UIBezierPath(ovalIn: brim).fill()
            let crown = CGRect(x: head.minX + head.width * 0.16,
                               y: head.minY - head.height * 0.08,
                               width: head.width * 0.68, height: head.height * 0.38)
            UIBezierPath(ovalIn: crown).fill()
        }
    }

    private static func moodColour(_ mood: GuestMood) -> UIColor {
        switch mood {
        case .unhappy: return ParkPalette.guestUnhappy
        case .neutral: return ParkPalette.guestNeutral
        case .happy: return ParkPalette.guestHappy
        }
    }

    private static func skinColour(_ tone: GuestAppearance.SkinTone) -> UIColor {
        switch tone {
        case .deep:  return UIColor(red: 0.42, green: 0.28, blue: 0.20, alpha: 1)
        case .tan:   return UIColor(red: 0.68, green: 0.48, blue: 0.34, alpha: 1)
        case .olive: return UIColor(red: 0.83, green: 0.66, blue: 0.48, alpha: 1)
        case .fair:  return UIColor(red: 0.95, green: 0.81, blue: 0.68, alpha: 1)
        }
    }

    private static func hairColour(_ colour: GuestAppearance.HairColour) -> UIColor {
        switch colour {
        case .dark:   return UIColor(red: 0.16, green: 0.13, blue: 0.12, alpha: 1)
        case .brown:  return UIColor(red: 0.40, green: 0.27, blue: 0.17, alpha: 1)
        case .sandy:  return UIColor(red: 0.79, green: 0.66, blue: 0.39, alpha: 1)
        case .ginger: return UIColor(red: 0.76, green: 0.40, blue: 0.19, alpha: 1)
        case .grey:   return UIColor(red: 0.78, green: 0.78, blue: 0.79, alpha: 1)
        }
    }

    // MARK: - Thought bubbles

    /// A rounded bubble with a tail and a symbol inside it. The bubble is
    /// tinted by mood so a park full of red bubbles reads as trouble from
    /// across the map, before any one of them is legible.
    static func bubbleTexture(icon: ThoughtIcon, mood: ThoughtMood, side: CGFloat) -> SKTexture {
        let size = CGSize(width: side * supersample, height: side * supersample)
        let key = "bubble-\(icon.rawValue)-\(mood.rawValue)-\(Int(size.width))"

        return SpriteFactory.texture(key: key, size: size) { context, size in
            let tint = bubbleColour(mood)

            // Tail first, so the body of the bubble covers where they join.
            let tail = UIBezierPath()
            tail.move(to: CGPoint(x: size.width * 0.40, y: size.height * 0.72))
            tail.addLine(to: CGPoint(x: size.width * 0.34, y: size.height * 0.98))
            tail.addLine(to: CGPoint(x: size.width * 0.60, y: size.height * 0.76))
            tail.close()
            tint.setFill()
            tail.fill()

            let body = CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.80)
            context.setShadow(offset: CGSize(width: 0, height: size.height * 0.03),
                              blur: size.height * 0.06,
                              color: UIColor.black.withAlphaComponent(0.25).cgColor)
            UIBezierPath(roundedRect: body, cornerRadius: body.height * 0.34).fill()
            context.setShadow(offset: .zero, blur: 0, color: nil)

            let inner = body.insetBy(dx: body.width * 0.09, dy: body.height * 0.11)
            UIColor.white.withAlphaComponent(0.92).setFill()
            UIBezierPath(roundedRect: inner, cornerRadius: inner.height * 0.32).fill()

            guard let symbol = UIImage(systemName: icon.symbolName) else { return }
            let glyphSide = min(inner.width, inner.height) * 0.78
            let glyph = CGRect(x: inner.midX - glyphSide / 2,
                               y: inner.midY - glyphSide / 2,
                               width: glyphSide, height: glyphSide)
            symbol.withTintColor(tint, renderingMode: .alwaysOriginal).draw(in: glyph)
        }
    }

    private static func bubbleColour(_ mood: ThoughtMood) -> UIColor {
        switch mood {
        case .positive: return ParkPalette.guestHappy
        case .neutral: return UIColor(red: 0.33, green: 0.40, blue: 0.52, alpha: 1)
        case .negative: return ParkPalette.guestUnhappy
        }
    }
}

/// The three-step mood a guest is drawn with. Kept coarse on purpose: a
/// continuous colour ramp is unreadable at this size and would defeat the
/// texture cache.
enum GuestMood: String {
    case unhappy
    case neutral
    case happy

    init(happiness: Double) {
        switch happiness {
        case ..<40: self = .unhappy
        case ..<70: self = .neutral
        default: self = .happy
        }
    }
}
