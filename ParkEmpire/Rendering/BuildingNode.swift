import SpriteKit
import UIKit

/// A placed building: the block itself, its name on a chip, and a queue-length
/// badge.
@MainActor
final class BuildingNode: SKSpriteNode {

    /// Holds the name chip. Kept as a container so it can be turned back
    /// upright and repositioned when the building itself is rotated.
    private let labelNode = SKNode()
    private let labelChip = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private let badgeLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private let badgeBackground = SKSpriteNode()
    private var badgeColour: UIColor = ParkPalette.badge
    /// The parts of the building that move. Most rides have one; a race
    /// track and a bumper car arena have several.
    private var motionNodes: [SKSpriteNode] = []
    /// How far below the middle of the building the name sits, before any
    /// rotation is applied.
    private var labelDrop: CGFloat = 0
    private var quarterTurns = 0

    /// A nil `title` means no label at all, which is what scenery wants: a
    /// park with forty captioned trees is unreadable.
    init(texture: SKTexture, size: CGSize, title: String?) {
        super.init(texture: texture, color: .clear, size: size)

        if let title {
            // A dark chip behind the name. White text alone disappears against
            // pale artwork and turns to mush where two buildings sit close
            // together; a chip keeps each name legible on its own.
            labelChip.fillColor = ParkPalette.labelChip
            labelChip.strokeColor = .clear
            labelChip.zPosition = 0

            titleLabel.fontSize = 9
            titleLabel.fontColor = .white
            titleLabel.verticalAlignmentMode = .center
            titleLabel.horizontalAlignmentMode = .center
            titleLabel.zPosition = 1

            labelNode.zPosition = 40
            labelNode.addChild(labelChip)
            labelNode.addChild(titleLabel)
            addChild(labelNode)

            labelDrop = size.height / 2 + 9
            labelNode.position = CGPoint(x: 0, y: -labelDrop)
            setTitle(title)
        }

        badgeBackground.texture = SpriteFactory.circleTexture(colour: ParkPalette.badge, diameter: 18)
        badgeBackground.size = CGSize(width: 18, height: 18)
        badgeBackground.position = CGPoint(x: size.width / 2 - 4, y: size.height / 2 - 4)
        badgeBackground.zPosition = 41
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

    func setTitle(_ title: String?) {
        guard let title, titleLabel.parent != nil, titleLabel.text != title else { return }
        titleLabel.text = title

        // The chip is fitted to the text rather than to the building, so a
        // Carousel and a Go Karts: Grand Prix both get a chip that suits them.
        let width = max(18, titleLabel.frame.width + 10)
        let height: CGFloat = 14
        labelChip.path = CGPath(roundedRect: CGRect(x: -width / 2, y: -height / 2,
                                                    width: width, height: height),
                                cornerWidth: height / 2,
                                cornerHeight: height / 2,
                                transform: nil)
    }

    /// Names are hidden when the park is zoomed out far enough that they would
    /// be unreadable anyway. At that distance the shape of the park is what
    /// matters, not what each thing is called.
    func setLabelVisible(_ visible: Bool) {
        guard labelNode.parent != nil, labelNode.isHidden == visible else { return }
        labelNode.isHidden = !visible
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

    /// Turns the artwork.
    ///
    /// The name and the badge are children of the building, so they would turn
    /// with it. Both are turned back upright, and the name is moved round to
    /// wherever "below the building" ended up, so a rotated ride does not end
    /// up captioned sideways off its own edge.
    func setRotation(quarterTurns: Int) {
        let turns = ((quarterTurns % 4) + 4) % 4
        guard turns != self.quarterTurns else { return }
        self.quarterTurns = turns

        let angle = -CGFloat(turns) * .pi / 2
        zRotation = angle

        labelNode.zRotation = -angle
        // Undoing the parent's rotation on a point below the centre.
        labelNode.position = CGPoint(x: sin(-angle) * labelDrop,
                                     y: -cos(-angle) * labelDrop)
        badgeBackground.zRotation = -angle
    }

    func setDimmed(_ dimmed: Bool) {
        let target: CGFloat = dimmed ? 0.45 : 1.0
        if abs(alpha - target) > 0.01 {
            alpha = target
        }
    }

    // MARK: - Motion

    /// Adds the moving parts for this motif and starts them. Called once, when
    /// the node is created.
    ///
    /// Most rides have a single moving part. A race track and a bumper car
    /// arena have several, which is the whole point of them: one kart going
    /// round on its own is a test track, not a race.
    func configureMotion(appearance: BuildingAppearance, buildingSize: CGSize) {
        guard motionNodes.isEmpty else { return }
        let motion = appearance.motif.motion
        guard motion != .none else { return }

        let partSize = BuildingArtwork.motionPartSize(for: appearance.motif,
                                                      buildingSize: buildingSize)

        for index in 0..<BuildingArtwork.motionPartCount(for: appearance.motif) {
            guard let texture = BuildingArtwork.motionTexture(for: appearance,
                                                              size: buildingSize,
                                                              variant: index) else { continue }
            let node = SKSpriteNode(texture: texture)
            node.size = partSize
            node.zPosition = 1
            apply(motion,
                  motif: appearance.motif,
                  to: node,
                  index: index,
                  buildingSize: buildingSize)
            addChild(node)
            motionNodes.append(node)
        }
    }

    private func apply(_ motion: BuildingMotion,
                       motif: BuildingMotif,
                       to node: SKSpriteNode,
                       index: Int,
                       buildingSize: CGSize) {
        switch motion {
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

        case .bob:
            // A short, slow pulse: enough to catch the eye, not enough to
            // pull attention away from the guests.
            node.position = .zero
            let up = SKAction.scaleY(to: 1.12, duration: 1.1)
            let down = SKAction.scaleY(to: 0.94, duration: 1.1)
            up.timingMode = .easeInEaseOut
            down.timingMode = .easeInEaseOut
            node.run(.repeatForever(.sequence([up, down])))

        case .launch:
            applyLaunch(to: node, buildingSize: buildingSize)

        case .slide:
            // Down one lane and straight back to the top, because there is
            // always another rider waiting.
            let top = buildingSize.height * 0.30
            let bottom = -buildingSize.height * 0.30
            let lane = -buildingSize.width * 0.24
            node.position = CGPoint(x: lane, y: top)
            let descend = SKAction.moveTo(y: bottom, duration: 1.5)
            descend.timingMode = .easeIn
            node.run(.repeatForever(.sequence([descend,
                                               .wait(forDuration: 0.5),
                                               .moveTo(y: top, duration: 0.01),
                                               .wait(forDuration: 0.8)])))

        case .hover:
            // Drifts around the porch without ever settling.
            node.position = CGPoint(x: buildingSize.width * 0.30,
                                    y: -buildingSize.height * 0.22)
            let up = SKAction.moveBy(x: 0, y: buildingSize.height * 0.10, duration: 1.9)
            let down = SKAction.moveBy(x: 0, y: -buildingSize.height * 0.10, duration: 1.9)
            up.timingMode = .easeInEaseOut
            down.timingMode = .easeInEaseOut
            node.run(.repeatForever(.sequence([up, down])))
            node.run(.repeatForever(.sequence([.fadeAlpha(to: 0.55, duration: 1.3),
                                               .fadeAlpha(to: 1.0, duration: 1.3)])))

        case .circuit:
            PathMotion.drive(node,
                             around: BuildingArtwork.motionPath(for: motif,
                                                                buildingSize: buildingSize),
                             duration: motif == .megaCoaster ? 8.5 : 5.5)

        case .race:
            applyRace(to: node, index: index, buildingSize: buildingSize)

        case .bumper:
            applyBumper(to: node, index: index, buildingSize: buildingSize)
        }
    }

    // MARK: - Multi-part motions

    /// Each kart gets its own lane and its own lap time, so they string out,
    /// close up and lap one another instead of orbiting in fixed formation.
    private func applyRace(to node: SKSpriteNode, index: Int, buildingSize: CGSize) {
        let lanes: [CGFloat] = [0, 0.055, -0.045, 0.11]
        let lapTimes: [TimeInterval] = [4.1, 4.6, 3.8, 5.0]
        // Spread round the oval rather than all leaving the line together,
        // because a race that is always restarting reads as a queue.
        let startAngles: [CGFloat] = [0, 1.9, 3.4, 4.9]

        let slot = index % lanes.count
        let points = PathMotion.ovalPoints(BuildingArtwork.trackRect(in: buildingSize),
                                     in: buildingSize,
                                     inset: lanes[slot] * min(buildingSize.width, buildingSize.height),
                                     startAngle: startAngles[slot],
                                     steps: 36)

        PathMotion.drive(node, around: points, duration: lapTimes[slot])
    }

    /// Cars cross the arena on overlapping loops at different speeds, so they
    /// keep meeting in the middle. The jolt is what sells the collision: the
    /// paths only have to bring them together at roughly the right moment.
    private func applyBumper(to node: SKSpriteNode, index: Int, buildingSize: CGSize) {
        let arena = CGSize(width: buildingSize.width * 0.62,
                           height: buildingSize.height * 0.52)

        // Fixed loops rather than random walks, so the same arena always looks
        // the same and nothing has to be simulated.
        let loops: [[CGPoint]] = [
            [CGPoint(x: -0.5, y: -0.5), CGPoint(x: 0.4, y: 0.1), CGPoint(x: -0.2, y: 0.5), CGPoint(x: 0.5, y: -0.3)],
            [CGPoint(x: 0.5, y: 0.4), CGPoint(x: -0.4, y: -0.2), CGPoint(x: 0.1, y: -0.5), CGPoint(x: -0.5, y: 0.3)],
            [CGPoint(x: -0.1, y: 0.5), CGPoint(x: 0.5, y: -0.4), CGPoint(x: -0.5, y: 0.0), CGPoint(x: 0.2, y: 0.4)],
            [CGPoint(x: 0.3, y: -0.5), CGPoint(x: -0.5, y: 0.4), CGPoint(x: 0.4, y: 0.3), CGPoint(x: -0.3, y: -0.3)],
            [CGPoint(x: -0.4, y: 0.2), CGPoint(x: 0.2, y: -0.4), CGPoint(x: 0.5, y: 0.2), CGPoint(x: -0.2, y: -0.1)]
        ]
        let lapTimes: [TimeInterval] = [5.4, 6.2, 4.8, 6.8, 5.9]
        let slot = index % loops.count

        let points = loops[slot].map { CGPoint(x: $0.x * arena.width, y: $0.y * arena.height) }
        // A bumper car turns on the spot and then drives, rather than sweeping
        // round the corner the way a kart does.
        PathMotion.drive(node, around: points, duration: lapTimes[slot], turnFraction: 0.25)

        // A short recoil on its own clock. Out of step with the driving, which
        // is what stops five cars jolting in unison.
        let jolt = SKAction.sequence([.scale(to: 1.18, duration: 0.07),
                                      .scale(to: 1.0, duration: 0.13)])
        node.run(.repeatForever(.sequence([.wait(forDuration: 1.4 + Double(slot) * 0.55),
                                           jolt])))
    }

    /// Winched down, held, then fired well clear of the masts, spinning, with
    /// a couple of diminishing bounces on the way back to the pad.
    private func applyLaunch(to node: SKSpriteNode, buildingSize: CGSize) {
        let pad = -buildingSize.height * 0.18
        let charged = -buildingSize.height * 0.38
        let apex = buildingSize.height * 1.05
        let firstBounce = buildingSize.height * 0.34
        let secondBounce = buildingSize.height * 0.08

        node.position = CGPoint(x: 0, y: pad)

        let winch = SKAction.moveTo(y: charged, duration: 1.1)
        winch.timingMode = .easeInEaseOut
        // A held breath at full stretch, which is the whole appeal of the ride.
        let strain = SKAction.sequence([.moveBy(x: buildingSize.width * 0.012, y: 0, duration: 0.05),
                                        .moveBy(x: -buildingSize.width * 0.024, y: 0, duration: 0.05),
                                        .moveBy(x: buildingSize.width * 0.012, y: 0, duration: 0.05)])

        let fire = SKAction.moveTo(y: apex, duration: 0.42)
        fire.timingMode = .easeOut
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.42)
        let launch = SKAction.group([fire, spin])

        let fall = SKAction.moveTo(y: secondBounce, duration: 0.52)
        fall.timingMode = .easeIn
        let bounceUp = SKAction.moveTo(y: firstBounce, duration: 0.34)
        bounceUp.timingMode = .easeOut
        let bounceDown = SKAction.moveTo(y: pad, duration: 0.38)
        bounceDown.timingMode = .easeIn
        let settleUp = SKAction.moveTo(y: secondBounce, duration: 0.22)
        settleUp.timingMode = .easeOut
        let settleDown = SKAction.moveTo(y: pad, duration: 0.24)
        settleDown.timingMode = .easeIn

        node.run(.repeatForever(.sequence([.wait(forDuration: 1.3),
                                           winch,
                                           .repeat(strain, count: 3),
                                           .wait(forDuration: 0.45),
                                           launch,
                                           .wait(forDuration: 0.10),
                                           fall,
                                           bounceUp,
                                           bounceDown,
                                           settleUp,
                                           settleDown,
                                           .wait(forDuration: 1.2)])))
    }

    /// Freezes every moving part. A ride that has stopped moving is the
    /// clearest signal that it is closed or broken.
    func setMotionRunning(_ running: Bool) {
        for node in motionNodes where node.isPaused == running {
            node.isPaused = !running
        }
    }
}
