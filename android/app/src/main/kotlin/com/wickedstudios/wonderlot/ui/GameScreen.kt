package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Text
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Switch
import androidx.activity.compose.BackHandler
import androidx.compose.runtime.Composable
import com.wickedstudios.wonderlot.AppInfo
import com.wickedstudios.wonderlot.Balance
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.draw.alpha
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.foundation.border
import android.app.Activity
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wickedstudios.wonderlot.AlertSeverity
import com.wickedstudios.wonderlot.BoostKind
import com.wickedstudios.wonderlot.CurrencyFormatter
import com.wickedstudios.wonderlot.GameController
import com.wickedstudios.wonderlot.GameMode
import com.wickedstudios.wonderlot.GameSpeed
import com.wickedstudios.wonderlot.BuildCategory
import com.wickedstudios.wonderlot.app.AppRouter
import com.wickedstudios.wonderlot.app.AppServices

private enum class GameSheet { None, Finance, Management, Staff, Settings, Alerts, Boosts, Achievements }

/** The park, with everything the player does to it laid over the top. */
@Composable
fun GameScreen(controller: GameController, router: AppRouter, services: AppServices) {
    // Reading this inside composition is what subscribes the interface to the controller's updates.
    val version = remember(controller) { mutableIntStateOf(0) }
    @Suppress("UNUSED_VARIABLE") val observed = version.intValue

    var sheet by remember { mutableStateOf(GameSheet.None) }
    var trialExpanded by remember { mutableStateOf(true) }
    var confirmExit by remember { mutableStateOf(false) }

    val hud = controller.hud
    val build = controller.build

    // The system Back button peels things off one layer at a time and only then offers to leave.
    BackHandler(enabled = sheet == GameSheet.None) {
        when {
            controller.pendingDemolition != null -> controller.cancelPendingDemolition()
            confirmExit -> confirmExit = false
            controller.movingStaffID != null -> controller.cancelStaffMove()
            build.isActive -> controller.exitBuildMode()
            controller.selection != null -> controller.clearSelection()
            else -> confirmExit = true
        }
    }

    Box(Modifier.fillMaxSize()) {
        ParkViewHost(controller, interactive = true, modifier = Modifier.fillMaxSize(), onVersion = { version.intValue = it })

        // Top: readouts, then whatever advice or goals apply.
        Column(Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 10.dp, vertical = 6.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Hud(controller, onOpenFinance = { sheet = GameSheet.Finance }, onAlerts = { sheet = GameSheet.Alerts },
                onSettings = { sheet = GameSheet.Settings })
            hud.trial?.let { TrialTracker(it, trialExpanded) { trialExpanded = !trialExpanded } }
            controller.currentTip?.let {
                TutorialTipCard(it, onDismiss = { controller.dismissTip() }, onTurnOff = { controller.setTipsEnabled(false); controller.dismissTip() })
            }
        }

        // Bottom: speed, then the build menu or the control bar.
        Column(Modifier.align(Alignment.BottomCenter).fillMaxWidth().navigationBarsPadding().padding(horizontal = 10.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)) {
            if (controller.movingStaffID != null) StaffMoveBar(controller)
            else controller.selection?.let { InspectorHost(it, controller) }
            if (build.isActive) BuildMenu(controller)
            ControlBar(controller,
                onFinance = { sheet = GameSheet.Finance }, onManage = { sheet = GameSheet.Management },
                onStaff = { sheet = GameSheet.Staff }, onBoosts = { sheet = GameSheet.Boosts },
                onAchievements = { sheet = GameSheet.Achievements }, onLeave = { confirmExit = true })
        }

        (controller.saveMessage ?: controller.notice)?.let { message ->
            LaunchedEffect(message) {
                delay(1600)
                controller.clearSaveMessage()
            }
            Box(Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 74.dp).clip(CircleShape).background(Theme.accent)
                .padding(horizontal = 10.dp, vertical = 5.dp)) { Label(message, size = 12.sp, weight = FontWeight.SemiBold, color = Color.Black) }
        }

        controller.event?.let { EventCard(it, controller.eventRemaining) { controller.dismissEvent() } }
        controller.celebration?.let { CelebrationCard(it) { controller.dismissCelebration() } }
        controller.trialResult?.let { report ->
            TrialResultCard(report,
                onKeepPlaying = { controller.dismissTrialResult() },
                onLeave = {
                    controller.dismissTrialResult()
                    router.opensLadderOnMenu = report.result.trial != null
                    router.exitToMenu()
                })
        }
    }

    controller.pendingDemolition?.let { pending ->
        ConfirmDialog(
            title = "Demolish ${pending.name}?",
            message = "You will be refunded ${CurrencyFormatter.short(pending.refund)}.",
            confirmText = "Demolish", destructive = true,
            onConfirm = { controller.confirmPendingDemolition() },
            onDismiss = { controller.cancelPendingDemolition() },
        )
    }

    if (confirmExit) {
        ConfirmDialog(
            title = "Back to the menu?", message = "The park is saved first.", confirmText = "Save and leave",
            onConfirm = { confirmExit = false; router.exitToMenu() }, onDismiss = { confirmExit = false },
        )
    }

    val close = { sheet = GameSheet.None }
    when (sheet) {
        GameSheet.None -> {}
        GameSheet.Finance -> FinanceSheet(controller, close)
        GameSheet.Management -> ManagementSheet(controller, close)
        GameSheet.Staff -> StaffSheet(controller, close)
        GameSheet.Settings -> ParkSettingsSheet(controller, services, close)
        GameSheet.Alerts -> AlertsSheet(controller, close)
        GameSheet.Boosts -> BoostsSheet(services, close)
        GameSheet.Achievements -> AchievementsSheet(controller, services, close)
    }
}

