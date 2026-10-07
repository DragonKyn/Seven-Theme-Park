import SpriteKit
import UIKit

/// The balls a juggler keeps in the air.
///
/// They are sprites of their own on top of the juggler's, not part of the
/// painting, because a ball painted into a still picture is a ball hanging in
/// mid air. Each one flies a parabola from one hand to the other and is
/// caught and thrown back, and the three are started a beat apart so that
/// there is always one on the way up, one on the way down and one in a hand:
/// the ordinary three-ball cascade.
enum JugglerRig {

    private static let ballName = "juggling-ball"
    private static let colours: [ParkColour] = [.red, .yellow, .blue]

    /// Seconds a ball is in the air, and seconds between throws. Three throws
    /// land in one flight, which is what makes it a cascade.
    private static let flight: TimeInterval = 0.9
    private static var beat: TimeInterval { flight / 3 }

    /// Puts the balls on a juggler's sprite, or takes them off anybody who is
    /// not one. Safe to call again whenever the look changes.
    static func configure(_ node: SKSpriteNode, look: StaffLook) {
        node.children.filter { $0.name == ballName }.forEach { $0.removeFromParent() }
        guard look.role == .entertainer, look.act == .juggler else { return }

        let canvas = node.size
        let figure = canvas.height * StaffArtwork.figureScale(for: look)
        let bottom = canvas.height - (canvas.height - figure) * 0.20

        // Hands at the hips, either side of the body, in the node's own
        // coordinates: y up, origin in the middle.
        let handY = canvas.height / 2 - (bottom - figure * 0.30)
        let reach = figure * 0.24
        let left = CGPoint(x: -reach, y: handY)
        let right = CGPoint(x: reach, y: handY)
        let lift = figure * 0.62
        let diameter = figure * 0.16

        for (index, colour) in colours.enumerated() {
            let ball = SKSpriteNode(texture: ballTexture(colour))
            ball.name = ballName
            ball.size = CGSize(width: diameter, height: diameter)
            ball.zPosition = 0.5

            // Throws alternate hands every beat, so the second ball starts
            // from the right hand and the first and third from the left.
            let startsLeft = index % 2 == 0
            let first = startsLeft ? left : right
            let second = startsLeft ? right : left
            ball.position = first

            let there = arc(from: first, to: second, lift: lift)
            let back = arc(from: second, to: first, lift: lift)
            ball.run(.sequence([
                .wait(forDuration: beat * Double(index)),
                .repeatForever(.sequence([there, back]))
            ]))
            node.addChild(ball)
        }
    }

    /// One throw: a true parabola, so the ball hangs at the top the way a
    /// thrown ball does and is quick on the way up and down.
    private static func arc(from start: CGPoint, to end: CGPoint, lift: CGFloat) -> SKAction {
        SKAction.customAction(withDuration: flight) { node, elapsed in
            let u = CGFloat(elapsed / CGFloat(flight))
            node.position = CGPoint(x: start.x + (end.x - start.x) * u,
                                    y: start.y + (end.y - start.y) * u + 4 * lift * u * (1 - u))
        }
    }

    private static func ballTexture(_ colour: ParkColour) -> SKTexture {
        let size = CGSize(width: 48, height: 48)
        return SpriteFactory.texture(key: "juggling-ball-\(colour.rawValue)", size: size) { _, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 3, dy: 3)
            ParkPalette.colour(colour).setFill()
            UIBezierPath(ovalIn: rect).fill()
            UIColor.black.withAlphaComponent(0.30).setStroke()
            let outline = UIBezierPath(ovalIn: rect)
            outline.lineWidth = 3
            outline.stroke()
            UIColor.white.withAlphaComponent(0.6).setFill()
            UIBezierPath(ovalIn: CGRect(x: size.width * 0.28, y: size.height * 0.24,
                                        width: size.width * 0.18, height: size.height * 0.18)).fill()
        }
    }
}
