import SpriteKit
import UIKit

/// A placed building: the block itself plus its name and a queue-length badge.
@MainActor
final class BuildingNode: SKSpriteNode {

    private let titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private let badgeLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private let badgeBackground = SKSpriteNode()
    private var badgeColour: UIColor = ParkPalette.badge

    init(texture: SKTexture, size: CGSize, title: String) {
        super.init(texture: texture, color: .clear, size: size)

        titleLabel.text = title
        titleLabel.fontSize = 9
        titleLabel.fontColor = .white
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: -size.height / 2 - 8)
        titleLabel.zPosition = 2
        addChild(titleLabel)

        badgeBackground.texture = SpriteFactory.circleTexture(colour: ParkPalette.badge, diameter: 18)
        badgeBackground.size = CGSize(width: 18, height: 18)
        badgeBackground.position = CGPoint(x: size.width / 2 - 4, y: size.height / 2 - 4)
        badgeBackground.zPosition = 3
        badgeBackground.isHidden = true
        addChild(badgeBackground)

        badgeLabel.fontSize = 10
        badgeLabel.fontColor = .white
        badgeLabel.verticalAlignmentMode = .center
        badgeLabel.horizontalAlignmentMode = .center
        badgeLabel.zPosition = 1
        badgeBackground.addChild(badgeLabel)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("BuildingNode is created in code only")
    }

    func setTitle(_ title: String) {
        guard titleLabel.text != title else { return }
        titleLabel.text = title
    }

    /// Shows the number of guests waiting, a warning marker, or nothing.
    func setBadge(_ text: String?, colour: UIColor = ParkPalette.badge) {
        guard let text else {
            badgeBackground.isHidden = true
            return
        }
        badgeBackground.isHidden = false
        if colour != badgeColour {
            badgeColour = colour
            badgeBackground.texture = SpriteFactory.circleTexture(colour: colour, diameter: 18)
        }
        if badgeLabel.text != text {
            badgeLabel.text = text
        }
    }

    func setDimmed(_ dimmed: Bool) {
        let target: CGFloat = dimmed ? 0.45 : 1.0
        if abs(alpha - target) > 0.01 {
            alpha = target
        }
    }
}