@Composable
private fun SpeedControl(controller: GameController, onLockedTap: () -> Unit, scale: Float, modifier: Modifier = Modifier) {
    val current = controller.hud.speed
    val turbo = controller.isTurboUnlocked
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
        for (speed in GameSpeed.entries) {
            val locked = speed.needsBoost && !turbo
            val background = when {
                locked -> Theme.control.copy(alpha = 0.6f * Theme.control.alpha)
                speed == current -> if (speed.needsBoost) Theme.accentWarm else Theme.accent
                else -> Theme.control
            }
            Box(Modifier.size(width = (28 * scale).dp, height = 32.dp)) {
                Box(
                    Modifier.fillMaxSize().clip(RoundedCornerShape(8.dp)).background(background)
                        .clickable { if (locked) onLockedTap() else controller.setSpeed(speed) },
                    contentAlignment = Alignment.Center,
                ) {
                    Label(speed.label, size = 12.sp, weight = FontWeight.ExtraBold,
                        color = if (locked) Theme.textSecondary else if (speed == current) Color.Black else Theme.textPrimary)
                }
                if (locked) {
                    SymbolIcon("play.rectangle.fill", Theme.accentWarm, 10.dp, Modifier.align(Alignment.TopEnd).offset(x = 2.dp, y = (-2).dp))
                }
            }
        }
    }
}

/**
 * Build, Manage, Staff, Money, the speed notches and the menu, in one bar, as on iOS. On a screen too narrow for the
 * natural sizes everything shrinks together rather than leaving gaps or running off the edge.
 */
@Composable
private fun ControlBar(
    controller: GameController, onFinance: () -> Unit, onManage: () -> Unit, onStaff: () -> Unit,
    onBoosts: () -> Unit, onAchievements: () -> Unit, onLeave: () -> Unit,
) {
    var menuOpen by remember { mutableStateOf(false) }
    val building = controller.build.isActive
    BoxWithConstraints(Modifier.fillMaxWidth().panelBackground().padding(8.dp)) {
        // Five buttons, five notches and their gaps, in dp, against what the bar actually has.
        val natural = 5 * 40f + (5 * 28f + 4 * 2f) + 6 * 6f
        val scale = (maxWidth.value / natural).coerceIn(0.8f, 1f)
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            ControlButton(if (building) "xmark" else "hammer.fill", if (building) "Close" else "Build",
                { if (building) controller.exitBuildMode() else controller.enterBuildMode(BuildCategory.path) }, highlighted = building, scale = scale)
            ControlButton("chart.bar.fill", "Manage", onManage, scale = scale)
            ControlButton("person.2.badge.gearshape.fill", "Staff", onStaff, scale = scale)
            ControlButton("dollarsign.circle.fill", "Money", onFinance, tint = Theme.money, scale = scale)
            Spacer(Modifier.weight(1f))
            SpeedControl(controller, onLockedTap = onBoosts, scale = scale)
            Box {
                ControlButton("line.3.horizontal", "Menu", { menuOpen = true }, scale = scale)
                DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }, containerColor = Theme.panelRaised) {
                    DropdownMenuItem(text = { Text("Achievements", color = Theme.textPrimary, fontWeight = FontWeight.SemiBold) }, onClick = { menuOpen = false; onAchievements() })
                    DropdownMenuItem(text = { Text("Boosts", color = Theme.textPrimary, fontWeight = FontWeight.SemiBold) }, onClick = { menuOpen = false; onBoosts() })
                    DropdownMenuItem(text = { Text("Save park", color = Theme.textPrimary, fontWeight = FontWeight.SemiBold) }, onClick = { menuOpen = false; controller.save() })
                    DropdownMenuItem(text = { Text("Leave park", color = Theme.danger, fontWeight = FontWeight.SemiBold) }, onClick = { menuOpen = false; onLeave() })
                }
            }
        }
    }
}

