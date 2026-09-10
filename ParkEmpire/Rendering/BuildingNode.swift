import SpriteKit
import UIKit

/// A placed building: the block itself plus its name and a queue-length badge.
@MainActor
final class BuildingNode: SKSpriteNode {

    private let titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private let badgeLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private let badgeBackground = SKSpriteNode()
    private var badgeColour: UIColor = ParkPalette.badge
    /// The one part of the building that moves, if it has one.
    private var motionNode: SKSpriteNode?

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

    // MARK: - Motion

    /// Adds the moving part for this motif and starts it. Called once, when
    /// the node is created.
    func configureMotion(appearance: BuildingAppearance, buildingSize: CGSize) {
        guard motionNode == nil,
              let texture = BuildingArtwork.motionTexture(for: appearance, size: buildingSize)
        else { return }

        let partSize = BuildingArtwork.motionPartSize(for: appearance.motif,
                                                      buildingSize: buildingSize)
        let node = SKSpriteNode(texture: texture)
        node.size = partSize
        node.zPosition = 1

        switch appearance.motif.motion {
        case .none:
            return

        case .spin:
            node.position = .zero
            node.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 7)))

        case .swing:
            // Pivot at the A-frame apex, so the hull swings from its arms
            // rather than spinning about its own middle.
            node.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            node.position = CGPoint(x: 0, y: buildingSize.height * 0.36)
            let left = SKAction.rotate(toAngle: 0.5, duration: 1.6)
            let right = SKAction.rotate(toAngle: -0.5, duration: 1.6)
            left.timingMode = .easeInEaseOut
            right.timingMode = .easeInEaseOut
            node.run(.repeatForever(.sequence([left, right])))

        case .rise:
            let low = -buildingSize.height * 0.20
            let high = buildingSize.height * 0.34
            node.position = CGPoint(x: 0, y: low)
            let climb = SKAction.moveTo(y: high, duration: 3.4)
            climb.timingMode = .easeOut
            let plunge = SKAction.moveTo(y: low, duration: 0.55)
            plunge.timingMode = .easeIn
            node.run(.repeatForever(.sequence([climb,
                                               .wait(forDuration: 1.1),
                                               plunge,
                                               .wait(forDuration: 1.4)])))

        case .circuit:
            // The track is drawn in texture space with y downward; the scene
            // has y upward, so the oval is rebuilt here rather than reused.
            let track = BuildingArtwork.trackRect(in: buildingSize)
            let path = CGPath(ellipseIn: CGRect(x: track.minX - buildingSize.width / 2,
                                                y: track.minY - buildingSize.height / 2,
                                                width: track.width,
                                                height: track.height),
                              transform: nil)
            node.run(.repeatForever(.follow(path,
                                            asOffset: false,
                                            orientToPath: true,
                                            duration: 5.5)))
        }

        addChild(node)
        motionNode = node
    }

    /// Freezes the moving part. A ride that has stopped moving is the clearest
    /// signal that it is closed or broken.
    func setMotionRunning(_ running: Bool) {
        guard let motionNode else { return }
        if motionNode.isPaused == running {
            motionNode.isPaused = !running
        }
    }
}
