import SpriteKit
import UIKit

/// Draws the park and turns touches into commands.
///
/// The scene owns no game state: every frame it advances the controller and
/// then mirrors `GameState` into nodes. Rendering is therefore free to run at
/// the display's refresh rate while the simulation ticks at its own fixed rate.
@MainActor
final class ParkScene: SKScene {

    weak var controller: GameController?

    /// A presentation scene draws the park but takes no input and drifts the
    /// camera by itself. Used for the park running behind the main menu.
    var isInteractive = true

    /// Points per tile at 1:1 zoom.
    static let tileSide: CGFloat = 32

    private let worldNode = SKNode()
    private let tileLayer = SKNode()
    private let sceneryLayer = SKNode()
    private let buildingLayer = SKNode()
    private let guestLayer = SKNode()
    private let overlayLayer = SKNode()

    private var tileNodes: [SKSpriteNode] = []
    private var buildingNodes: [UUID: BuildingNode] = [:]
    private var sceneryNodes: [UUID: BuildingNode] = [:]
    private var guestNodes: [UUID: SKSpriteNode] = [:]
    /// Which mood each guest sprite is currently drawn with, so the texture is
    /// only swapped when the mood actually changes.
    private var guestMood: [UUID: GuestMood] = [:]
    /// The last thought each guest has already had a bubble for.
    private var shownThought: [UUID: UUID] = [:]
    /// Bubbles currently on screen. Held so the cap can be enforced without a
    /// counter that a completion block would have to decrement.
    private var bubbleNodes: [SKNode] = []
    /// Ceiling on bubbles on screen at once. A park where every guest is
    /// thinking out loud is noise rather than information.
    private static let maxBubbles = 10
    private var staffNodes: [UUID: SKSpriteNode] = [:]
    private var staffTextures: [StaffRole: SKTexture] = [:]
    /// The uniform the cached staff textures were drawn in.
    private var renderedUniform: ParkColour?
    private var entranceSign: SKSpriteNode?
    private var entranceSignLabel: SKLabelNode?
    private var renderedParkName: String?
    private var litterNodes: [GridCoord: SKSpriteNode] = [:]
    private var litterIntensity: [GridCoord: Int] = [:]
    private var renderedLitterGeneration = -1
    private var ghostNode: SKSpriteNode?
    private var selectionNode: SKSpriteNode?

    private var renderedMapGeneration = -1
    private var lastFrameTime: TimeInterval = 0

    private let cameraNode = SKCameraNode()
    private var cameraPanStart: CGPoint = .zero
    private var pinchStartScale: CGFloat = 1

    private var cameraPan: UIPanGestureRecognizer?
    private var paintPan: UIPanGestureRecognizer?

