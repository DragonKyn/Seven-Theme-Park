import SpriteKit
import UIKit

/// Scenery: the things a park is decorated with rather than the things guests
/// queue for.
///
/// Most of these are drawn several ways. One catalogue entry called "Shade
/// Tree" produces four different trees, so an avenue of them looks planted
/// rather than stamped, and the player picks a style or leaves it mixed.
extension BuildingArtwork {

    // MARK: - Planting

    static func drawTree(_ context: CGContext,
                         _ size: CGSize,
                         _ primary: UIColor,
                         _ secondary: UIColor,
                         _ accent: UIColor,
                         _ variant: Int) {
        switch variant % 4 {
        case 1:
            // Tall and narrow, for lining a walkway.
            trunk(size, accent, width: 0.10, top: 0.52)
            withShadow(context) {
                fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.22, y: size.height * 0.06,
                                                 width: size.width * 0.56,
                                                 height: size.height * 0.62)), primary)
            }
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.30, y: size.height * 0.12,
                                             width: size.width * 0.24,
                                             height: size.height * 0.30)), secondary)

        case 2:
            // Three overlapping clumps, which reads as a broad old tree.
            trunk(size, accent, width: 0.13, top: 0.60)
            withShadow(context) {
                let clumps: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.30, 0.34, 0.42), (0.66, 0.32, 0.38), (0.48, 0.22, 0.46)
                ]
                for clump in clumps {
                    let side = size.width * clump.2
                    fill(UIBezierPath(ovalIn: CGRect(x: size.width * clump.0 - side / 2,
                                                     y: size.height * clump.1 - side / 2,
                                                     width: side, height: side)), primary)
                }
            }
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.34, y: size.height * 0.18,
                                             width: size.width * 0.22,
                                             height: size.height * 0.22)), secondary)

        case 3:
            // Flat-topped, like a parasol pine.
            trunk(size, accent, width: 0.11, top: 0.44)
            withShadow(context) {
                let canopy = CGRect(x: size.width * 0.08, y: size.height * 0.20,
                                    width: size.width * 0.84, height: size.height * 0.30)
                fill(UIBezierPath(roundedRect: canopy, cornerRadius: canopy.height * 0.5), primary)
            }
            fill(UIBezierPath(roundedRect: CGRect(x: size.width * 0.18, y: size.height * 0.24,
                                                  width: size.width * 0.30,
                                                  height: size.height * 0.12),
                              cornerRadius: size.height * 0.06), secondary)

        default:
            trunk(size, accent, width: 0.12, top: 0.58)
            withShadow(context) {
                fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.12, y: size.height * 0.14,
                                                 width: size.width * 0.76,
                                                 height: size.height * 0.56)), primary)
            }
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.20, y: size.height * 0.18,
                                             width: size.width * 0.34,
                                             height: size.height * 0.34)), secondary)
        }
    }

    private static func trunk(_ size: CGSize, _ colour: UIColor, width: CGFloat, top: CGFloat) {
        let rect = CGRect(x: size.width * (0.5 - width / 2), y: size.height * top,
                          width: size.width * width, height: size.height * (0.94 - top))
        fill(UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.4), colour)
    }

    static func drawConifer(_ context: CGContext,
                            _ size: CGSize,
                            _ primary: UIColor,
                            _ secondary: UIColor,
                            _ accent: UIColor,
                            _ variant: Int) {
        trunk(size, accent, width: 0.10, top: 0.72)

        // How many tiers, and how wide they get: a young fir, a tall one and a
        // squat one from the same drawing.
        let tiers: [[(CGFloat, CGFloat, CGFloat)]] = [
            [(0.10, 0.55, 0.62), (0.32, 0.78, 0.78)],
            [(0.04, 0.36, 0.44), (0.22, 0.58, 0.62), (0.42, 0.80, 0.80)],
            [(0.22, 0.62, 0.74), (0.44, 0.82, 0.92)]
        ]

        withShadow(context) {
            for tier in tiers[variant % tiers.count] {
                let cone = UIBezierPath()
                cone.move(to: CGPoint(x: size.width * 0.5, y: size.height * tier.0))
                cone.addLine(to: CGPoint(x: size.width * (0.5 + tier.2 / 2), y: size.height * tier.1))
                cone.addLine(to: CGPoint(x: size.width * (0.5 - tier.2 / 2), y: size.height * tier.1))
                cone.close()
                fill(cone, primary)
            }
        }
    }

    static func drawFlowerBed(_ context: CGContext,
                              _ size: CGSize,
                              _ primary: UIColor,
                              _ secondary: UIColor,
                              _ accent: UIColor,
                              _ variant: Int) {
        let bed = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.10, dy: size.height * 0.22)
        let shape = variant % 3 == 1
            ? UIBezierPath(ovalIn: bed)
            : UIBezierPath(roundedRect: bed, cornerRadius: bed.height * 0.3)
        fill(shape, accent)

        // Scattered, in rows, or a ring round a centrepiece.
        let layouts: [[(CGFloat, CGFloat)]] = [
            [(0.26, 0.36), (0.50, 0.28), (0.74, 0.38), (0.34, 0.62), (0.62, 0.66), (0.50, 0.50)],
            [(0.24, 0.38), (0.44, 0.38), (0.64, 0.38), (0.34, 0.62), (0.54, 0.62), (0.74, 0.62)],
            [(0.50, 0.28), (0.72, 0.42), (0.66, 0.66), (0.34, 0.66), (0.28, 0.42), (0.50, 0.50)]
        ]

        for (index, spot) in layouts[variant % layouts.count].enumerated() {
            let diameter = size.width * (index == 5 && variant % 3 == 2 ? 0.22 : 0.17)
            let rect = CGRect(x: spot.0 * size.width - diameter / 2,
                              y: spot.1 * size.height - diameter / 2,
                              width: diameter, height: diameter)
            fill(UIBezierPath(ovalIn: rect), index % 2 == 0 ? primary : secondary)
        }
    }

    static func drawTopiary(_ context: CGContext,
                            _ size: CGSize,
                            _ primary: UIColor,
                            _ secondary: UIColor,
                            _ accent: UIColor,
                            _ variant: Int) {
        let planter = CGRect(x: size.width * 0.26, y: size.height * 0.66,
                             width: size.width * 0.48, height: size.height * 0.26)
        fill(UIBezierPath(roundedRect: planter, cornerRadius: planter.height * 0.22), accent)

        withShadow(context) {
            switch variant % 3 {
            case 1:
                // Two balls stacked, clipped into a lollipop.
                for (y, side) in [(0.46, 0.44), (0.20, 0.34)] as [(CGFloat, CGFloat)] {
                    let width = size.width * side
                    fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.5 - width / 2,
                                                     y: size.height * y - width / 2,
                                                     width: width, height: width)), primary)
                }
            case 2:
                // A cone, clipped to a point.
                let cone = UIBezierPath()
                cone.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.08))
                cone.addLine(to: CGPoint(x: size.width * 0.80, y: size.height * 0.70))
                cone.addLine(to: CGPoint(x: size.width * 0.20, y: size.height * 0.70))
                cone.close()
                fill(cone, primary)
            default:
                let bush = CGRect(x: size.width * 0.16, y: size.height * 0.14,
                                  width: size.width * 0.68, height: size.height * 0.58)
                fill(UIBezierPath(roundedRect: bush, cornerRadius: bush.width * 0.34), primary)
            }
        }

        let sheen = CGRect(x: size.width * 0.26, y: size.height * 0.22,
                           width: size.width * 0.26, height: size.height * 0.22)
        fill(UIBezierPath(ovalIn: sheen), secondary)
    }

    static func drawHedge(_ context: CGContext,
                          _ size: CGSize,
                          _ primary: UIColor,
                          _ secondary: UIColor,
                          _ accent: UIColor,
                          _ variant: Int) {
        let hedge = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.04, dy: size.height * 0.24)

        withShadow(context) {
            switch variant % 3 {
            case 1:
                // Clipped square, the formal cut.
                fill(UIBezierPath(roundedRect: hedge, cornerRadius: size.width * 0.06), primary)
            case 2:
                // Scalloped along the top, which reads as an untrimmed run.
                let path = UIBezierPath(roundedRect: hedge, cornerRadius: size.width * 0.10)
                fill(path, primary)
                let bumps = 3
                for index in 0..<bumps {
                    let side = size.width / CGFloat(bumps)
                    fill(UIBezierPath(ovalIn: CGRect(x: side * CGFloat(index) + side * 0.08,
                                                     y: hedge.minY - side * 0.22,
                                                     width: side * 0.84, height: side * 0.60)),
                         primary)
                }
            default:
                fill(UIBezierPath(roundedRect: hedge, cornerRadius: hedge.height * 0.34), primary)
            }
        }

        // A lighter band along the top, so the run has a lit face.
        fill(UIBezierPath(roundedRect: CGRect(x: hedge.minX + hedge.width * 0.06,
                                              y: hedge.minY + hedge.height * 0.10,
                                              width: hedge.width * 0.88,
                                              height: hedge.height * 0.22),
                          cornerRadius: hedge.height * 0.12), secondary)
    }

    // MARK: - Furniture

    static func drawLamp(_ context: CGContext,
                         _ size: CGSize,
                         _ primary: UIColor,
                         _ secondary: UIColor,
                         _ accent: UIColor,
                         _ variant: Int) {
        let base = CGRect(x: size.width * 0.34, y: size.height * 0.80,
                          width: size.width * 0.32, height: size.height * 0.12)
        fill(UIBezierPath(roundedRect: base, cornerRadius: base.height * 0.4), accent)

        let post = CGRect(x: size.width * 0.45, y: size.height * 0.30,
                          width: size.width * 0.10, height: size.height * 0.54)
        fill(UIBezierPath(rect: post), accent)

        withShadow(context) {
            if variant % 2 == 1 {
                // A lantern: four panes in a frame, the old-fashioned cut.
                let lantern = CGRect(x: size.width * 0.32, y: size.height * 0.10,
                                     width: size.width * 0.36, height: size.height * 0.28)
                fill(UIBezierPath(roundedRect: lantern, cornerRadius: size.width * 0.05), primary)
                let cap = UIBezierPath()
                cap.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.02))
                cap.addLine(to: CGPoint(x: lantern.maxX, y: lantern.minY))
                cap.addLine(to: CGPoint(x: lantern.minX, y: lantern.minY))
                cap.close()
                fill(cap, accent)
            } else {
                let head = CGRect(x: size.width * 0.30, y: size.height * 0.12,
                                  width: size.width * 0.40, height: size.height * 0.26)
                fill(UIBezierPath(ovalIn: head), primary)
            }
        }

        let glow = CGRect(x: size.width * 0.38, y: size.height * 0.18,
                          width: size.width * 0.24, height: size.height * 0.14)
        fill(UIBezierPath(ovalIn: glow), secondary)
    }

    static func drawPicnicTable(_ context: CGContext,
                                _ size: CGSize,
                                _ primary: UIColor,
                                _ secondary: UIColor,
                                _ accent: UIColor,
                                _ variant: Int) {
        // Two benches with the table between them, seen from above.
        for y in [0.20, 0.66] as [CGFloat] {
            let bench = CGRect(x: size.width * 0.12, y: size.height * y,
                               width: size.width * 0.76, height: size.height * 0.14)
            fill(UIBezierPath(roundedRect: bench, cornerRadius: bench.height * 0.4), accent)
        }

        withShadow(context) {
            let table = CGRect(x: size.width * 0.18, y: size.height * 0.36,
                               width: size.width * 0.64, height: size.height * 0.28)
            fill(UIBezierPath(roundedRect: table, cornerRadius: size.width * 0.05), primary)
        }

        if variant % 2 == 1 {
            // With a parasol through the middle of it.
            let shade = min(size.width, size.height) * 0.46
            let centre = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            withShadow(context) {
                fill(UIBezierPath(ovalIn: CGRect(x: centre.x - shade / 2, y: centre.y - shade / 2,
                                                 width: shade, height: shade)), secondary)
            }
            // Panels, so it reads as a parasol rather than a plate.
            for index in 0..<4 {
                let wedge = UIBezierPath()
                let from = CGFloat(index) * .pi / 2
                wedge.move(to: centre)
                wedge.addArc(withCenter: centre, radius: shade / 2,
                             startAngle: from, endAngle: from + .pi / 4, clockwise: true)
                wedge.close()
                fill(wedge, primary)
            }
            let pole = min(size.width, size.height) * 0.10
            fill(UIBezierPath(ovalIn: CGRect(x: centre.x - pole / 2, y: centre.y - pole / 2,
                                             width: pole, height: pole)), accent)
        } else {
            // Or with the grain of the boards showing.
            for index in 0..<3 {
                let line = CGRect(x: size.width * 0.20,
                                  y: size.height * (0.40 + 0.08 * CGFloat(index)),
                                  width: size.width * 0.60,
                                  height: max(1, size.height * 0.02))
                fill(UIBezierPath(rect: line), secondary.withAlphaComponent(0.55))
            }
        }
    }

    static func drawFlagPole(_ context: CGContext,
                             _ size: CGSize,
                             _ primary: UIColor,
                             _ secondary: UIColor,
                             _ accent: UIColor,
                             _ variant: Int) {
        let base = CGRect(x: size.width * 0.36, y: size.height * 0.78,
                          width: size.width * 0.28, height: size.height * 0.16)
        withShadow(context) {
            fill(UIBezierPath(ovalIn: base), accent)
        }

        let pole = CGRect(x: size.width * 0.47, y: size.height * 0.08,
                          width: size.width * 0.06, height: size.height * 0.76)
        fill(UIBezierPath(roundedRect: pole, cornerRadius: pole.width * 0.5), accent)

        let flag = UIBezierPath()
        let top = size.height * 0.12
        switch variant % 3 {
        case 1:
            // Swallowtail.
            flag.move(to: CGPoint(x: pole.maxX, y: top))
            flag.addLine(to: CGPoint(x: size.width * 0.94, y: top + size.height * 0.06))
            flag.addLine(to: CGPoint(x: size.width * 0.78, y: top + size.height * 0.13))
            flag.addLine(to: CGPoint(x: size.width * 0.94, y: top + size.height * 0.20))
            flag.addLine(to: CGPoint(x: pole.maxX, y: top + size.height * 0.26))
        case 2:
            // A long pennant, tapering to a point.
            flag.move(to: CGPoint(x: pole.maxX, y: top))
            flag.addLine(to: CGPoint(x: size.width * 0.96, y: top + size.height * 0.09))
            flag.addLine(to: CGPoint(x: pole.maxX, y: top + size.height * 0.18))
        default:
            // A plain rectangle, rippling along its free edge.
            flag.move(to: CGPoint(x: pole.maxX, y: top))
            flag.addLine(to: CGPoint(x: size.width * 0.90, y: top))
            flag.addQuadCurve(to: CGPoint(x: size.width * 0.90, y: top + size.height * 0.24),
                              controlPoint: CGPoint(x: size.width * 0.78,
                                                    y: top + size.height * 0.12))
            flag.addLine(to: CGPoint(x: pole.maxX, y: top + size.height * 0.24))
        }
        flag.close()
        withShadow(context) { fill(flag, primary) }

        // A band across the flag, in the park's trim.
        let band = CGRect(x: pole.maxX, y: top + size.height * 0.10,
                          width: size.width * 0.30, height: max(1, size.height * 0.04))
        fill(UIBezierPath(rect: band), secondary)
    }

    static func drawGardenArch(_ context: CGContext,
                               _ size: CGSize,
                               _ primary: UIColor,
                               _ secondary: UIColor,
                               _ accent: UIColor,
                               _ variant: Int) {
        let thickness = max(2, size.width * 0.09)

        let arch = UIBezierPath()
        arch.move(to: CGPoint(x: size.width * 0.16, y: size.height * 0.90))
        arch.addLine(to: CGPoint(x: size.width * 0.16, y: size.height * 0.46))
        arch.addQuadCurve(to: CGPoint(x: size.width * 0.84, y: size.height * 0.46),
                          controlPoint: CGPoint(x: size.width * 0.50, y: size.height * 0.02))
        arch.addLine(to: CGPoint(x: size.width * 0.84, y: size.height * 0.90))
        withShadow(context) {
            stroke(arch, primary, width: thickness)
        }

        if variant % 2 == 1 {
            // Trained with climbing flowers up both legs.
            for x in [0.16, 0.84] as [CGFloat] {
                for index in 0..<3 {
                    let dot = size.width * 0.11
                    fill(UIBezierPath(ovalIn: CGRect(x: size.width * x - dot / 2,
                                                     y: size.height * (0.52 + 0.13 * CGFloat(index)),
                                                     width: dot, height: dot)), secondary)
                }
            }
            let crown = size.width * 0.14
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.5 - crown / 2,
                                             y: size.height * 0.14,
                                             width: crown, height: crown)), secondary)
        } else {
            // Or with cross-bracing between the legs.
            for index in 0..<2 {
                let rung = UIBezierPath()
                let y = size.height * (0.58 + 0.16 * CGFloat(index))
                rung.move(to: CGPoint(x: size.width * 0.16, y: y))
                rung.addLine(to: CGPoint(x: size.width * 0.84, y: y))
                stroke(rung, secondary, width: max(1, thickness * 0.45))
            }
        }
    }

    static func drawClockTower(_ context: CGContext,
                               _ size: CGSize,
                               _ primary: UIColor,
                               _ secondary: UIColor,
                               _ accent: UIColor,
                               _ variant: Int) {
        let shaft = CGRect(x: size.width * 0.28, y: size.height * 0.26,
                           width: size.width * 0.44, height: size.height * 0.66)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: shaft, cornerRadius: size.width * 0.04), primary)
        }

        // Roof: a spire or a dome.
        if variant % 2 == 1 {
            let dome = CGRect(x: size.width * 0.24, y: size.height * 0.06,
                              width: size.width * 0.52, height: size.height * 0.30)
            fill(UIBezierPath(ovalIn: dome), accent)
        } else {
            let spire = UIBezierPath()
            spire.move(to: CGPoint(x: size.width * 0.50, y: size.height * 0.02))
            spire.addLine(to: CGPoint(x: size.width * 0.78, y: size.height * 0.28))
            spire.addLine(to: CGPoint(x: size.width * 0.22, y: size.height * 0.28))
            spire.close()
            fill(spire, accent)
        }

        // The face, with hands at ten past ten because that is how every
        // clock in every advertisement is set.
        let face = CGRect(x: size.width * 0.34, y: size.height * 0.36,
                          width: size.width * 0.32, height: size.height * 0.32)
        fill(UIBezierPath(ovalIn: face), ParkPalette.colour(.cream))
        stroke(UIBezierPath(ovalIn: face), secondary, width: max(1, size.width * 0.025))

        let hands = UIBezierPath()
        hands.move(to: CGPoint(x: face.midX, y: face.midY))
        hands.addLine(to: CGPoint(x: face.midX - face.width * 0.26, y: face.midY - face.height * 0.20))
        hands.move(to: CGPoint(x: face.midX, y: face.midY))
        hands.addLine(to: CGPoint(x: face.midX + face.width * 0.22, y: face.midY - face.height * 0.30))
        stroke(hands, ParkPalette.colour(.charcoal), width: max(1, size.width * 0.022))

        // Base course, so the tower sits on something.
        let base = CGRect(x: size.width * 0.20, y: size.height * 0.84,
                          width: size.width * 0.60, height: size.height * 0.12)
        fill(UIBezierPath(roundedRect: base, cornerRadius: size.width * 0.03), secondary)
    }

    static func drawStatue(_ context: CGContext,
                           _ size: CGSize,
                           _ primary: UIColor,
                           _ secondary: UIColor,
                           _ accent: UIColor,
                           _ variant: Int) {
        let plinth = CGRect(x: size.width * 0.22, y: size.height * 0.64,
                            width: size.width * 0.56, height: size.height * 0.28)
        withShadow(context) {
            fill(UIBezierPath(roundedRect: plinth, cornerRadius: plinth.height * 0.16), accent)
        }

        switch variant % 3 {
        case 1:
            // An urn rather than a figure.
            let urn = UIBezierPath()
            urn.move(to: CGPoint(x: size.width * 0.36, y: size.height * 0.62))
            urn.addQuadCurve(to: CGPoint(x: size.width * 0.36, y: size.height * 0.26),
                             controlPoint: CGPoint(x: size.width * 0.22, y: size.height * 0.44))
            urn.addLine(to: CGPoint(x: size.width * 0.64, y: size.height * 0.26))
            urn.addQuadCurve(to: CGPoint(x: size.width * 0.64, y: size.height * 0.62),
                             controlPoint: CGPoint(x: size.width * 0.78, y: size.height * 0.44))
            urn.close()
            fill(urn, primary)
            fill(UIBezierPath(roundedRect: CGRect(x: size.width * 0.30, y: size.height * 0.20,
                                                  width: size.width * 0.40,
                                                  height: size.height * 0.08),
                              cornerRadius: size.height * 0.04), secondary)

        case 2:
            // A rearing horse, which at this size is a body and a neck.
            let body = CGRect(x: size.width * 0.30, y: size.height * 0.38,
                              width: size.width * 0.40, height: size.height * 0.26)
            fill(UIBezierPath(roundedRect: body, cornerRadius: body.height * 0.4), primary)
            let neck = UIBezierPath()
            neck.move(to: CGPoint(x: size.width * 0.58, y: size.height * 0.46))
            neck.addLine(to: CGPoint(x: size.width * 0.72, y: size.height * 0.16))
            neck.addLine(to: CGPoint(x: size.width * 0.58, y: size.height * 0.14))
            neck.addLine(to: CGPoint(x: size.width * 0.46, y: size.height * 0.42))
            neck.close()
            fill(neck, primary)
            fill(UIBezierPath(ovalIn: CGRect(x: size.width * 0.60, y: size.height * 0.10,
                                             width: size.width * 0.18,
                                             height: size.height * 0.12)), secondary)

        default:
            let torso = CGRect(x: size.width * 0.38, y: size.height * 0.28,
                               width: size.width * 0.24, height: size.height * 0.40)
            fill(UIBezierPath(roundedRect: torso, cornerRadius: torso.width * 0.4), primary)

            let head = CGRect(x: size.width * 0.41, y: size.height * 0.14,
                              width: size.width * 0.18, height: size.height * 0.18)
            fill(UIBezierPath(ovalIn: head), primary)

            let sash = CGRect(x: torso.minX, y: torso.minY + torso.height * 0.30,
                              width: torso.width, height: max(1, size.height * 0.04))
            fill(UIBezierPath(rect: sash), secondary)
        }
    }

    // MARK: - Water

    static func drawFountainBasin(_ context: CGContext,
                                  _ size: CGSize,
                                  _ primary: UIColor,
                                  _ secondary: UIColor,
                                  _ accent: UIColor,
                                  _ variant: Int) {
        let basin = CGRect(origin: .zero, size: size)
            .insetBy(dx: size.width * 0.08, dy: size.height * 0.08)

        withShadow(context) {
            if variant % 2 == 1 {
                // Square basin, for a formal garden.
                fill(UIBezierPath(roundedRect: basin, cornerRadius: size.width * 0.06), accent)
            } else {
                fill(UIBezierPath(ovalIn: basin), accent)
            }
        }

        let water = basin.insetBy(dx: basin.width * 0.14, dy: basin.height * 0.14)
        let waterPath = variant % 2 == 1
            ? UIBezierPath(roundedRect: water, cornerRadius: size.width * 0.04)
            : UIBezierPath(ovalIn: water)
        fill(waterPath, ParkPalette.water)

        let inner = water.insetBy(dx: water.width * 0.26, dy: water.height * 0.26)
        fill(UIBezierPath(ovalIn: inner), secondary)
    }

    /// The water, drawn separately so it can pulse.
    static func drawFountainJet(_ context: CGContext,
                                _ size: CGSize,
                                _ primary: UIColor,
                                _ secondary: UIColor,
                                _ accent: UIColor) {
        let column = CGRect(x: size.width * 0.38, y: size.height * 0.18,
                            width: size.width * 0.24, height: size.height * 0.72)
        fill(UIBezierPath(roundedRect: column, cornerRadius: column.width / 2),
             ParkPalette.colour(.white).withAlphaComponent(0.85))

        let crown = CGRect(x: size.width * 0.20, y: 0,
                           width: size.width * 0.60, height: size.height * 0.30)
        fill(UIBezierPath(ovalIn: crown),
             ParkPalette.colour(.white).withAlphaComponent(0.70))
    }
}
