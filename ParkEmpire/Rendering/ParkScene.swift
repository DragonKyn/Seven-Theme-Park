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
    /// Drawn height of a guest and of an employee, in points at 1:1 zoom.
    /// Shared so the selection marker can be sized to the figure it is
    /// drawn around rather than guessing at it.
    private static let guestHeight = tileSide * 0.58
    private static let staffHeight = tileSide * 0.66

    private let worldNode = SKNode()
    private let tileLayer = SKNode()
    private let sceneryLayer = SKNode()
    private let trainLayer = SKNode()
    private let buildingLayer = SKNode()
    private let guestLayer = SKNode()
    private let overlayLayer = SKNode()

    private var tileNodes: [SKSpriteNode] = []
    /// How each tile currently looks, so unchanged tiles are skipped.
    private var tileAppearance: [Int] = []
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
    private var carPark: SKSpriteNode?
    private var renderedCarParkLevel = -1
    private var entranceSign: SKSpriteNode?
    private var entranceSignLabel: SKLabelNode?
    private var renderedParkName: String?
    private var litterNodes: [GridCoord: SKSpriteNode] = [:]
    private var litterIntensity: [GridCoord: Int] = [:]
    private var renderedLitterGeneration = -1
    private var trainNodes: [SKSpriteNode] = []
    private var renderedTrackGeneration = -1
    private var labelsVisible = true
    /// Camera scale beyond which building names are hidden. Bigger numbers are
    /// further out, because the camera scales the world down as it zooms out.
    private static let labelCutoffScale: CGFloat = 1.35
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
            worldNode.addChild(trainLayer)
            worldNode.addChild(buildingLayer)
            worldNode.addChild(overlayLayer)
            worldNode.addChild(guestLayer)
            addChild(worldNode)
        }

        tileLayer.zPosition = 0
        sceneryLayer.zPosition = 5
        // Between the scenery and the buildings, so a train passes behind a
        // station canopy the way it would in life.
        trainLayer.zPosition = 7
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
        let person = controller.build.isActive ? nil : nearestPerson(to: scenePoint)

        var guestID: UUID?
        var staffID: UUID?
        switch person {
        case .guest(let id): guestID = id
        case .staff(let id): staffID = id
        case nil: break
        }

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

    private enum TappedPerson {
        case guest(UUID)
        case staff(UUID)
    }

    /// Whoever the tap actually landed nearest to, guest or employee.
    ///
    /// Both are checked against one another rather than guests first. Staff
    /// walk the same paths as guests, so an employee nearly always has a guest
    /// within the touch radius as well, and checking guests first meant
    /// tapping an employee opened a visitor's inspector instead.
    ///
    /// People are small; the radius is generous, and a tap that finds nobody
    /// falls through to whatever is underneath them.
    private func nearestPerson(to scenePoint: CGPoint) -> TappedPerson? {
        guard let state = controller?.state else { return nil }
        let world = worldNode.convert(scenePoint, from: self)
        let target = CGPoint(x: world.x / Self.tileSide, y: world.y / Self.tileSide)

        var best: TappedPerson?
        var bestDistance = 0.8

        for guest in state.guests where guest.isActive {
            // A guest inside a ride is not drawn, so it cannot be tapped.
            if case .engaged = guest.activity { continue }
            let distance = SimMath.distance(guest.position, target)
            if distance < bestDistance {
                bestDistance = distance
                best = .guest(guest.id)
            }
        }

        for member in state.staff {
            let distance = SimMath.distance(member.position, target)
            if distance < bestDistance {
                bestDistance = distance
                best = .staff(member.id)
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
        syncTrains(state: controller.state)
        syncBuildings(state: controller.state)
        updateLabelVisibility()
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

        // A sixty-tile-square park is three and a half thousand sprites, and
        // painting one path tile bumps the generation for all of them. Each
        // tile keeps a small code for how it currently looks, so the common
        // case is an integer comparison rather than building a texture key.
        for index in 0..<state.map.tileCount {
            let coord = state.map.coord(atLinearIndex: index)
            guard let tile = state.map.tile(at: coord) else { continue }
            let code = appearanceCode(for: tile, at: coord, map: state.map)
            guard tileAppearance[index] != code else { continue }
            tileAppearance[index] = code
            tileNodes[index].texture = texture(for: tile, at: coord, map: state.map)
        }
    }

    /// A cheap number standing for everything that decides how a tile is
    /// drawn: its terrain, which square of the grass check it is on, and for
    /// railway, which neighbours it joins.
    private func appearanceCode(for tile: Tile, at coord: GridCoord, map: ParkMap) -> Int {
        let terrain: Int
        switch tile.terrain {
        case .grass: terrain = 0
        case .path: terrain = 1
        case .entrance: terrain = 2
        case .water: terrain = 3
        case .track: terrain = 4
        }
        let alternate = (coord.x + coord.y) % 2 != 0 ? 1 : 0
        return terrain * 100 + alternate * 50 + trackConnections(at: coord, map: map)
    }

    private func buildTileNodes(state: GameState) {
        tileNodes.reserveCapacity(state.map.tileCount)
        tileAppearance = Array(repeating: -1, count: state.map.tileCount)
        for index in 0..<state.map.tileCount {
            let coord = state.map.coord(atLinearIndex: index)
            tileAppearance[index] = appearanceCode(for: state.map.tile(at: coord) ?? Tile(),
                                                   at: coord,
                                                   map: state.map)
            let node = SKSpriteNode(texture: texture(for: state.map.tile(at: coord) ?? Tile(),
                                                     at: coord,
                                                     map: state.map))
            node.size = CGSize(width: Self.tileSide, height: Self.tileSide)
            node.position = CGPoint(x: (CGFloat(coord.x) + 0.5) * Self.tileSide,
                                    y: (CGFloat(coord.y) + 0.5) * Self.tileSide)
            tileLayer.addChild(node)
            tileNodes.append(node)
        }
    }

    /// Railway is drawn from what it joins on to, so a straight run reads as
    /// a straight run. Everything else is a flat colour.
    private func texture(for tile: Tile, at coord: GridCoord, map: ParkMap) -> SKTexture {
        guard tile.terrain == .track else {
            return SpriteFactory.tileTexture(colour: colour(for: tile, at: coord),
                                             side: Self.tileSide)
        }

        return SpriteFactory.trackTileTexture(connections: trackConnections(at: coord, map: map),
                                              side: Self.tileSide)
    }

    /// Which of the four neighbours are also railway, as north, east, south
    /// and west bits. Zero for anything that is not railway itself.
    private func trackConnections(at coord: GridCoord, map: ParkMap) -> Int {
        guard map.tile(at: coord)?.terrain == .track else { return 0 }
        let offsets: [(Int, GridCoord)] = [
            (1, GridCoord(coord.x, coord.y + 1)),
            (2, GridCoord(coord.x + 1, coord.y)),
            (4, GridCoord(coord.x, coord.y - 1)),
            (8, GridCoord(coord.x - 1, coord.y))
        ]
        var connections = 0
        for (bit, neighbour) in offsets where map.tile(at: neighbour)?.terrain == .track {
            connections |= bit
        }
        return connections
    }

    private func colour(for tile: Tile, at coord: GridCoord) -> UIColor {
        ParkPalette.colour(for: tile.terrain, alternate: (coord.x + coord.y) % 2 != 0)
    }

    /// Names are dropped once the park is zoomed out far enough that they
    /// would be a wall of chips rather than information.
    private func updateLabelVisibility() {
        let visible = cameraNode.xScale <= Self.labelCutoffScale
        guard visible != labelsVisible else { return }
        labelsVisible = visible
        for node in buildingNodes.values { node.setLabelVisible(visible) }
    }

    // MARK: - Trains

    /// Runs a train round each length of track the player has laid.
    ///
    /// Rebuilt whenever the map changes rather than nudged: track is edited a
    /// tile at a time and a half-updated route would send a locomotive across
    /// the grass.
    private func syncTrains(state: GameState) {
        guard state.map.generation != renderedTrackGeneration else { return }
        renderedTrackGeneration = state.map.generation

        for node in trainNodes { node.removeFromParent() }
        trainNodes.removeAll()

        let network = state.trackNetwork
        let stations = state.attractions.filter { $0.definition?.kind == .transport }
        let carSize = CGSize(width: Self.tileSide * 0.86, height: Self.tileSide * 0.46)

        for (index, route) in network.routes.enumerated() where route.tiles.count > 2 {
            // A train only runs where there is something for it to do. Laying
            // a tile of track should not put a locomotive on the map.
            let served = stations.filter { network.routeIndex(touching: $0.rect) == index }
            guard served.count >= 2 else { continue }

            let points = route.tiles.map {
                CGPoint(x: (CGFloat($0.x) + 0.5) * Self.tileSide,
                        y: (CGFloat($0.y) + 0.5) * Self.tileSide)
            }
            // A tile a second or so, which reads as a park train rather than
            // as something anybody would ride for the speed.
            let isLoop = route.isLoop
            // A line is stored one way, and the train covers it twice a cycle,
            // so it needs twice as long to run at the same speed as a loop.
            let duration = Double(points.count) * (isLoop ? 0.85 : 1.7)

            // A locomotive and two carriages either way. On a loop each car
            // starts a tile further back round the ring. On a dead-ended line
            // the train shuttles: every car keeps the same distance back along
            // the rails and the whole thing reverses at the end, which is what
            // a real terminus looks like.
            let cars = 3
            let spacing = Self.tileSide
            let consist = spacing * CGFloat(cars - 1)

            for carriage in 0..<cars {
                let carPath: [CGPoint]
                if isLoop {
                    let offset = (points.count - carriage) % points.count
                    carPath = Array(points[offset...] + points[..<offset])
                } else {
                    carPath = PathMotion.shuttlePoints(along: points,
                                                     carIndex: carriage,
                                                     carSpacing: spacing,
                                                     consistLength: consist,
                                                     samples: max(48, points.count * 3))
                }

                let node = SKSpriteNode(texture: SpriteFactory.trainCarTexture(
                    isLocomotive: carriage == 0, size: carSize))
                node.size = carSize
                trainLayer.addChild(node)
                PathMotion.drive(node, around: carPath, duration: duration)
                trainNodes.append(node)
            }
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
                                    rotation: attraction.rotation,
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
                                    rotation: facility.rotation,
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
            let drawnSize = item.size.rotated(by: item.rotation)
            let pixelSize = CGSize(width: CGFloat(drawnSize.width) * Self.tileSide,
                                   height: CGFloat(drawnSize.height) * Self.tileSide)
            let node = BuildingNode(
                texture: BuildingArtwork.bodyTexture(for: appearance, size: pixelSize),
                size: pixelSize,
                title: nil)
            node.setRotation(quarterTurns: item.rotation)
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
                              rotation: Int,
                              appearance: BuildingAppearance,
                              title: String) -> BuildingNode {
        if let existing = buildingNodes[id] {
            existing.setTitle(title)
            return existing
        }

        // `size` is the ground the building takes up, already turned. The
        // artwork is drawn the way round it was designed and then rotated, so
        // a turned building is not a squashed one.
        let drawnSize = size.rotated(by: rotation)
        let pixelSize = CGSize(width: CGFloat(drawnSize.width) * Self.tileSide,
                               height: CGFloat(drawnSize.height) * Self.tileSide)
        let node = BuildingNode(texture: BuildingArtwork.bodyTexture(for: appearance, size: pixelSize),
                                size: pixelSize,
                                title: title)
        node.configureMotion(appearance: appearance, buildingSize: pixelSize)
        node.setRotation(quarterTurns: rotation)
        node.position = CGPoint(x: (CGFloat(origin.x) + CGFloat(size.width) / 2) * Self.tileSide,
                                y: (CGFloat(origin.y) + CGFloat(size.height) / 2) * Self.tileSide)
        buildingLayer.addChild(node)
        buildingNodes[id] = node
        return node
    }

    // MARK: - Guests

    /// Where a guest's sprite actually sits, which is not always the middle
    /// of their tile: guests in a queue are fanned out into slots so a line
    /// of them is countable. The selection marker reads this too, so the box
    /// lands on the figure rather than beside it.
    private func drawPosition(of guest: Guest) -> CGPoint {
        var offset = CGPoint.zero
        if case .queueing = guest.activity {
            let slot = guest.queueSlot
            offset = CGPoint(x: CGFloat(slot % 3 - 1) * 0.24,
                             y: CGFloat(slot / 3) * -0.22)
        }
        return CGPoint(x: (guest.position.x + offset.x) * Self.tileSide,
                       y: (guest.position.y + offset.y) * Self.tileSide)
    }

    private func syncGuests(state: GameState) {
        let height = Self.guestHeight
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

            node.position = drawPosition(of: guest)

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
        let height = Self.staffHeight
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
        syncCarPark(entrance: entrance, level: state.carParkLevel)

        guard renderedParkName != state.parkName else { return }
        renderedParkName = state.parkName
        entranceSignLabel?.text = state.parkName
        // Long names shrink rather than overflow the board.
        let face = width * 0.86
        entranceSignLabel?.fontSize = min(height * 0.40,
                                          face * 1.5 / CGFloat(max(1, state.parkName.count)))
    }

    /// The car park outside the gate. Drawn once and never touched again: it
    /// is scenery in the plainest sense, with nothing to simulate and nothing
    /// to select.
    private func syncCarPark(entrance: GridCoord, level: Int) {
        let size = CGSize(width: Self.tileSide * 13, height: Self.tileSide * 4.4)

        let node: SKSpriteNode
        if let existing = carPark {
            node = existing
            if renderedCarParkLevel != level {
                renderedCarParkLevel = level
                node.texture = SpriteFactory.carParkTexture(level: level, size: size)
            }
        } else {
            renderedCarParkLevel = level
            node = SKSpriteNode(texture: SpriteFactory.carParkTexture(level: level, size: size))
            node.size = size
            // Below the tiles, so nothing in the park can be confused for it.
            node.zPosition = -1
            worldNode.addChild(node)
            carPark = node
        }

        node.position = CGPoint(x: (CGFloat(entrance.x) + 0.5) * Self.tileSide,
                                y: (CGFloat(entrance.y) - 4.1) * Self.tileSide)
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
            : controller.ghostFootprint

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
            // A guest on a ride is not drawn, so the marker goes with them
            // rather than hanging over the spot they left. The selection
            // itself is untouched: their panel stays open throughout.
            if let guest = controller.state.guest(id: detail.id), !isInside(guest) {
                centre = drawPosition(of: guest)
                size = markerSize(around: Self.guestHeight, aspect: GuestArtwork.aspect)
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
                size = markerSize(around: Self.staffHeight, aspect: StaffArtwork.aspect)
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

    /// True while a guest is inside a ride or a building, where they are not
    /// drawn.
    private func isInside(_ guest: Guest) -> Bool {
        if case .engaged = guest.activity { return true }
        return false
    }

    /// A box drawn a little outside the figure it marks, rather than a square
    /// the size of a tile, so it reads as being around that person.
    private func markerSize(around height: CGFloat, aspect: CGFloat) -> CGSize {
        let margin = Self.tileSide * 0.16
        return CGSize(width: height * aspect + margin, height: height + margin)
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
