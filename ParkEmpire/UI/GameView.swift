import SpriteKit
import SwiftUI

/// The playing screen: the SpriteKit park with every overlay stacked on top.
struct GameView: View {
    @ObservedObject var controller: GameController
    @EnvironmentObject private var router: AppRouter

    @State private var scene: ParkScene?
    @State private var showingFinance = false
    @State private var showingManagement = false
    @State private var showingSettings = false
    @State private var showingAlerts = false
    @State private var showingStaff = false
    @State private var showingAchievements = false

    var body: some View {
        ZStack {
            parkSurface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HUDView(hud: controller.hud,
                        alertCount: controller.alerts.count,
                        onOpenFinance: { showingFinance = true },
                        onOpenAlerts: { showingAlerts = true },
                        onOpenSettings: { showingSettings = true })
                    .padding(.horizontal, 10)
                    .padding(.top, 6)

                if let tip = controller.currentTip {
                    TutorialTipView(tip: tip,
                                    onDismiss: { controller.dismissTip() },
                                    onTurnOff: { controller.setTipsEnabled(false) })
                        .padding(.horizontal, 10)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer(minLength: 0)

                VStack(spacing: 8) {
                    if let selection = controller.selection {
                        InspectorHostView(selection: selection, controller: controller)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if controller.build.isActive {
                        BuildMenuView(controller: controller)
                            .transition(.move(edge: .bottom))
                    }

                    ControlBarView(controller: controller,
                                   onOpenFinance: { showingFinance = true },
                                   onOpenManagement: { showingManagement = true },
                                   onOpenStaff: { showingStaff = true },
                                   onOpenAchievements: { showingAchievements = true },
                                   onExit: { router.exitToMenu() })
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
            }
            .animation(.easeInOut(duration: 0.18), value: controller.build.isActive)
            .animation(.easeInOut(duration: 0.18), value: controller.selection?.identity)
            .animation(.easeInOut(duration: 0.18), value: controller.build.pending)
            .animation(.easeInOut(duration: 0.22), value: controller.currentTip)

            if let award = controller.celebration {
                CelebrationView(award: award) { controller.dismissCelebration() }
                    .transition(.opacity)
            }

            if let event = controller.event {
                EventCardView(event: event) { controller.dismissEvent() }
                    .id(event.id)
                    .transition(.opacity)
            }
        }
        .onAppear(perform: prepareScene)
        .sheet(isPresented: $showingFinance) {
            FinanceView(controller: controller)
        }
        .sheet(isPresented: $showingManagement) {
            ManagementView(controller: controller)
        }
        .sheet(isPresented: $showingStaff) {
            StaffView(controller: controller)
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView(controller: controller)
        }
        .sheet(isPresented: $showingSettings) {
            ParkSettingsView(controller: controller)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingAlerts) {
            AlertListView(alerts: controller.alerts) { target in
                controller.focus(on: target)
                showingAlerts = false
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Remove this structure?",
               isPresented: Binding(get: { controller.pendingDemolition != nil },
                                    set: { if !$0 { controller.cancelPendingDemolition() } }),
               presenting: controller.pendingDemolition) { _ in
            Button("Remove", role: .destructive) { controller.confirmPendingDemolition() }
            Button("Cancel", role: .cancel) { controller.cancelPendingDemolition() }
        } message: { pending in
            Text("Removing \(pending.name) refunds \(CurrencyFormatter.short(pending.refund)).")
        }
    }

    @ViewBuilder
    private var parkSurface: some View {
        if let scene {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
        } else {
            Color(red: 0.42, green: 0.66, blue: 0.38)
        }
    }

    private func prepareScene() {
        guard scene == nil else { return }
        let newScene = ParkScene(size: CGSize(width: 390, height: 844))
        newScene.scaleMode = .resizeFill
        newScene.controller = controller
        scene = newScene
    }
}

// MARK: - Bottom control bar

private struct ControlBarView: View {
    @ObservedObject var controller: GameController
    let onOpenFinance: () -> Void
    let onOpenManagement: () -> Void
    let onOpenStaff: () -> Void
    let onOpenAchievements: () -> Void
    let onExit: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button {
                if controller.build.isActive {
                    controller.exitBuildMode()
                } else {
                    controller.enterBuildMode(category: .path)
                }
            } label: {
                ControlButtonLabel(symbol: controller.build.isActive ? "xmark" : "hammer.fill",
                                   title: controller.build.isActive ? "Close" : "Build",
                                   highlighted: controller.build.isActive)
            }

            Button(action: onOpenManagement) {
                ControlButtonLabel(symbol: "chart.bar.fill", title: "Manage")
            }

            Button(action: onOpenStaff) {
                ControlButtonLabel(symbol: "person.2.badge.gearshape.fill", title: "Staff")
            }

            Button(action: onOpenFinance) {
                ControlButtonLabel(symbol: "dollarsign.circle.fill",
                                   title: "Money",
                                   tint: Theme.money)
            }

            Spacer(minLength: 0)

            SpeedControlView(speed: controller.hud.speed) { controller.setSpeed($0) }

            Menu {
                Button("Achievements", systemImage: "rosette", action: onOpenAchievements)
                Button("Save park") { controller.save() }
                Button("Save and exit", role: .destructive, action: onExit)
            } label: {
                ControlButtonLabel(symbol: "line.3.horizontal", title: "Menu")
            }
        }
        .padding(8)
        .panelBackground()
        .overlay(alignment: .top) {
            if let message = controller.saveMessage {
                Text(message)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.accent))
                    .foregroundStyle(.black)
                    .offset(y: -28)
                    .task {
                        try? await Task.sleep(nanoseconds: 1_600_000_000)
                        controller.clearSaveMessage()
                    }
            }
        }
    }
}

private struct ControlButtonLabel: View {
    let symbol: String
    let title: String
    var highlighted = false
    /// Colours the icon only, so one button can be picked out of the row
    /// without turning the whole thing into a different kind of control.
    var tint: Color?

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(highlighted ? Color.black : (tint ?? Theme.textPrimary))
            Text(title)
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .frame(width: 40, height: 42)
        .foregroundStyle(highlighted ? Color.black : Theme.textPrimary)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(highlighted ? Theme.accentWarm : Theme.control)
        )
    }
}
