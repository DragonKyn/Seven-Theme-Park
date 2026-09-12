import SpriteKit
import UIKit

/// The carnival booths.
///
/// Every one of them is the same shell — a striped valance, a back board and a
/// counter — with a different game painted on the board. That is deliberate:
/// a row of booths along a walkway should read as a midway at a glance, and
/// what separates one from the next is the game, not the architecture.
///
/// Kept out of `BuildingArtwork` because that file is already the longest in
/// the project, and a booth is a self-contained piece of drawing.
extension BuildingArtwork {

    // MARK: - The shell every booth shares

    /// Draws the booth and hands back the board the game goes on.
    @discardableResult
    static func boothShell(_ context: CGContext,
                           _ size: CGSize,
                           _ primary: UIColor,
                           _ secondary: UIColor,
                           _ accent: UIColor) -> CGRect {
        let body = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.07, dy: size.height * 0.07)

        withShadow(context) {
            fill(UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.10), primary)
        }

        // Striped valance across the top, scalloped along its lower edge.
        let valance = CGRect(x: body.minX, y: body.minY,
                             width: body.width, height: body.height * 0.20)
        context.saveGState()
        UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.10).addClip()
        let stripes = 7
        for index in 0..<stripes {
            let stripe = CGRect(x: valance.minX + valance.width * CGFloat(index) / CGFloat(stripes),
                                y: valance.minY,
                                width: valance.width / CGFloat(stripes),
                                height: valance.height)
            fill(UIBezierPath(rect: stripe),
                 index % 2 == 0 ? secondary : ParkPalette.colour(.cream))
        }
        context.restoreGState()

        let scallops = 7
        let radius = valance.width / CGFloat(scallops) / 2
        for index in 0..<scallops {
            let centre = CGPoint(x: valance.minX + radius * CGFloat(index * 2 + 1),
                                 y: valance.maxY)
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - radius, y: centre.y - radius * 0.7,
                                             width: radius * 2, height: radius * 1.4)),
                 index % 2 == 0 ? secondary : ParkPalette.colour(.cream))
        }

        // Back board: the dark face the game is painted on.
        let board = CGRect(x: body.minX + body.width * 0.10,
                           y: body.minY + body.height * 0.28,
                           width: body.width * 0.80,
                           height: body.height * 0.42)
        fill(UIBezierPath(roundedRect: board, cornerRadius: board.height * 0.10),
             ParkPalette.colour(.charcoal))
        stroke(UIBezierPath(roundedRect: board, cornerRadius: board.height * 0.10),
               accent, width: max(1, size.width * 0.016))

        // Counter across the front, with a lip so it reads as a surface.
        let counter = CGRect(x: body.minX + body.width * 0.06,
                             y: body.maxY - body.height * 0.22,
                             width: body.width * 0.88,
                             height: body.height * 0.14)
        fill(UIBezierPath(roundedRect: counter, cornerRadius: counter.height * 0.3), accent)
        fill(UIBezierPath(rect: CGRect(x: counter.minX, y: counter.minY,
                                       width: counter.width, height: counter.height * 0.32)),
             UIColor.white.withAlphaComponent(0.22))

        hangPrizes(size, body: body)
        return board
    }

    /// Plush prizes strung along the top corners. They are what tells a guest
    /// walking past that there is something to win here.
    private static func hangPrizes(_ size: CGSize, body: CGRect) {
        let colours: [ParkColour] = [.pink, .cyan, .yellow, .lime]
        // The big one hangs in the middle of the run, where everybody walking
        // past looks. That is how a midway sells a game.
        let sizes: [CGFloat] = [0.09, 0.15, 0.08, 0.11]

        for (index, x) in [0.08, 0.92, 0.20, 0.80].enumerated() {
            let side = body.width * sizes[index % sizes.count]
            let centre = CGPoint(x: body.minX + body.width * CGFloat(x),
                                 y: body.minY + body.height * (index < 2 ? 0.30 : 0.26))
            let colour = ParkPalette.colour(colours[index % colours.count])

            let string = UIBezierPath()
            string.move(to: CGPoint(x: centre.x, y: body.minY + body.height * 0.18))
            string.addLine(to: centre)
            stroke(string, ParkPalette.colour(.cream).withAlphaComponent(0.7),
                   width: max(0.5, size.width * 0.006))

            // Body, head and two ears: enough for a plush at this size.
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - side / 2, y: centre.y,
                                             width: side, height: side * 1.1)), colour)
            let head = side * 0.72
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - head / 2, y: centre.y - head * 0.62,
                                             width: head, height: head)), colour)
            let ear = head * 0.42
            for dx in [-head * 0.34, head * 0.34] {
                fill(UIBezierPath(ovalIn: CGRect(x: centre.x + dx - ear / 2,
                                                 y: centre.y - head * 0.78,
                                                 width: ear, height: ear)), colour)
            }
        }
    }

    /// Somewhere to put the thing the guest picks up: a ball, a mallet, a gun.
    private static func counterLine(_ size: CGSize) -> CGFloat {
        size.height * 0.78
    }

    // MARK: - The games

    static func drawBasketballGame(_ context: CGContext,
                                   _ size: CGSize,
                                   _ primary: UIColor,
                                   _ secondary: UIColor,
                                   _ accent: UIColor) {
        let board = boothShell(context, size, primary, secondary, accent)

        // Two backboards with a hoop and a net under each.
        for x in [0.32, 0.68] as [CGFloat] {
            let centre = CGPoint(x: board.minX + board.width * x,
                                 y: board.minY + board.height * 0.38)
            let backboard = CGRect(x: centre.x - board.width * 0.13,
                                   y: centre.y - board.height * 0.26,
                                   width: board.width * 0.26,
                                   height: board.height * 0.40)
            fill(UIBezierPath(roundedRect: backboard, cornerRadius: backboard.height * 0.12),
                 ParkPalette.colour(.cream))
            stroke(UIBezierPath(rect: backboard.insetBy(dx: backboard.width * 0.22,
                                                        dy: backboard.height * 0.24)),
                   ParkPalette.colour(.red), width: max(1, size.width * 0.010))

            let hoop = CGRect(x: centre.x - board.width * 0.08,
                              y: backboard.maxY - board.height * 0.03,
                              width: board.width * 0.16,
                              height: board.height * 0.09)
            stroke(UIBezierPath(ovalIn: hoop), ParkPalette.colour(.orange),
                   width: max(1, size.width * 0.014))

            let net = UIBezierPath()
            for step in 0...3 {
                let top = CGPoint(x: hoop.minX + hoop.width * CGFloat(step) / 3, y: hoop.midY)
                net.move(to: top)
                net.addLine(to: CGPoint(x: hoop.midX + (top.x - hoop.midX) * 0.4,
                                        y: hoop.maxY + board.height * 0.14))
            }
            stroke(net, ParkPalette.colour(.cream).withAlphaComponent(0.85),
                   width: max(0.5, size.width * 0.006))
        }

        // A ball waiting on the counter.
        let ball = size.width * 0.10
        let centre = CGPoint(x: size.width * 0.50, y: counterLine(size))
        fill(UIBezierPath(ovalIn: CGRect(x: centre.x - ball / 2, y: centre.y - ball / 2,
                                         width: ball, height: ball)),
             ParkPalette.colour(.orange))
        let seam = UIBezierPath()
        seam.move(to: CGPoint(x: centre.x - ball / 2, y: centre.y))
        seam.addLine(to: CGPoint(x: centre.x + ball / 2, y: centre.y))
        stroke(seam, ParkPalette.colour(.charcoal), width: max(0.5, size.width * 0.006))
    }

    static func drawWaterRaceGame(_ context: CGContext,
                                  _ size: CGSize,
                                  _ primary: UIColor,
                                  _ secondary: UIColor,
                                  _ accent: UIColor) {
        let board = boothShell(context, size, primary, secondary, accent)

        // Five lanes, each with a target at the bottom and a runner part way
        // up: the whole point of the game is that they are not level.
        let lanes = 5
        let heights: [CGFloat] = [0.62, 0.34, 0.78, 0.46, 0.22]
        for lane in 0..<lanes {
            let x = board.minX + board.width * (0.14 + 0.18 * CGFloat(lane))

            let rail = UIBezierPath()
            rail.move(to: CGPoint(x: x, y: board.maxY - board.height * 0.12))
            rail.addLine(to: CGPoint(x: x, y: board.minY + board.height * 0.12))
            stroke(rail, ParkPalette.colour(.slate), width: max(1, size.width * 0.008))

            let runner = CGRect(x: x - board.width * 0.045,
                                y: board.maxY - board.height * (0.12 + 0.68 * heights[lane]),
                                width: board.width * 0.09,
                                height: board.height * 0.13)
            fill(UIBezierPath(roundedRect: runner, cornerRadius: runner.height * 0.3),
                 ParkPalette.colour([.red, .yellow, .lime, .cyan, .violet][lane]))

            let target = board.width * 0.07
            fill(UIBezierPath(ovalIn: CGRect(x: x - target / 2,
                                             y: board.maxY - board.height * 0.18,
                                             width: target, height: target)),
                 ParkPalette.colour(.cream))
            fill(UIBezierPath(ovalIn: CGRect(x: x - target * 0.18,
                                             y: board.maxY - board.height * 0.18 + target * 0.32,
                                             width: target * 0.36, height: target * 0.36)),
                 ParkPalette.colour(.red))
        }

        // Water guns bolted to the counter, muzzles up at the board.
        for x in [0.30, 0.50, 0.70] as [CGFloat] {
            let foot = CGPoint(x: size.width * x, y: counterLine(size))
            let gun = UIBezierPath()
            gun.move(to: CGPoint(x: foot.x, y: foot.y + size.height * 0.02))
            gun.addLine(to: CGPoint(x: foot.x, y: foot.y - size.height * 0.05))
            stroke(gun, ParkPalette.colour(.charcoal), width: max(1, size.width * 0.018))
            fill(UIBezierPath(ovalIn: CGRect(x: foot.x - size.width * 0.016,
                                             y: foot.y - size.height * 0.07,
                                             width: size.width * 0.032,
                                             height: size.height * 0.03)),
                 ParkPalette.colour(.cyan))
        }
    }

    static func drawBalloonGame(_ context: CGContext,
                                _ size: CGSize,
                                _ primary: UIColor,
                                _ secondary: UIColor,
                                _ accent: UIColor) {
        let board = boothShell(context, size, primary, secondary, accent)

        // A wall of balloons, one row already burst.
        let columns = 6
        let rows = 3
        let palette: [ParkColour] = [.red, .yellow, .cyan, .lime, .violet, .orange]
        let width = board.width / CGFloat(columns)
        let height = board.height / CGFloat(rows)

        for row in 0..<rows {
            for column in 0..<columns {
                let centre = CGPoint(x: board.minX + width * (CGFloat(column) + 0.5),
                                     y: board.minY + height * (CGFloat(row) + 0.5))
                // One gap, so the wall reads as a game in progress.
                if row == 1 && column == 3 {
                    stroke(UIBezierPath(ovalIn: CGRect(x: centre.x - width * 0.26,
                                                       y: centre.y - height * 0.26,
                                                       width: width * 0.52, height: height * 0.52)),
                           ParkPalette.colour(.slate), width: max(0.5, size.width * 0.005))
                    continue
                }
                let colour = ParkPalette.colour(palette[(row * columns + column) % palette.count])
                fill(UIBezierPath(ovalIn: CGRect(x: centre.x - width * 0.30,
                                                 y: centre.y - height * 0.32,
                                                 width: width * 0.60, height: height * 0.64)),
                     colour)
            }
        }

        // Darts on the counter, points inward.
        for x in [0.38, 0.50, 0.62] as [CGFloat] {
            let dart = UIBezierPath()
            let foot = CGPoint(x: size.width * x, y: counterLine(size))
            dart.move(to: CGPoint(x: foot.x, y: foot.y + size.height * 0.03))
            dart.addLine(to: CGPoint(x: foot.x, y: foot.y - size.height * 0.04))
            stroke(dart, ParkPalette.colour(.cream), width: max(1, size.width * 0.010))
            fill(UIBezierPath(ovalIn: CGRect(x: foot.x - size.width * 0.012,
                                             y: foot.y - size.height * 0.055,
                                             width: size.width * 0.024,
                                             height: size.height * 0.022)),
                 ParkPalette.colour(.red))
        }
    }

    static func drawTargetGame(_ context: CGContext,
                               _ size: CGSize,
                               _ primary: UIColor,
                               _ secondary: UIColor,
                               _ accent: UIColor) {
        let board = boothShell(context, size, primary, secondary, accent)

        // Three targets, ringed, on stands.
        for x in [0.22, 0.50, 0.78] as [CGFloat] {
            let centre = CGPoint(x: board.minX + board.width * x,
                                 y: board.minY + board.height * 0.42)
            let outer = min(board.width * 0.22, board.height * 0.60)

            let stand = UIBezierPath()
            stand.move(to: centre)
            stand.addLine(to: CGPoint(x: centre.x, y: board.maxY - board.height * 0.06))
            stroke(stand, ParkPalette.colour(.slate), width: max(1, size.width * 0.010))

            let rings: [(CGFloat, ParkColour)] = [(1.0, .cream), (0.68, .red), (0.34, .cream)]
            for (scale, colour) in rings {
                let side = outer * scale
                fill(UIBezierPath(ovalIn: CGRect(x: centre.x - side / 2, y: centre.y - side / 2,
                                                 width: side, height: side)),
                     ParkPalette.colour(colour))
            }
            let pip = outer * 0.16
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - pip / 2, y: centre.y - pip / 2,
                                             width: pip, height: pip)),
                 ParkPalette.colour(.red))
        }

        // A rifle lying across the counter.
        let rifle = CGRect(x: size.width * 0.34, y: counterLine(size) - size.height * 0.012,
                           width: size.width * 0.32, height: size.height * 0.024)
        fill(UIBezierPath(roundedRect: rifle, cornerRadius: rifle.height / 2),
             ParkPalette.colour(.charcoal))
        fill(UIBezierPath(roundedRect: CGRect(x: rifle.minX, y: rifle.minY - rifle.height * 0.6,
                                              width: rifle.width * 0.26,
                                              height: rifle.height * 2.2),
                          cornerRadius: rifle.height * 0.6),
             ParkPalette.colour(.brown))
    }

    static func drawMoleGame(_ context: CGContext,
                             _ size: CGSize,
                             _ primary: UIColor,
                             _ secondary: UIColor,
                             _ accent: UIColor) {
        let board = boothShell(context, size, primary, secondary, accent)

        // A green field with holes in it. The moles themselves are the moving
        // parts and are drawn over the top of this.
        let field = board.insetBy(dx: board.width * 0.05, dy: board.height * 0.10)
        fill(UIBezierPath(roundedRect: field, cornerRadius: field.height * 0.18),
             ParkPalette.colour(.green))

        for x in [0.20, 0.50, 0.80] as [CGFloat] {
            for y in [0.34, 0.72] as [CGFloat] {
                let hole = CGRect(x: field.minX + field.width * x - field.width * 0.09,
                                  y: field.minY + field.height * y - field.height * 0.09,
                                  width: field.width * 0.18,
                                  height: field.height * 0.18)
                fill(UIBezierPath(ovalIn: hole), ParkPalette.colour(.charcoal))
                fill(UIBezierPath(ovalIn: hole.insetBy(dx: hole.width * 0.14,
                                                       dy: hole.height * 0.14)),
                     UIColor.black.withAlphaComponent(0.55))
            }
        }

        // Mallet on the counter.
        let handle = UIBezierPath()
        handle.move(to: CGPoint(x: size.width * 0.42, y: counterLine(size) + size.height * 0.02))
        handle.addLine(to: CGPoint(x: size.width * 0.58, y: counterLine(size) - size.height * 0.03))
        stroke(handle, ParkPalette.colour(.brown), width: max(1, size.width * 0.014))
        let head = CGRect(x: size.width * 0.56, y: counterLine(size) - size.height * 0.055,
                          width: size.width * 0.09, height: size.height * 0.045)
        fill(UIBezierPath(roundedRect: head, cornerRadius: head.height * 0.3),
             ParkPalette.colour(.red))
    }

    static func drawStrengthTester(_ context: CGContext,
                                   _ size: CGSize,
                                   _ primary: UIColor,
                                   _ secondary: UIColor,
                                   _ accent: UIColor) {
        let board = boothShell(context, size, primary, secondary, accent)

        // A column up the middle of the board, banded from green to red, with
        // a bell on top. The puck that climbs it is the moving part.
        let column = CGRect(x: board.midX - board.width * 0.07,
                            y: board.minY + board.height * 0.08,
                            width: board.width * 0.14,
                            height: board.height * 0.84)
        fill(UIBezierPath(roundedRect: column, cornerRadius: column.width * 0.3),
             ParkPalette.colour(.charcoal))

        let bands: [ParkColour] = [.red, .orange, .amber, .lime, .green]
        for (index, colour) in bands.enumerated() {
            let slice = CGRect(x: column.minX + column.width * 0.18,
                               y: column.minY + column.height * CGFloat(index) / CGFloat(bands.count),
                               width: column.width * 0.64,
                               height: column.height / CGFloat(bands.count) * 0.82)
            fill(UIBezierPath(roundedRect: slice, cornerRadius: slice.height * 0.2),
                 ParkPalette.colour(colour))
        }

        let bell = min(board.width * 0.16, board.height * 0.28)
        let bellPath = UIBezierPath(arcCenter: CGPoint(x: column.midX, y: column.minY),
                                    radius: bell / 2,
                                    startAngle: .pi, endAngle: 0, clockwise: true)
        bellPath.close()
        fill(bellPath, ParkPalette.colour(.amber))

        // Sledgehammer resting against the counter.
        let shaft = UIBezierPath()
        shaft.move(to: CGPoint(x: size.width * 0.26, y: counterLine(size) + size.height * 0.04))
        shaft.addLine(to: CGPoint(x: size.width * 0.34, y: counterLine(size) - size.height * 0.08))
        stroke(shaft, ParkPalette.colour(.brown), width: max(1, size.width * 0.016))
        let head = CGRect(x: size.width * 0.30, y: counterLine(size) - size.height * 0.11,
                          width: size.width * 0.09, height: size.height * 0.04)
        fill(UIBezierPath(roundedRect: head, cornerRadius: head.height * 0.25),
             ParkPalette.colour(.slate))
    }

    static func drawRingTossGame(_ context: CGContext,
                                 _ size: CGSize,
                                 _ primary: UIColor,
                                 _ secondary: UIColor,
                                 _ accent: UIColor) {
        let board = boothShell(context, size, primary, secondary, accent)

        // Rows of bottles, a couple of them already ringed.
        let columns = 5
        let rows = 2
        for row in 0..<rows {
            for column in 0..<columns {
                let x = board.minX + board.width * (0.12 + 0.19 * CGFloat(column))
                let base = board.minY + board.height * (0.52 + 0.40 * CGFloat(row))

                let bottle = UIBezierPath()
                let bodyWidth = board.width * 0.075
                bottle.move(to: CGPoint(x: x - bodyWidth / 2, y: base))
                bottle.addLine(to: CGPoint(x: x - bodyWidth / 2, y: base - board.height * 0.20))
                bottle.addLine(to: CGPoint(x: x - bodyWidth * 0.18, y: base - board.height * 0.32))
                bottle.addLine(to: CGPoint(x: x + bodyWidth * 0.18, y: base - board.height * 0.32))
                bottle.addLine(to: CGPoint(x: x + bodyWidth / 2, y: base - board.height * 0.20))
                bottle.addLine(to: CGPoint(x: x + bodyWidth / 2, y: base))
                bottle.close()
                fill(bottle, ParkPalette.colour(row == 0 ? .green : .teal))

                guard (row + column) % 4 == 1 else { continue }
                let ring = CGRect(x: x - bodyWidth * 0.70, y: base - board.height * 0.24,
                                  width: bodyWidth * 1.40, height: board.height * 0.09)
                stroke(UIBezierPath(ovalIn: ring), ParkPalette.colour(.red),
                       width: max(1, size.width * 0.009))
            }
        }

        // Spare rings stacked on the counter.
        for x in [0.40, 0.52, 0.64] as [CGFloat] {
            let ring = CGRect(x: size.width * x - size.width * 0.045,
                              y: counterLine(size) - size.height * 0.016,
                              width: size.width * 0.09, height: size.height * 0.032)
            stroke(UIBezierPath(ovalIn: ring), ParkPalette.colour(.yellow),
                   width: max(1, size.width * 0.010))
        }
    }

    // MARK: - Moving parts

    /// A mole, drawn from its shoulders up, because that is all a hole shows.
    static func drawMole(_ context: CGContext, _ size: CGSize, _ variant: Int) {
        let fur = ParkPalette.colour(.brown)
        let body = CGRect(origin: .zero, size: size).insetBy(dx: size.width * 0.08, dy: 0)
        fill(UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.44), fur)

        let snout = CGRect(x: body.midX - body.width * 0.22,
                           y: body.midY,
                           width: body.width * 0.44,
                           height: body.height * 0.30)
        fill(UIBezierPath(ovalIn: snout), ParkPalette.colour(.sand))
        fill(UIBezierPath(ovalIn: CGRect(x: snout.midX - snout.width * 0.12,
                                         y: snout.midY - snout.height * 0.10,
                                         width: snout.width * 0.24,
                                         height: snout.height * 0.24)),
             ParkPalette.colour(.charcoal))

        let eye = body.width * 0.13
        for dx in [-body.width * 0.20, body.width * 0.20] {
            fill(UIBezierPath(ovalIn: CGRect(x: body.midX + dx - eye / 2,
                                             y: body.minY + body.height * 0.24,
                                             width: eye, height: eye)),
                 ParkPalette.colour(.charcoal))
        }

        // Every third mole wears the hat, so the board is not three of one thing.
        guard variant % 3 == 2 else { return }
        fill(UIBezierPath(roundedRect: CGRect(x: body.minX, y: body.minY,
                                              width: body.width, height: body.height * 0.18),
                          cornerRadius: body.height * 0.08),
             ParkPalette.colour(.red))
    }

    /// The puck that climbs the strength tester.
    static func drawStrikerPuck(_ context: CGContext, _ size: CGSize, _ accent: UIColor) {
        let body = CGRect(origin: .zero, size: size)
        fill(UIBezierPath(roundedRect: body, cornerRadius: body.height * 0.4),
             ParkPalette.colour(.cream))
        fill(UIBezierPath(roundedRect: body.insetBy(dx: body.width * 0.18,
                                                    dy: body.height * 0.28),
                          cornerRadius: body.height * 0.2),
             accent)
    }
}