// region Sheets

@Composable
private fun BoostsSheet(services: AppServices, onDismiss: () -> Unit) {
    val activity = LocalContext.current as? Activity
    val ads = services.ads
    val scope = rememberCoroutineScope()
    var pending by remember { mutableStateOf<BoostKind?>(null) }
    // Ticks once a second so the countdowns move.
    var tick by remember { mutableStateOf(0) }
    LaunchedEffect(Unit) {
        while (true) {
            delay(1000)
            services.boosts.refresh()
            tick += 1
        }
    }
    @Suppress("UNUSED_VARIABLE") val observed = tick
    val minutes = Balance.adBoostMinutes.toInt()

    BottomSheet("Boosts", onDismiss, tall = true) {
        Label(
            "Watch a short advert to switch one of these on for $minutes minutes. Watch another and the time stacks. " +
                "Neither is needed to finish anything in the game.",
            size = 13.sp, weight = FontWeight.Medium, color = Theme.textSecondary,
        )

        for (kind in BoostKind.entries) {
            val remaining = services.boosts.remainingLabel(kind)
            Column(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Color.White.copy(alpha = 0.08f))
                    .border(if (remaining == null) 1.dp else 2.dp, if (remaining == null) Color.White.copy(alpha = 0.08f) else Theme.money.copy(alpha = 0.5f), RoundedCornerShape(14.dp))
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier.size(42.dp).clip(CircleShape)
                            .then(if (remaining == null) Modifier.background(Theme.control) else Modifier.background(Theme.moneyGradient)),
                        contentAlignment = Alignment.Center,
                    ) { SymbolIcon(kind.symbolName, if (remaining == null) Theme.textSecondary else Color.Black.copy(alpha = 0.85f), 20.dp) }
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Label(kind.title, size = 16.sp, weight = FontWeight.ExtraBold)
                        Label(kind.summary, size = 12.sp, weight = FontWeight.Medium, color = Theme.textSecondary)
                    }
                }

                remaining?.let { Label("Running, $it left", size = 13.sp, weight = FontWeight.Bold, color = Theme.accent) }

                val busy = pending != null
                Box(
                    Modifier.fillMaxWidth().height(44.dp).clip(RoundedCornerShape(12.dp)).background(Theme.moneyGradient)
                        .alpha(if (!busy || pending == kind) 1f else 0.5f)
                        .clickable(enabled = !busy && activity != null) {
                            pending = kind
                            scope.launch {
                                val earned = ads.show(activity!!)
                                if (earned) services.boosts.grant(kind)
                                pending = null
                            }
                        },
                    contentAlignment = Alignment.Center,
                ) {
                    Label(
                        when {
                            pending == kind -> "Loading advert"
                            remaining != null -> "Watch another, add $minutes minutes"
                            else -> "Watch an advert, $minutes minutes"
                        },
                        size = 14.sp, weight = FontWeight.ExtraBold, color = Color.Black.copy(alpha = 0.88f),
                    )
                }
            }
        }

        ads.lastError?.let { Label(it, size = 12.sp, weight = FontWeight.SemiBold, color = Theme.danger) }
        Label(ads.statusLine, size = 11.sp, weight = FontWeight.SemiBold, color = Theme.textSecondary)
        Label(
            "No advert will ever interrupt your park. The only ones in ${AppInfo.gameName} are the ones you choose to watch here.",
            size = 11.sp, weight = FontWeight.Medium, color = Theme.textSecondary,
        )
        if (ads.canChangePrivacyChoices && activity != null) {
            PillButton("Privacy choices", { ads.showPrivacyOptions(activity) }, background = Theme.control, foreground = Theme.textPrimary)
        }
    }
}

// endregion
