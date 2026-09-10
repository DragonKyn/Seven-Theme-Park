import SpriteKit
import SwiftUI

/// Holds the park running behind the main menu.
///
/// The menu is a struct and gets rebuilt constantly, so the controller and the
/// scene live here instead. Building one is not cheap: it lays out a park and
/// simulates it briefly, so it is created once when the menu appears and kept
/// for as long as the menu is on screen.
@MainActor
final class DemoParkBackdrop {
    let controller: GameController
    let scene: ParkScene

    init() {
        controller = GameController.demo()

        scene = ParkScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .resizeFill
        scene.isInteractive = false
        scene.controller = controller
    }
}
