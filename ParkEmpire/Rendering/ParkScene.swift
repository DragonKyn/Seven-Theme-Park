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
    /// What each building is currently painted as, so one that has been
    /// repainted is rebuilt and one that has not is left alone.
    private var renderedAppearance: [UUID: BuildingAppearance] = [:]
    private var sceneryNodes: [UUID: BuildingNode] = [:]
    private var elementNodes: [UUID: SKSpriteNode] = [:]
    private var guestNodes: [UUID: SKSpriteNode] = [:]
    /// Which mood each guest sprite is currently drawn with, so the texture is
    /// only swapped when the mood actually changes.
    private var guestMood: [UUID: GuestMood] = [:]
    /// What each guest is currently drawn carrying, for the same reason: a
    /// prize won at a booth has to change the sprite, and nothing else does.
    private var guestPrize: [UUID: GuestPrize] = [:]
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
    /// The colours the park's furniture is currently painted in.
    private var renderedScheme: ParkScheme?
    private var carPark: SKSpriteNode?
    private var renderedCarParkLevel = -1
    private var entranceSign: SKSpriteNode?
    private var entranceSignLabel: SKLabelNode?
    private var renderedParkName: String?
    private var litterNodes: [GridCoord: SKSpriteNode] = [:]
    private var litterIntensity: [GridCoord: Int] = [:]
    private var renderedLitterGeneration = -1
    private var trainNodes: [SKSpriteNode] = []
    /// Coaster cars, remembered along with the ride they belong to, so a
    /// change of colour or car type can be painted onto the train that is
    /// already running instead of building a new one.
    private var coasterCars: [CoasterCar] = []
    /// The colour and car type each coaster's train is currently drawn in.
    private var renderedLivery: [UUID: String] = [:]
    private var renderedTrackGeneration = -1
    /// The colour the coaster track and its elements are currently painted.
    private var renderedTrackColour: ParkColour?
    private var renderedElementColour: ParkColour?

    /// One car of a coaster train, and what it needs to be repainted.
    private struct CoasterCar {
        let node: SKSpriteNode
        let attraction: UUID
        let isLeading: Bool
        let size: CGSize
    }
    private var labelsVisible = true
    /// Camera scale beyond which building names are hidden. Bigger numbers are
    /// further out, because the camera scales the world down as it zooms out.
    private static let labelCutoffScale: CGFloat = 1.35
    private var ghostNode: SKSpriteNode?
    /// The building that is lined up but not yet paid for, and the frame
    /// round the ground it would occupy.
    private var previewNode: SKSpriteNode?
    private var previewOutline: SKSpriteNode?
    private var selectionNode: SKSpriteNode?

    private var renderedMapGeneration = -1
    private var lastFrameTime: TimeInterval = 0

    private let cameraNode = SKCameraNode()
    private var cameraPanStart: CGPoint = .zero
    private var pinchStartScale: CGFloat = 1

    private var cameraPan: UIPanGestureRecognizer?
    private var paintPan: UIPanGestureRecognizer?
    /// Where a drag of a waiting placement started, and where the placement
    /// was at the time.
    private var dragAnchor: GridCoord?
    private var dragOrigin: GridCoord?

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

    /// A one-finger drag moves the camera, so looking around the park can
    /// never place anything by accident. Two modes take that finger for
    /// themselves: drawing a walkway, and sliding a placement that is waiting
    /// to be confirmed. In both, two fingers still move the camera.
    private func updateGestureModes() {
        guard let controller else { return }
        let isPainting = controller.canDraw && controller.build.isDrawing
        let isPlacing = controller.build.pending != nil
        let takesOneFinger = isPainting || isPlacing

        guard takesOneFinger != paintPan?.isEnabled else { return }
        paintPan?.isEnabled = takesOneFinger
        cameraPan?.minimumNumberOfTouches = takesOneFinger ? 2 : 1
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

        // A placement waiting to be confirmed follows the finger instead.
        if controller.build.pending != nil {
            dragPending(to: coord, state: recognizer.state, controller: controller)
            return
        }

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

    /// Slides a waiting placement under the finger.
    ///
    /// Moved by how far the finger has travelled rather than to wherever it
    /// is, so the building keeps the same offset from the fingertip it had
    /// when the drag started. Dropping the corner on the finger makes a
    /// building jump the moment it is touched.
    private func dragPending(to coord: GridCoord,
                             state: UIGestureRecognizer.State,
                             controller: GameController) {
        switch state {
        case .began:
            dragAnchor = coord
            dragOrigin = controller.build.pending?.origin
        case .changed:
            guard let anchor = dragAnchor, let origin = dragOrigin else { return }
            controller.movePending(to: GridCoord(origin.x + coord.x - anchor.x,
                                                 origin.y + coord.y - anchor.y))
        default:
            dragAnchor = nil
            dragOrigin = nil
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
        repaintParkFurniture(state: controller.state)
        syncTiles(state: controller.state)
        syncLitter(state: controller.state)
        syncScenery(state: controller.state)
        syncTrackElements(state: controller.state)
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

    /// Drops every building and every piece of scenery when the park's
    /// colours change, so they are built again in the new ones.
    ///
    /// Heavy-handed on purpose: this runs when a player picks a colour and
    /// never otherwise, and a node that knows how to repaint itself is a node
    /// that has to remember what it was painted with.
    private func repaintParkFurniture(state: GameState) {
        guard renderedScheme != state.scheme else { return }
        renderedScheme = state.scheme

        for node in buildingNodes.values { node.removeFromParent() }
        buildingNodes.removeAll()
        renderedAppearance.removeAll()
        for node in sceneryNodes.values { node.removeFromParent() }
        sceneryNodes.removeAll()
    }

    // MARK: - Tiles

    private func syncTiles(state: GameState) {
        if tileNodes.isEmpty {
            buildTileNodes(state: state)
        }
        // Repainting the track is not a change to the map, so it has to force
        // its own pass. Every tile is re-examined, which is the same work one
        // path tile already costs and happens only when a colour is picked.
        if renderedTrackColour != state.coasterTrackColour {
            renderedTrackColour = state.coasterTrackColour
            for index in tileAppearance.indices { tileAppearance[index] = -1 }
            renderedMapGeneration = -1
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
            tileNodes[index].texture = texture(for: tile,
                                               at: coord,
                                               map: state.map,
                                               rail: state.coasterTrackColour)
        }
    }

    /// A cheap number standing for everything that decides how a tile is
    /// drawn: its terrain, which of the repeating variants it uses, and for
    /// track and water, which neighbours it joins or stops against.
    private func appearanceCode(for tile: Tile, at coord: GridCoord, map: ParkMap) -> Int {
        let terrain: Int
        switch tile.terrain {
        case .grass: terrain = 0
        case .path: terrain = 1
        case .entrance: terrain = 2
        case .water: terrain = 3
        case .track: terrain = 4
        case .coasterTrack: terrain = 5
        case .coasterLoop: terrain = 6
        case .coasterHill: terrain = 7
        case .coasterHelix: terrain = 8
        case .coasterJump: terrain = 9
        }
        return terrain * 1000 + tileVariant(at: coord) * 100 + neighbourMask(for: tile, at: coord, map: map)
    }

    /// Which repeat of a terrain a tile uses. Taken from the coordinate, so a
    /// field of grass is varied without anything being stored per tile.
    private func tileVariant(at coord: GridCoord) -> Int {
        ((coord.x &* 7) &+ (coord.y &* 13)) & 3
    }

    /// Track connections, or for water the sides where it stops.
    private func neighbourMask(for tile: Tile, at coord: GridCoord, map: ParkMap) -> Int {
        switch tile.terrain {
        case .water: return shoreMask(at: coord, map: map)
        default: return trackConnections(at: coord, map: map)
        }
    }

    /// Sides of a water tile that are not more water, as north, east, south
    /// and west bits.
    private func shoreMask(at coord: GridCoord, map: ParkMap) -> Int {
        let offsets: [(Int, GridCoord)] = [
            (1, GridCoord(coord.x, coord.y + 1)),
            (2, GridCoord(coord.x + 1, coord.y)),
            (4, GridCoord(coord.x, coord.y - 1)),
            (8, GridCoord(coord.x - 1, coord.y))
        ]
        var shores = 0
        for (bit, neighbour) in offsets where map.tile(at: neighbour)?.terrain != .water {
            shores |= bit
        }
        return shores
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
                                                     map: state.map,
                                                     rail: state.coasterTrackColour))
            node.size = CGSize(width: Self.tileSide, height: Self.tileSide)
            node.position = CGPoint(x: (CGFloat(coord.x) + 0.5) * Self.tileSide,
                                    y: (CGFloat(coord.y) + 0.5) * Self.tileSide)
            tileLayer.addChild(node)
            tileNodes.append(node)
        }
    }

    /// Which of the four neighbours are the same kind of track, as north,
    /// east, south and west bits. Zero for anything that is not track.
    private func trackConnections(at coord: GridCoord, map: ParkMap) -> Int {
        guard let terrain = map.tile(at: coord)?.terrain,
              terrain == .track || terrain.isCoasterTrack else { return 0 }
        let offsets: [(Int, GridCoord)] = [
            (1, GridCoord(coord.x, coord.y + 1)),
            (2, GridCoord(coord.x + 1, coord.y)),
            (4, GridCoord(coord.x, coord.y - 1)),
            (8, GridCoord(coord.x - 1, coord.y))
        ]
        var connections = 0
        // Every kind of coaster piece joins every other, so a loop bolted
        // between two straights reads as connected to both.
        for (bit, neighbour) in offsets {
            guard let other = map.tile(at: neighbour)?.terrain else { continue }
            let joins = terrain.isCoasterTrack ? other.isCoasterTrack : other == terrain
            guard joins else { continue }
            connections |= bit
        }
        return connections
    }

    /// Ground is drawn per tile rather than as a flat colour: grass has tufts
    /// on it, paving has joints, water has a shore, and track is drawn from
    /// what it joins on to.
    private func texture(for tile: Tile,
                         at coord: GridCoord,
                         map: ParkMap,
                         rail: ParkColour? = nil) -> SKTexture {
        let variant = tileVariant(at: coord)

        switch tile.terrain {
        case .grass:
            return SpriteFactory.grassTexture(variant: variant, side: Self.tileSide)
        case .path:
            return SpriteFactory.pathTexture(variant: variant, side: Self.tileSide)
        case .water:
            return SpriteFactory.waterTexture(shores: shoreMask(at: coord, map: map),
                                              variant: variant,
                                              side: Self.tileSide)
        case .entrance:
            return SpriteFactory.tileTexture(colour: ParkPalette.entrance, side: Self.tileSide)
        case .track, .coasterTrack, .coasterLoop, .coasterHill, .coasterHelix, .coasterJump:
            let connections = trackConnections(at: coord, map: map)
            return SpriteFactory.trackTileTexture(connections: connections,
                                                  side: Self.tileSide,
                                                  coaster: tile.terrain.isCoasterTrack,
                                                  rail: rail)
        }
    }

    /// Names are dropped once the park is zoomed out far enough that they
    /// would be a wall of chips rather than information.
    private func updateLabelVisibility() {
        let visible = cameraNode.xScale <= Self.labelCutoffScale
        guard visible != labelsVisible else { return }
        labelsVisible = visible
        for node in buildingNodes.values { node.setLabelVisible(visible) }
    }

    /// Loops, corkscrews and jumps sitting on the track. Like scenery, they
    /// never change once placed, so this only adds and removes.
    private func syncTrackElements(state: GameState) {
        let rail = state.coasterTrackColour
        var seen = Set<UUID>()

        for element in state.trackElements {
            seen.insert(element.id)
            guard let definition = element.definition else { continue }

            // Drawn the way round it was designed and then turned, so a
            // rotated loop is not a squashed one, and drawn taller than the
            // ground it covers so a loop has room to be a loop.
            let drawn = element.size.rotated(by: element.rotation)
            let pixelSize = CGSize(width: CGFloat(drawn.width) * Self.tileSide,
                                   height: CGFloat(definition.visualHeight) * Self.tileSide)
            // Built only when it is wanted: this runs every frame, and a
            // texture key is a string.
            func artwork() -> SKTexture {
                CoasterElementArtwork.texture(for: definition.motif,
                                              size: pixelSize,
                                              trackY: definition.trackLine,
                                              rail: rail)
            }

            if let existing = elementNodes[element.id] {
                // Already on the map. The only thing that can change under it
                // is the colour of the rails.
                if renderedElementColour != rail { existing.texture = artwork() }
                continue
            }

            let node = SKSpriteNode(texture: artwork())
            node.size = pixelSize
            node.zRotation = -CGFloat(((element.rotation % 4) + 4) % 4) * .pi / 2
            node.position = elementSpriteCentre(element, definition: definition)
            // Structure first, train on top of it. A loop drawn over the cars
            // hides the very thing it was bought to show off.
            node.zPosition = -1
            trainLayer.addChild(node)
            elementNodes[element.id] = node
        }

        renderedElementColour = rail

        for (id, node) in elementNodes where !seen.contains(id) {
            node.removeFromParent()
            elementNodes.removeValue(forKey: id)
        }
    }

    // MARK: - Trains

    /// Runs a train round each length of track the player has laid.
    ///
    /// Rebuilt whenever the map changes rather than nudged: track is edited a
    /// tile at a time and a half-updated route would send a locomotive across
    /// the grass.
    private func syncTrains(state: GameState) {
        repaintCoasters(state: state)

        guard state.map.generation != renderedTrackGeneration else { return }
        renderedTrackGeneration = state.map.generation

        for node in trainNodes { node.removeFromParent() }
        trainNodes.removeAll()
        coasterCars.removeAll()
        renderedLivery.removeAll()

        runTrains(on: state.trackNetwork,
                  servedBy: state.attractions.filter { $0.baseDefinition?.kind == .transport },
                  coaster: false,
                  elements: [])
        runTrains(on: state.coasterNetwork,
                  servedBy: state.attractions.filter { $0.baseDefinition?.kind == .custom },
                  coaster: true,
                  elements: state.trackElements)
    }

    /// Repaints coaster trains in place when the player picks a new colour or
    /// car type.
    ///
    /// Swapping a texture leaves the actions running, so the train keeps going
    /// round and simply changes colour underneath the player. Rebuilding it
    /// sent every car back to the station, which made choosing a colour feel
    /// like a punishment.
    private func repaintCoasters(state: GameState) {
        guard !coasterCars.isEmpty else { return }

        for attraction in state.attractions where attraction.baseDefinition?.kind == .custom {
            let key = "\(attraction.livery.rawValue)|\(attraction.carStyle.rawValue)"
            guard renderedLivery[attraction.id] != key else { continue }
            renderedLivery[attraction.id] = key

            for car in coasterCars where car.attraction == attraction.id {
                car.node.texture = SpriteFactory.coasterCarTexture(isLeading: car.isLeading,
                                                                   style: attraction.carStyle,
                                                                   colour: attraction.livery,
                                                                   size: car.size)
            }
        }
    }

    /// The line a train actually runs, with every element's own geometry
    /// spliced in where the route passes through one.
    ///
    /// Before this, an element was a picture painted over track the train drove
    /// straight through, which is why a loop felt like scenery. The element
    /// hands out the same points it draws itself with, so the train goes round
    /// the loop, over the jump and down the helix.
    private func ridePoints(for route: TrackNetwork.Route,
                            elements: [TrackElement]) -> [CGPoint] {
        guard !elements.isEmpty else { return route.tiles.map(tileCentre) }

        var points: [CGPoint] = []
        var index = 0

        while index < route.tiles.count {
            let tile = route.tiles[index]
            guard let element = elements.first(where: { $0.rect.contains(tile) }),
                  let definition = element.definition else {
                points.append(tileCentre(tile))
                index += 1
                continue
            }

            // However many of the next tiles belong to this same element.
            var span = 1
            while index + span < route.tiles.count,
                  element.rect.contains(route.tiles[index + span]) {
                span += 1
            }

            let path = worldPath(of: element, definition: definition)
            // The route may cross the element either way round.
            let entry = tileCentre(tile)
            let fromStart = hypot(path[0].x - entry.x, path[0].y - entry.y)
            let fromEnd = hypot(path[path.count - 1].x - entry.x,
                                path[path.count - 1].y - entry.y)
            points.append(contentsOf: fromStart <= fromEnd ? path : path.reversed())

            index += span
        }

        return points
    }

    /// An element's drawn centreline, in scene coordinates.
    ///
    /// The sprite is drawn at its visual size, turned, and pushed up out of its
    /// footprint; the points are put through exactly the same transform, which
    /// is what keeps the train on the rails that were drawn for it.
    private func worldPath(of element: TrackElement,
                           definition: CoasterElementDefinition) -> [CGPoint] {
        let drawn = element.size.rotated(by: element.rotation)
        let design = CGSize(width: CGFloat(drawn.width) * Self.tileSide,
                            height: CGFloat(definition.visualHeight) * Self.tileSide)
        let raw = CoasterElementArtwork.centreline(for: definition.motif,
                                                   size: design,
                                                   trackY: definition.trackLine)

        let centre = elementSpriteCentre(element, definition: definition)
        let angle = -CGFloat(((element.rotation % 4) + 4) % 4) * .pi / 2
        let cosine = cos(angle)
        let sine = sin(angle)

        return raw.map { point in
            // Texture space runs y downward from the top-left corner; the
            // sprite's own space runs y upward from its middle.
            let localX = point.x - design.width / 2
            let localY = design.height / 2 - point.y
            return CGPoint(x: centre.x + localX * cosine - localY * sine,
                           y: centre.y + localX * sine + localY * cosine)
        }
    }

    /// Where an element's sprite sits. It is taller than its footprint, so it
    /// is pushed up by the difference, in whichever direction is up once the
    /// element has been turned.
    private func elementSpriteCentre(_ element: TrackElement,
                                     definition: CoasterElementDefinition) -> CGPoint {
        let footCentre = CGPoint(
            x: (CGFloat(element.origin.x) + CGFloat(element.size.width) / 2) * Self.tileSide,
            y: (CGFloat(element.origin.y) + CGFloat(element.size.height) / 2) * Self.tileSide)

        let drawn = element.size.rotated(by: element.rotation)
        let overhang = CGFloat(definition.visualHeight - drawn.height) / 2 * Self.tileSide
        guard overhang != 0 else { return footCentre }

        let angle = -CGFloat(((element.rotation % 4) + 4) % 4) * .pi / 2
        return CGPoint(x: footCentre.x - sin(angle) * overhang,
                       y: footCentre.y + cos(angle) * overhang)
    }

    private func tileCentre(_ coord: GridCoord) -> CGPoint {
        CGPoint(x: (CGFloat(coord.x) + 0.5) * Self.tileSide,
                y: (CGFloat(coord.y) + 0.5) * Self.tileSide)
    }

    /// Puts a train on every circuit that has something to serve it.
    ///
    /// The railway and the coaster are the same problem with different
    /// liveries and different speeds: a ring of tiles, some stations against
    /// it, and a string of cars to run round it.
    private func runTrains(on network: TrackNetwork,
                           servedBy stations: [Attraction],
                           coaster: Bool,
                           elements: [TrackElement]) {
        let carSize = coaster
            ? CGSize(width: Self.tileSide * 0.62, height: Self.tileSide * 0.40)
            : CGSize(width: Self.tileSide * 0.86, height: Self.tileSide * 0.46)
        // A railway needs a station at each end to be worth running. A coaster
        // circuit is one ride, so one station is the whole thing.
        let stationsNeeded = coaster ? 1 : 2

        for (index, route) in network.routes.enumerated() where route.tiles.count > 2 {
            // A train only runs where there is something for it to do. Laying
            // a tile of track should not put a locomotive on the map.
            let served = stations.filter { network.routeIndex(touching: $0.rect) == index }
            guard served.count >= stationsNeeded else { continue }

            // Tile centres turn through a right angle at a bend. Rounding
            // them off makes the train curve through a corner the way the
            // rails are drawn, rather than pivoting on the spot at the end of
            // the turn.
            // Elements have already put their own curves in, so those are
            // smoothed less: rounding a loop again only softens it.
            let points = PathMotion.smoothed(ridePoints(for: route, elements: elements),
                                             closed: route.isLoop,
                                             iterations: elements.isEmpty ? 2 : 1)
            // A tile a second or so, which reads as a park train rather than
            // as something anybody would ride for the speed.
            let isLoop = route.isLoop
            // A coaster is meant to be quick and a park train is not, and a
            // line is covered twice a cycle. Paced off the line the train
            // actually runs rather than off the tiles, because an element can
            // add a great deal of track without adding a single tile.
            let pace = coaster ? 0.34 : 0.85
            let span = Double(PathMotion.ringLength(of: points) / Self.tileSide)
            let duration = span * (isLoop ? pace : pace * 2)

            // On a loop the lead car pulls the rest, each starting a tile
            // further back round the ring. On a dead-ended line it is a
            // push-pull set with a locomotive at each end, so the train
            // reverses at the terminus without anything turning round.
            let cars = coaster ? 4 : 3
            let spacing = coaster ? Self.tileSide * 0.68 : Self.tileSide
            let consist = spacing * CGFloat(cars - 1)

            for carriage in 0..<cars {
                // A coaster train has a lead car and followers. A shuttle
                // railway has a locomotive at each end so it can reverse.
                let isTailLocomotive = !coaster && !isLoop && carriage == cars - 1
                let isLeading = carriage == 0 || isTailLocomotive

                let texture = coaster
                    ? SpriteFactory.coasterCarTexture(isLeading: carriage == 0,
                                                      style: served.first?.carStyle ?? .classic,
                                                      colour: served.first?.livery ?? .red,
                                                      size: carSize)
                    : SpriteFactory.trainCarTexture(isLocomotive: isLeading, size: carSize)

                let node = SKSpriteNode(texture: texture)
                node.size = carSize
                // The rear locomotive faces the other way, which is what makes
                // a set that runs equally well in both directions read as one.
                if isTailLocomotive { node.xScale = -1 }
                // Above the element structures, which sit at -1.
                node.zPosition = 1
                trainLayer.addChild(node)

                if coaster, let ride = served.first {
                    coasterCars.append(CoasterCar(node: node,
                                                  attraction: ride.id,
                                                  isLeading: carriage == 0,
                                                  size: carSize))
                    renderedLivery[ride.id] = "\(ride.livery.rawValue)|\(ride.carStyle.rawValue)"
                }

                if isLoop {
                    // Smoothing multiplied the points, so a carriage sits a
                    // tile back in points rather than one array step back.
                    let perTile = max(1, points.count / max(route.tiles.count, 1))
                    let back = (carriage * perTile) % points.count
                    let offset = (points.count - back) % points.count
                    let carPath = Array(points[offset...] + points[..<offset])
                    PathMotion.drive(node, around: carPath, duration: duration)
                } else {
                    let run = PathMotion.shuttleRun(along: points,
                                                    carIndex: carriage,
                                                    carSpacing: spacing,
                                                    consistLength: consist,
                                                    samples: max(48, points.count * 3))
                    PathMotion.drive(node,
                                     around: run.points,
                                     duration: duration,
                                     headings: run.headings)
                }

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
                                    appearance: (attraction.definition?.appearance ?? .unknown)
                                        .tinted(attraction.tint)
                                        .applying(state.scheme),
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
                                    appearance: (facility.definition?.appearance ?? .unknown)
                                        .applying(state.scheme),
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
            renderedAppearance.removeValue(forKey: id)
        }
    }

    /// Scenery never changes once placed, so this only ever adds nodes for new
    /// items and removes nodes for demolished ones.
    private func syncScenery(state: GameState) {
        var seen = Set<UUID>()

        for item in state.scenery {
            seen.insert(item.id)
            guard sceneryNodes[item.id] == nil else { continue }

            let appearance = (item.definition?.appearance ?? .unknown)
                .withVariant(item.variant)
                .applying(state.scheme)
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
            if renderedAppearance[id] == appearance {
                existing.setTitle(title)
                return existing
            }
            // Repainted since it was built, so it is drawn again.
            existing.removeFromParent()
            buildingNodes.removeValue(forKey: id)
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
        renderedAppearance[id] = appearance
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
                                                                  prize: guest.prize,
                                                                  height: height))
                node.size = guestSize
                guestLayer.addChild(node)
                guestNodes[guest.id] = node
                guestMood[guest.id] = mood
                guestPrize[guest.id] = guest.prize
            }

            // Guests inside a ride or a building are not drawn. Furniture is
            // the exception: somebody at a booth is stood at the counter and
            // somebody on a bench is sat in the open, and a bench whose
            // occupants vanish looks like a bench nobody uses.
            if case .engaged(let target) = guest.activity, !isInTheOpen(target, state: state) {
                node.isHidden = true
                continue
            }
            node.isHidden = false

            if guestMood[guest.id] != mood || guestPrize[guest.id] != guest.prize {
                guestMood[guest.id] = mood
                guestPrize[guest.id] = guest.prize
                node.texture = GuestArtwork.texture(for: guest.appearance,
                                                    age: guest.ageCategory,
                                                    mood: mood,
                                                    prize: guest.prize,
                                                    height: height)
            }

            node.position = drawPosition(of: guest)

            showBubbleIfNeeded(for: guest, on: node, now: now)
        }

        for (id, node) in guestNodes where !seen.contains(id) {
            node.removeFromParent()
            guestNodes.removeValue(forKey: id)
            guestMood.removeValue(forKey: id)
            guestPrize.removeValue(forKey: id)
            shownThought.removeValue(forKey: id)
        }
    }

    /// Whether a guest busy with something is still out in the open: playing
    /// at a booth's counter, or sitting on a bench or at a picnic table.
    private func isInTheOpen(_ target: ParkTarget, state: GameState) -> Bool {
        guard case .facility(let id) = target else { return false }
        guard let kind = state.facility(id: id)?.definition?.kind else { return false }
        return kind == .game || kind == .bench
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
        // A placement waiting to be confirmed is drawn as the thing itself,
        // the way round it would actually stand. A tinted rectangle told the
        // player where a building would go but nothing about which way it was
        // facing, which is how a ride ends up backwards and paid for.
        if let pending = controller.build.pending,
           let definition = controller.pendingDefinition {
            syncPendingPreview(pending: pending, definition: definition, controller: controller)
            ghostNode?.isHidden = true
            return
        }

        hidePendingPreview()

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

    /// Draws the building that is waiting to be confirmed, plus a frame round
    /// the ground it would take up, coloured by whether it would be allowed.
    private func syncPendingPreview(pending: PendingPlacement,
                                    definition: BuildableDefinition,
                                    controller: GameController) {
        let footprint = controller.pendingFootprint
        let drawn = footprint.rotated(by: pending.rotation)
        let groundSize = CGSize(width: CGFloat(footprint.width) * Self.tileSide,
                                height: CGFloat(footprint.height) * Self.tileSide)
        let drawnSize = CGSize(width: CGFloat(drawn.width) * Self.tileSide,
                               height: CGFloat(drawn.height) * Self.tileSide)
        let centre = CGPoint(x: (CGFloat(pending.origin.x) + CGFloat(footprint.width) / 2) * Self.tileSide,
                             y: (CGFloat(pending.origin.y) + CGFloat(footprint.height) / 2) * Self.tileSide)
        let valid = controller.pendingCheck?.isValid ?? false

        let art: SKSpriteNode
        if let existing = previewNode {
            art = existing
        } else {
            art = SKSpriteNode()
            art.zPosition = 6
            art.alpha = 0.92
            overlayLayer.addChild(art)
            previewNode = art
        }

        if let element = definition as? CoasterElementDefinition {
            // The preview is drawn at the element's full height, so what the
            // player lines up is the shape they will get.
            let previewSize = CGSize(width: drawnSize.width,
                                     height: CGFloat(element.visualHeight) * Self.tileSide)
            art.texture = CoasterElementArtwork.texture(
                for: element.motif,
                size: previewSize,
                trackY: element.trackLine,
                rail: controller.state.coasterTrackColour)
            art.size = previewSize
            art.zRotation = -CGFloat(((pending.rotation % 4) + 4) % 4) * .pi / 2
            art.position = pendingElementCentre(pending, definition: element)
            art.isHidden = false
            art.colorBlendFactor = valid ? 0 : 0.55
            art.color = ParkPalette.ghostInvalid
            drawFrame(valid: valid, size: groundSize, centre: centre)
            return
        }

        if let appearance = definition.previewAppearance {
            // Shown in the style and the colours it would actually be built
            // in, so the preview is the thing rather than a picture of it.
            let styled = appearance
                .withVariant(controller.build.variant ?? 0)
                .applying(controller.state.scheme)
            art.texture = BuildingArtwork.bodyTexture(for: styled, size: drawnSize)
        } else {
            art.texture = SpriteFactory.buildingTexture(colour: ParkPalette.ghostValid, size: drawnSize)
        }
        art.size = drawnSize
        art.zRotation = -CGFloat(((pending.rotation % 4) + 4) % 4) * .pi / 2
        art.position = centre
        art.isHidden = false
        // A placement that cannot be made is greyed as well as outlined, so it
        // reads as refused even where the frame is hard to see.
        art.colorBlendFactor = valid ? 0 : 0.55
        art.color = ParkPalette.ghostInvalid

        drawFrame(valid: valid, size: groundSize, centre: centre)
    }

    /// The pulsing outline round the ground a placement would take up. Pulsing
    /// so an unconfirmed placement is never mistaken for something built.
    private func drawFrame(valid: Bool, size: CGSize, centre: CGPoint) {
        let frame: SKSpriteNode
        if let existing = previewOutline {
            frame = existing
        } else {
            frame = SKSpriteNode()
            frame.zPosition = 7
            overlayLayer.addChild(frame)
            previewOutline = frame

            let grow = SKAction.scale(to: 1.04, duration: 0.6)
            let shrink = SKAction.scale(to: 1.0, duration: 0.6)
            grow.timingMode = .easeInEaseOut
            shrink.timingMode = .easeInEaseOut
            frame.run(.repeatForever(.sequence([grow, shrink])))
        }

        frame.texture = SpriteFactory.outlineTexture(
            colour: valid ? ParkPalette.previewValid : ParkPalette.ghostInvalid,
            size: size,
            lineWidth: 4)
        frame.size = size
        frame.position = centre
        frame.isHidden = false
    }

    /// Where an element's preview sprite sits: pushed up out of its footprint
    /// by the same amount the placed one will be.
    private func pendingElementCentre(_ pending: PendingPlacement,
                                      definition: CoasterElementDefinition) -> CGPoint {
        let footprint = definition.footprint(rotatedBy: pending.rotation)
        let element = TrackElement(id: UUID(),
                                   definitionID: definition.id,
                                   origin: pending.origin,
                                   size: footprint,
                                   rotation: pending.rotation)
        return elementSpriteCentre(element, definition: definition)
    }

    private func hidePendingPreview() {
        previewNode?.isHidden = true
        previewOutline?.isHidden = true
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
