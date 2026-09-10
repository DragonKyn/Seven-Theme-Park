import SpriteKit
import UIKit

/// Draws guests and the bubbles that appear over their heads.
///
/// The figure itself is `PersonArtwork`'s job. What belongs here is turning a
/// guest's appearance and mood into one.
enum GuestArtwork {

    /// Width of a guest sprite as a share of its height.
    static let aspect = PersonArtwork.aspect

    // MARK: - Guests

    static func texture(for appearance: GuestAppearance,
                        age: AgeCategory,
                        mood: GuestMood,
                        height: CGFloat) -> SKTexture {
        let size = CGSize(width: height * aspect * PersonArtwork.supersample,
                          height: height * PersonArtwork.supersample)
        let key = "guest-\(appearance.shirt.rawValue)-\(appearance.hair.rawValue)"
            + "-\(appearance.skin.rawValue)-\(appearance.hat.rawValue)"
            + "-\(age.rawValue)-\(mood.rawValue)-\(Int(size.height))"

        return SpriteFactory.texture(key: key, size: size) { context, size in
            PersonArtwork.draw(look(for: appearance, age: age),
                               tint: moodColour(mood),
                               context: context,
                               size: size)
        }
    }

    private static func look(for appearance: GuestAppearance,
                             age: AgeCategory) -> PersonArtwork.Look {
        // Children are shorter and seniors slightly stooped, drawn as a scale
        // rather than as separate artwork.
        let heightScale: CGFloat
        switch age {
        case .child: heightScale = 0.78
        case .senior: heightScale = 0.92
        case .adult: heightScale = 1.0
        }

        let headwear: PersonArtwork.Headwear
        switch appearance.hat {
        case .none: headwear = .none
        case .cap: headwear = .cap
        case .sunHat: headwear = .sunHat
        }

        return PersonArtwork.Look(
            skin: appearance.skin,
            hair: appearance.hair,
            shirt: ParkPalette.colour(appearance.shirt),
            headwear: headwear,
            // A cap matches the shirt; a sun hat is straw whatever they wear.
            headwearColour: appearance.hat == .sunHat
                ? ParkPalette.colour(.cream)
                : ParkPalette.colour(appearance.shirt),
            heightScale: heightScale)
    }

    private static func moodColour(_ mood: GuestMood) -> UIColor {
        switch mood {
        case .unhappy: return ParkPalette.guestUnhappy
        case .neutral: return ParkPalette.guestNeutral
        case .happy: return ParkPalette.guestHappy
        }
    }

    // MARK: - Thought bubbles

    /// A rounded bubble with a tail and a symbol inside it. The bubble is
    /// tinted by mood so a park full of red bubbles reads as trouble from
    /// across the map, before any one of them is legible.
    static func bubbleTexture(icon: ThoughtIcon, mood: ThoughtMood, side: CGFloat) -> SKTexture {
        let size = CGSize(width: side * PersonArtwork.supersample,
                          height: side * PersonArtwork.supersample)
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