    private static let minCameraScale: CGFloat = 0.4
    private static let maxCameraScale: CGFloat = 2.6

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.42, green: 0.66, blue: 0.38, alpha: 1)
        scaleMode = .resizeFill

        if worldNode.parent == nil {
            worldNode.addChild(tileLayer)
            worldNode.addChild(sceneryLayer)
            worldNode.addChild(buildingLayer)
            worldNode.addChild(overlayLayer)
            worldNode.addChild(guestLayer)
            addChild(worldNode)
        }

        tileLayer.zPosition = 0
        sceneryLayer.zPosition = 5
        buildingLayer.zPosition = 10
        overlayLayer.zPosition = 20
        guestLayer.zPosition = 30

        if cameraNode.parent == nil {
            addChild(cameraNode)
        }
        camera = cameraNode

        if isInteractive {
            cameraNode.setScale(1.0)
            centreCameraOnEntrance()
            installGestures(on: view)
        } else {
            startCameraDrift()
        }
    }

    /// Slowly sweeps the park so the menu background is never quite still.
    private func startCameraDrift() {
        guard let state = controller?.state else { return }
        cameraNode.setScale(0.78)

        let centreX = CGFloat(state.map.width) / 2 * Self.tileSide
        let low = CGPoint(x: centreX, y: Self.tileSide * 5)
        let high = CGPoint(x: centreX, y: Self.tileSide * 15)

        cameraNode.position = low
        let up = SKAction.move(to: high, duration: 26)
        let down = SKAction.move(to: low, duration: 26)
        up.timingMode = .easeInEaseOut
        down.timingMode = .easeInEaseOut
        cameraNode.run(.repeatForever(.sequence([up, down])))
    }

    private func centreCameraOnEntrance() {
        guard let state = controller?.state else { return }
        let entrance = state.map.entranceCoord
        cameraNode.position = CGPoint(x: (CGFloat(entrance.x) + 0.5) * Self.tileSide,
                                      y: (CGFloat(entrance.y) + 5) * Self.tileSide)
    }

    // MARK: - Gestures

    private func installGestures(on view: SKView) {
        view.gestureRecognizers?.forEach { view.removeGestureRecognizer($0) }

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinch)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCameraPan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 2
        view.addGestureRecognizer(pan)
        cameraPan = pan

        let paint = UIPanGestureRecognizer(target: self, action: #selector(handlePaintPan(_:)))
        paint.minimumNumberOfTouches = 1
        paint.maximumNumberOfTouches = 1
        paint.isEnabled = false
        view.addGestureRecognizer(paint)
        paintPan = paint

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)
    }

    /// A one-finger drag moves the camera in every mode except explicit
    /// drawing, so looking around the park can never place anything by
    /// accident. While drawing, one finger paints and two move the camera.
    private func updateGestureModes() {
        guard let controller else { return }
        let isPainting = controller.canDraw && controller.build.isDrawing

        guard isPainting != paintPan?.isEnabled else { return }
        paintPan?.isEnabled = isPainting
        cameraPan?.minimumNumberOfTouches = isPainting ? 2 : 1
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            pinchStartScale = cameraNode.xScale
        case .changed:
            let proposed = pinchStartScale / recognizer.scale
            cameraNode.setScale(min(max(proposed, Self.minCameraScale), Self.maxCameraScale))
            clampCamera()
        default:
            break
        }
    }

    @objc private func handleCameraPan(_ recognizer: UIPanGestureRecognizer) {
        guard let view else { return }
        switch recognizer.state {
        case .began:
            cameraPanStart = cameraNode.position
        case .changed:
            let translation = recognizer.translation(in: view)
            cameraNode.position = CGPoint(
                x: cameraPanStart.x - translation.x * cameraNode.xScale,
                y: cameraPanStart.y + translation.y * cameraNode.yScale)
            clampCamera()
        default:
            break
        }
    }

    @objc private func handlePaintPan(_ recognizer: UIPanGestureRecognizer) {
        guard let view, let controller else { return }
        let location = recognizer.location(in: view)
        guard let coord = tileCoord(atViewPoint: location) else { return }

        switch recognizer.state {
        case .began, .changed:
            controller.updateGhost(at: coord)
            controller.paint(at: coord)
        case .ended, .cancelled:
            controller.updateGhost(at: coord)
        default:
            break
        }
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let view, let controller else { return }
        let location = recognizer.location(in: view)
        guard let coord = tileCoord(atViewPoint: location) else { return }

        let scenePoint = convertPoint(fromView: location)
        let guestID = controller.build.isActive ? nil : nearestGuest(to: scenePoint)
        let staffID = (controller.build.isActive || guestID != nil)
            ? nil
            : nearestStaff(to: scenePoint)
        controller.handleTap(at: coord, guestID: guestID, staffID: staffID)
    }

    private func tileCoord(atViewPoint point: CGPoint) -> GridCoord? {
        guard let state = controller?.state else { return nil }
        let scenePoint = convertPoint(fromView: point)
        let world = worldNode.convert(scenePoint, from: self)
        let coord = GridCoord(Int(floor(world.x / Self.tileSide)),
                              Int(floor(world.y / Self.tileSide)))
        return state.map.isInside(coord) ? coord : nil
    }

    /// Guests are small; allow a generous touch radius before falling through
    /// to whatever is underneath them.
    private func nearestGuest(to scenePoint: CGPoint) -> UUID? {
        guard let state = controller?.state else { return nil }
        let world = worldNode.convert(scenePoint, from: self)
        let target = CGPoint(x: world.x / Self.tileSide, y: world.y / Self.tileSide)

        var best: UUID?
        var bestDistance = 0.75

        for guest in state.guests where guest.isActive {
            let distance = SimMath.distance(guest.position, target)
            if distance < bestDistance {
                bestDistance = distance
                best = guest.id
            }
        }
        return best
    }

    private func nearestStaff(to scenePoint: CGPoint) -> UUID? {
        guard let state = controller?.state else { return nil }
        let world = worldNode.convert(scenePoint, from: self)
        let target = CGPoint(x: world.x / Self.tileSide, y: world.y / Self.tileSide)

        var best: UUID?
        var bestDistance = 0.8

        for member in state.staff {
            let distance = SimMath.distance(member.position, target)
            if distance < bestDistance {
                bestDistance = distance
                best = member.id
            }
        }
        return best
    }

    private func clampCamera() {
        guard let state = controller?.state else { return }
        let width = CGFloat(state.map.width) * Self.tileSide
        let height = CGFloat(state.map.height) * Self.tileSide
        let margin = Self.tileSide * 6
        cameraNode.position.x = min(max(cameraNode.position.x, -margin), width + margin)
        cameraNode.position.y = min(max(cameraNode.position.y, -margin), height + margin)
    }

    // MARK: - Frame loop

    override func update(_ currentTime: TimeInterval) {
        guard let controller else { return }

        let delta: TimeInterval
        if lastFrameTime == 0 {
            delta = 0
        } else {
            delta = min(currentTime - lastFrameTime, 0.25)
        }
        lastFrameTime = currentTime

        controller.advance(realDelta: delta)

        if isInteractive { updateGestureModes() }
        syncTiles(state: controller.state)
        syncLitter(state: controller.state)
        syncScenery(state: controller.state)
        syncBuildings(state: controller.state)
        syncEntranceSign(state: controller.state)
        syncGuests(state: controller.state)
        syncStaff(state: controller.state)
        if isInteractive {
            syncGhost(controller: controller)
            syncSelection(controller: controller)
        }
    }

    // MARK: - Tiles

    private func syncTiles(state: GameState) {
        if tileNodes.isEmpty {
            buildTileNodes(state: state)
        }
        guard state.map.generation != renderedMapGeneration else { return }
        renderedMapGeneration = state.map.generation

        for index in 0..<state.map.tileCount {
            let coord = state.map.coord(atLinearIndex: index)
            guard let tile = state.map.tile(at: coord) else { continue }
            tileNodes[index].texture = SpriteFactory.tileTexture(colour: colour(for: tile, at: coord),
                                                                 side: Self.tileSide)
        }
    }

    private func buildTileNodes(state: GameState) {
        tileNodes.reserveCapacity(state.map.tileCount)
        for index in 0..<state.map.tileCount {
            let coord = state.map.coord(atLinearIndex: index)
            let node = SKSpriteNode(texture: SpriteFactory.tileTexture(
                colour: colour(for: state.map.tile(at: coord) ?? Tile(), at: coord),
                side: Self.tileSide))
            node.size = CGSize(width: Self.tileSide, height: Self.tileSide)
            node.position = CGPoint(x: (CGFloat(coord.x) + 0.5) * Self.tileSide,
                                    y: (CGFloat(coord.y) + 0.5) * Self.tileSide)
            tileLayer.addChild(node)
            tileNodes.append(node)
        }
    }

    private func colour(for tile: Tile, at coord: GridCoord) -> UIColor {
        ParkPalette.colour(for: tile.terrain, alternate: (coord.x + coord.y) % 2 != 0)
    }

    // MARK: - Buildings

    private func syncBuildings(state: GameState) {
        var seen = Set<UUID>()

        for attraction in state.attractions {
            seen.insert(attraction.id)
            let node = buildingNode(for: attraction.id,
                                    size: attraction.size,
                                    origin: attraction.origin,
                                    appearance: attraction.definition?.appearance ?? .unknown,
                                    title: attraction.name)
            node.setMotionRunning(attraction.isOperational)
            if attraction.isBroken {
                node.setBadge("!", colour: ParkPalette.broken)
            } else {
                node.setBadge(attraction.queue.isEmpty ? nil : "\(attraction.queue.count)")
            }
            node.setDimmed(!attraction.isOperational)
        }

        for facility in state.facilities {
            seen.insert(facility.id)
            let node = buildingNode(for: facility.id,
                                    size: facility.size,
                                    origin: facility.origin,
                                    appearance: facility.definition?.appearance ?? .unknown,
                                    title: facility.name)
            if facility.isUnusable {
                node.setBadge("!", colour: ParkPalette.broken)
            } else {
                node.setBadge(facility.queue.isEmpty ? nil : "\(facility.queue.count)")
            }
            node.setDimmed(!facility.isOpen || facility.isUnusable)
        }

        for (id, node) in buildingNodes where !seen.contains(id) {
            node.removeFromParent()
            buildingNodes.removeValue(forKey: id)
        }
    }

    /// Scenery never changes once placed, so this only ever adds nodes for new
    /// items and removes nodes for demolished ones.
    private func syncScenery(state: GameState) {
        var seen = Set<UUID>()

        for item in state.scenery {
            seen.insert(item.id)
            guard sceneryNodes[item.id] == nil else { continue }

            let appearance = item.definition?.appearance ?? .unknown
            let pixelSize = CGSize(width: CGFloat(item.size.width) * Self.tileSide,
                                   height: CGFloat(item.size.height) * Self.tileSide)
            let node = BuildingNode(
                texture: BuildingArtwork.bodyTexture(for: appearance, size: pixelSize),
                size: pixelSize,
                title: nil)
            node.position = CGPoint(
                x: (CGFloat(item.origin.x) + CGFloat(item.size.width) / 2) * Self.tileSide,
                y: (CGFloat(item.origin.y) + CGFloat(item.size.height) / 2) * Self.tileSide)
            node.configureMotion(appearance: appearance, buildingSize: pixelSize)
            sceneryLayer.addChild(node)
            sceneryNodes[item.id] = node
        }

        for (id, node) in sceneryNodes where !seen.contains(id) {
            node.removeFromParent()
            sceneryNodes.removeValue(forKey: id)
        }
    }

    private func buildingNode(for id: UUID,
                              size: GridSize,
                              origin: GridCoord,
                              appearance: BuildingAppearance,
                              title: String) -> BuildingNode {
        if let existing = buildingNodes[id] {
            existing.setTitle(title)
            return existing
        }

        let pixelSize = CGSize(width: CGFloat(size.width) * Self.tileSide,
                               height: CGFloat(size.height) * Self.tileSide)
        let node = BuildingNode(texture: BuildingArtwork.bodyTexture(for: appearance, size: pixelSize),
                                size: pixelSize,
                                title: title)
        node.configureMotion(appearance: appearance, buildingSize: pixelSize)
        node.position = CGPoint(x: (CGFloat(origin.x) + CGFloat(size.width) / 2) * Self.tileSide,
                                y: (CGFloat(origin.y) + CGFloat(size.height) / 2) * Self.tileSide)
        buildingLayer.addChild(node)
        buildingNodes[id] = node
        return node
    }

    // MARK: - Guests

    private func syncGuests(state: GameState) {
        let height = Self.tileSide * 0.58
        let guestSize = CGSize(width: height * GuestArtwork.aspect, height: height)
        let now = state.clock.simTime

        var seen = Set<UUID>()

        for guest in state.guests where guest.isActive {
            seen.insert(guest.id)
            let mood = GuestMood(happiness: guest.happiness)

            let node: SKSpriteNode
            if let existing = guestNodes[guest.id] {
                node = existing
            } else {
                node = SKSpriteNode(texture: GuestArtwork.texture(for: guest.appearance,
                                                                  age: guest.ageCategory,
                                                                  mood: mood,
                                                                  height: height))
                node.size = guestSize
                guestLayer.addChild(node)
                guestNodes[guest.id] = node
                guestMood[guest.id] = mood
            }

            // Guests inside a ride or a building are not drawn.
            if case .engaged = guest.activity {
                node.isHidden = true
                continue
            }
            node.isHidden = false

            if guestMood[guest.id] != mood {
                guestMood[guest.id] = mood
                node.texture = GuestArtwork.texture(for: guest.appearance,
                                                    age: guest.ageCategory,
                                                    mood: mood,
                                                    height: height)
            }

            var offset = CGPoint.zero
            if case .queueing = guest.activity {
                let slot = guest.queueSlot
                offset = CGPoint(x: CGFloat(slot % 3 - 1) * 0.24,
                                 y: CGFloat(slot / 3) * -0.22)
            }

            node.position = CGPoint(x: (guest.position.x + offset.x) * Self.tileSide,
                                    y: (guest.position.y + offset.y) * Self.tileSide)

            showBubbleIfNeeded(for: guest, on: node, now: now)
        }

        for (id, node) in guestNodes where !seen.contains(id) {
            node.removeFromParent()
            guestNodes.removeValue(forKey: id)
            guestMood.removeValue(forKey: id)
            shownThought.removeValue(forKey: id)
        }
    }

    /// Pops a bubble over a guest who has just thought something new.
    ///
    /// Only fresh thoughts qualify, so loading a save does not fire a bubble
    /// over every guest at once, and only a handful are ever on screen
    /// together: a park where everybody is thinking out loud reads as noise.
    private func showBubbleIfNeeded(for guest: Guest, on node: SKSpriteNode, now: Double) {
        guard let thought = guest.thoughts.last else { return }
        guard shownThought[guest.id] != thought.id else { return }
        shownThought[guest.id] = thought.id

        bubbleNodes.removeAll { $0.parent == nil }
        guard now - thought.simTime < 2.5, bubbleNodes.count < Self.maxBubbles else { return }

        let side = Self.tileSide * 0.62
        let bubble = SKSpriteNode(texture: GuestArtwork.bubbleTexture(icon: thought.icon,
                                                                     mood: thought.mood,
                                                                     side: side))
        bubble.size = CGSize(width: side, height: side)
        bubble.position = CGPoint(x: side * 0.34, y: node.size.height * 0.55 + side * 0.42)
        bubble.zPosition = 6
        bubble.setScale(0.25)
        bubble.alpha = 0
        node.addChild(bubble)
        bubbleNodes.append(bubble)

        let pop = SKAction.scale(to: 1.0, duration: 0.18)
        pop.timingMode = .easeOut
        let appear = SKAction.group([pop, .fadeIn(withDuration: 0.14)])
        let leave = SKAction.group([.fadeOut(withDuration: 0.35),
                                    .moveBy(x: 0, y: side * 0.30, duration: 0.35)])
        bubble.run(.sequence([appear,
                              .wait(forDuration: 2.4),
                              leave,
                              .removeFromParent()]))
    }

    // MARK: - Litter

    private func syncLitter(state: GameState) {
        guard state.map.litterGeneration != renderedLitterGeneration else { return }
        renderedLitterGeneration = state.map.litterGeneration

        let side = Self.tileSide
        var seen = Set<GridCoord>()

        for coord in state.map.litteredTiles {
            seen.insert(coord)
            let intensity = min(2, Int(state.map.litter(at: coord) / 34))

            let node: SKSpriteNode
            if let existing = litterNodes[coord] {
                node = existing
            } else {
                node = SKSpriteNode()
                node.size = CGSize(width: side, height: side)
                node.position = CGPoint(x: (CGFloat(coord.x) + 0.5) * side,
                                        y: (CGFloat(coord.y) + 0.5) * side)
                node.zPosition = 1
                tileLayer.addChild(node)
                litterNodes[coord] = node
                litterIntensity[coord] = -1
            }

            if litterIntensity[coord] != intensity {
                litterIntensity[coord] = intensity
                node.texture = SpriteFactory.litterTexture(intensity: intensity, side: side)
            }
        }

        for (coord, node) in litterNodes where !seen.contains(coord) {
            node.removeFromParent()
            litterNodes.removeValue(forKey: coord)
            litterIntensity.removeValue(forKey: coord)
        }
    }

    // MARK: - Staff

    private func syncStaff(state: GameState) {
        let height = Self.tileSide * 0.66
        let staffSize = CGSize(width: height * StaffArtwork.aspect, height: height)

        // Changing the uniform changes every employee at once, so the cached
        // textures and the sprites using them are both thrown away and rebuilt
        // by the loop below. Cheaper to write than to re-pair each node with
        // its role, and it happens only when the player picks a new colour.
        if renderedUniform != state.uniformColour {
            renderedUniform = state.uniformColour
            staffTextures.removeAll()
            for node in staffNodes.values { node.removeFromParent() }
            staffNodes.removeAll()
        }

        var seen = Set<UUID>()

        for member in state.staff {
            seen.insert(member.id)

            let node: SKSpriteNode
            if let existing = staffNodes[member.id] {
                node = existing
            } else {
                node = SKSpriteNode(texture: staffTexture(for: member.role,
                                                          uniform: state.uniformColour,
                                                          height: height))
                node.size = staffSize
                node.zPosition = 2
                guestLayer.addChild(node)
                staffNodes[member.id] = node
            }

            node.position = CGPoint(x: member.position.x * Self.tileSide,
                                    y: member.position.y * Self.tileSide)
        }

        for (id, node) in staffNodes where !seen.contains(id) {
            node.removeFromParent()
            staffNodes.removeValue(forKey: id)
        }
    }

    private func staffTexture(for role: StaffRole,
                              uniform: ParkColour,
                              height: CGFloat) -> SKTexture {
        if let cached = staffTextures[role] { return cached }
        let texture = StaffArtwork.texture(for: role, uniform: uniform, height: height)
        staffTextures[role] = texture
        return texture
    }

    // MARK: - Entrance sign

    /// A board on two posts standing outside the gate with the park's name on
    /// it, facing the way an arriving guest would be walking in from.
    private func syncEntranceSign(state: GameState) {
        let width = Self.tileSide * 5.4
        let height = Self.tileSide * 1.5

        let board: SKSpriteNode
        if let existing = entranceSign {
            board = existing
        } else {
            board = SKSpriteNode(texture: SpriteFactory.entranceSignTexture(
                size: CGSize(width: width, height: height)))
            board.size = CGSize(width: width, height: height)
            board.zPosition = 1

            let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
            label.fontColor = ParkPalette.signText
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            // Sits on the board face, which is the upper part of the artwork;
            // the lower part is the posts.
            label.position = CGPoint(x: 0, y: height * 0.13)
            label.zPosition = 1
            board.addChild(label)
            entranceSignLabel = label

            buildingLayer.addChild(board)
            entranceSign = board
        }

        let entrance = state.map.entranceCoord
        board.position = CGPoint(x: (CGFloat(entrance.x) + 0.5) * Self.tileSide,
                                 y: (CGFloat(entrance.y) - 0.85) * Self.tileSide)

        guard renderedParkName != state.parkName else { return }
        renderedParkName = state.parkName
        entranceSignLabel?.text = state.parkName
        // Long names shrink rather than overflow the board.
        let face = width * 0.86
        entranceSignLabel?.fontSize = min(height * 0.40,
                                          face * 1.5 / CGFloat(max(1, state.parkName.count)))
    }

    // MARK: - Build preview

    private func syncGhost(controller: GameController) {
        guard controller.build.isActive,
              let coord = controller.build.ghost else {
            ghostNode?.isHidden = true
            return
        }

        let size = controller.build.isDemolishing
            ? GridSize.single
            : (controller.selectedDefinition?.footprint ?? .single)

        let pixelSize = CGSize(width: CGFloat(size.width) * Self.tileSide,
                               height: CGFloat(size.height) * Self.tileSide)
        let colour = controller.build.ghostValid ? ParkPalette.ghostValid : ParkPalette.ghostInvalid

        let node: SKSpriteNode
        if let existing = ghostNode {
            node = existing
        } else {
            node = SKSpriteNode()
            node.zPosition = 5
            overlayLayer.addChild(node)
            ghostNode = node
        }

        node.isHidden = false
        node.texture = SpriteFactory.buildingTexture(colour: colour, size: pixelSize)
        node.size = pixelSize
        node.position = CGPoint(x: (CGFloat(coord.x) + CGFloat(size.width) / 2) * Self.tileSide,
                                y: (CGFloat(coord.y) + CGFloat(size.height) / 2) * Self.tileSide)
    }

    // MARK: - Selection highlight

    private func syncSelection(controller: GameController) {
        guard let selection = controller.selection else {
            selectionNode?.isHidden = true
            return
        }

        var centre: CGPoint?
        var size = CGSize(width: Self.tileSide, height: Self.tileSide)

        switch selection {
        case .guest(let detail):
            if let guest = controller.state.guest(id: detail.id) {
                centre = CGPoint(x: guest.position.x * Self.tileSide, y: guest.position.y * Self.tileSide)
                size = CGSize(width: Self.tileSide * 0.7, height: Self.tileSide * 0.7)
            }
        case .attraction(let detail):
            if let attraction = controller.state.attraction(id: detail.id) {
                centre = rectCentre(origin: attraction.origin, size: attraction.size)
                size = pixelSize(for: attraction.size)
            }
        case .facility(let detail):
            if let facility = controller.state.facility(id: detail.id) {
                centre = rectCentre(origin: facility.origin, size: facility.size)
                size = pixelSize(for: facility.size)
            }
        case .staff(let detail):
            if let member = controller.state.staffMember(id: detail.id) {
                centre = CGPoint(x: member.position.x * Self.tileSide,
                                 y: member.position.y * Self.tileSide)
                size = CGSize(width: Self.tileSide * 0.8, height: Self.tileSide * 0.8)
            }
        }

        guard let centre else {
            selectionNode?.isHidden = true
            return
        }

        let node: SKSpriteNode
        if let existing = selectionNode {
            node = existing
        } else {
            node = SKSpriteNode()
            node.zPosition = 25
            overlayLayer.addChild(node)
            selectionNode = node
        }

        node.isHidden = false
        node.texture = SpriteFactory.outlineTexture(colour: ParkPalette.selection, size: size)
        node.size = size
        node.position = centre
    }

    private func rectCentre(origin: GridCoord, size: GridSize) -> CGPoint {
        CGPoint(x: (CGFloat(origin.x) + CGFloat(size.width) / 2) * Self.tileSide,
                y: (CGFloat(origin.y) + CGFloat(size.height) / 2) * Self.tileSide)
    }

    private func pixelSize(for size: GridSize) -> CGSize {
        CGSize(width: CGFloat(size.width) * Self.tileSide,
               height: CGFloat(size.height) * Self.tileSide)
    }
}
