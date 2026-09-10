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

    /// Points per tile at 1:1 zoom.
    static let tileSide: CGFloat = 32

    private let worldNode = SKNode()
    private let tileLayer = SKNode()
    private let buildingLayer = SKNode()
    private let guestLayer = SKNode()
    private let overlayLayer = SKNode()

    private var tileNodes: [SKSpriteNode] = []
    private var buildingNodes: [UUID: BuildingNode] = [:]
    private var guestNodes: [UUID: SKSpriteNode] = [:]
    /// Which of the three mood textures each guest sprite is currently showing,
    /// so the texture is only swapped when the mood actually changes.
    private var guestMoodIndex: [UUID: Int] = [:]
    private var guestTextures: [SKTexture] = []
    private var staffNodes: [UUID: SKSpriteNode] = [:]
    private var staffTextures: [StaffRole: SKTexture] = [:]
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
            worldNode.addChild(buildingLayer)
            worldNode.addChild(overlayLayer)
            worldNode.addChild(guestLayer)
            addChild(worldNode)
        }

        tileLayer.zPosition = 0
        buildingLayer.zPosition = 10
        overlayLayer.zPosition = 20
        guestLayer.zPosition = 30

        if cameraNode.parent == nil {
            addChild(cameraNode)
        }
        camera = cameraNode
        cameraNode.setScale(1.0)
        centreCameraOnEntrance()

        installGestures(on: view)
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

        updateGestureModes()
        syncTiles(state: controller.state)
        syncLitter(state: controller.state)
        syncBuildings(state: controller.state)
        syncGuests(state: controller.state)
        syncStaff(state: controller.state)
        syncGhost(controller: controller)
        syncSelection(controller: controller)
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
        switch tile.terrain {
        case .path: return ParkPalette.path
        case .entrance: return ParkPalette.entrance
        case .grass: return (coord.x + coord.y) % 2 == 0 ? ParkPalette.grass : ParkPalette.grassAlt
        }
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
        let diameter = Self.tileSide * 0.42
        if guestTextures.isEmpty {
            guestTextures = [
                SpriteFactory.circleTexture(colour: ParkPalette.guestUnhappy, diameter: diameter),
                SpriteFactory.circleTexture(colour: ParkPalette.guestNeutral, diameter: diameter),
                SpriteFactory.circleTexture(colour: ParkPalette.guestHappy, diameter: diameter)
            ]
        }

        var seen = Set<UUID>()

        for guest in state.guests where guest.isActive {
            seen.insert(guest.id)
            let mood = moodIndex(for: guest.happiness)

            let node: SKSpriteNode
            if let existing = guestNodes[guest.id] {
                node = existing
            } else {
                node = SKSpriteNode(texture: guestTextures[mood])
                node.size = CGSize(width: diameter, height: diameter)
                guestLayer.addChild(node)
                guestNodes[guest.id] = node
                guestMoodIndex[guest.id] = mood
            }

            // Guests inside a ride or a building are not drawn.
            if case .engaged = guest.activity {
                node.isHidden = true
                continue
            }
            node.isHidden = false

            if guestMoodIndex[guest.id] != mood {
                guestMoodIndex[guest.id] = mood
                node.texture = guestTextures[mood]
            }

            var offset = CGPoint.zero
            if case .queueing = guest.activity {
                let slot = guest.queueSlot
                offset = CGPoint(x: CGFloat(slot % 3 - 1) * 0.24,
                                 y: CGFloat(slot / 3) * -0.22)
            }

            node.position = CGPoint(x: (guest.position.x + offset.x) * Self.tileSide,
                                    y: (guest.position.y + offset.y) * Self.tileSide)
        }

        for (id, node) in guestNodes where !seen.contains(id) {
            node.removeFromParent()
            guestNodes.removeValue(forKey: id)
            guestMoodIndex.removeValue(forKey: id)
        }
    }

    private func moodIndex(for happiness: Double) -> Int {
        switch happiness {
        case ..<40: return 0
        case ..<70: return 1
        default: return 2
        }
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
        let diameter = Self.tileSide * 0.5
        var seen = Set<UUID>()

        for member in state.staff {
            seen.insert(member.id)

            let node: SKSpriteNode
            if let existing = staffNodes[member.id] {
                node = existing
            } else {
                node = SKSpriteNode(texture: staffTexture(for: member.role, diameter: diameter))
                node.size = CGSize(width: diameter, height: diameter)
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

    private func staffTexture(for role: StaffRole, diameter: CGFloat) -> SKTexture {
        if let cached = staffTextures[role] { return cached }
        let texture = SpriteFactory.circleTexture(colour: ParkPalette.colour(for: role),
                                                  diameter: diameter)
        staffTextures[role] = texture
        return texture
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
