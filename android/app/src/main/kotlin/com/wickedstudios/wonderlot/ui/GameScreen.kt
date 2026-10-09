package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.runtime.Composable
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
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                SpeedControl(controller, onLockedTap = { sheet = GameSheet.Boosts })
            }
            ControlBar(controller,
                onFinance = { sheet = GameSheet.Finance }, onManage = { sheet = GameSheet.Management },
                onStaff = { sheet = GameSheet.Staff }, onBoosts = { sheet = GameSheet.Boosts },
                onAchievements = { sheet = GameSheet.Achievements }, onLeave = { confirmExit = true })
        }

        controller.notice?.let { message ->
            Box(Modifier.align(Alignment.TopCenter).statusBarsPadding().padding(top = 70.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.75f))
                .padding(horizontal = 14.dp, vertical = 7.dp)) { Label(message, size = 12.sp, color = Color.White) }
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
        GameSheet.Settings -> ParkSettingsSheet(controller, close)
        GameSheet.Alerts -> AlertsSheet(controller, close)
        GameSheet.Boosts -> BoostsSheet(services, close)
        GameSheet.Achievements -> AchievementsSheet(controller, close)
    }
}

@Composable
private fun Hud(controller: GameController, onOpenFinance: () -> Unit, onAlerts: () -> Unit, onSettings: () -> Unit) {
    val hud = controller.hud
    Row(Modifier.fillMaxWidth().panelBackground().padding(8.dp), verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Box(Modifier.clickable(onClick = onOpenFinance)) {
            MoneyPill(hud.cash, hud.todayProfit, hud.mode == GameMode.freeBuild)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Label(hud.parkName, size = 13.sp, weight = FontWeight.ExtraBold, maxLines = 1)
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                StarRating(hud.starRating)
                Label("Day ${hud.day}  ${hud.clockLabel}", size = 11.sp, color = Theme.textSecondary, maxLines = 1)
            }
        }
        StatPill("person.2.fill", "${hud.guestCount}")
        val hasAlerts = controller.alerts.isNotEmpty()
        Box(Modifier.size(34.dp).clip(CircleShape).background(if (hasAlerts) Theme.accentWarm else Theme.control).clickable(onClick = onAlerts),
            contentAlignment = Alignment.Center) { SymbolIcon("bell.fill", if (hasAlerts) Color.Black else Theme.textPrimary, 16.dp) }
        Box(Modifier.size(34.dp).clip(CircleShape).background(Theme.control).clickable(onClick = onSettings), contentAlignment = Alignment.Center) {
            SymbolIcon("gearshape.fill", Theme.textPrimary, 16.dp)
        }
    }
}

@Composable
private fun SpeedControl(controller: GameController, onLockedTap: () -> Unit, modifier: Modifier = Modifier) {
    val current = controller.hud.speed
    val turbo = controller.isTurboUnlocked
    Row(modifier.clip(RoundedCornerShape(10.dp)).background(Theme.control).padding(3.dp), horizontalArrangement = Arrangement.spacedBy(3.dp)) {
        for (speed in GameSpeed.entries) {
            val locked = speed.needsBoost && !turbo
            Box(
                Modifier.size(width = 30.dp, height = 40.dp).clip(RoundedCornerShape(8.dp))
                    .background(if (speed == current) Theme.accent else Color.Transparent)
                    .clickable { if (locked) onLockedTap() else controller.setSpeed(speed) },
                contentAlignment = Alignment.Center,
            ) {
                if (locked) SymbolIcon("lock.fill", Theme.textSecondary, 12.dp)
                else Label(speed.label, size = 11.sp, weight = FontWeight.ExtraBold, color = if (speed == current) Color.Black else Theme.textPrimary)
            }
        }
    }
}

@Composable
private fun ControlBar(
    controller: GameController, onFinance: () -> Unit, onManage: () -> Unit, onStaff: () -> Unit,
    onBoosts: () -> Unit, onAchievements: () -> Unit, onLeave: () -> Unit,
) {
    var menuOpen by remember { mutableStateOf(false) }
    val building = controller.build.isActive
    Row(Modifier.fillMaxWidth().panelBackground().padding(8.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
        ControlButton(if (building) "xmark" else "hammer.fill", if (building) "Close" else "Build",
            { if (building) controller.exitBuildMode() else controller.enterBuildMode(BuildCategory.path) }, highlighted = building)
        ControlButton("chart.bar.fill", "Manage", onManage)
        ControlButton("person.2.badge.gearshape.fill", "Staff", onStaff)
        ControlButton("dollarsign.circle.fill", "Money", onFinance, tint = Theme.money)
        Box {
            ControlButton("line.3.horizontal", "Menu", { menuOpen = true })
            DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                DropdownMenuItem(text = { Text("Achievements") }, onClick = { menuOpen = false; onAchievements() })
                DropdownMenuItem(text = { Text("Boosts") }, onClick = { menuOpen = false; onBoosts() })
                DropdownMenuItem(text = { Text("Save park") }, onClick = { menuOpen = false; controller.save() })
                DropdownMenuItem(text = { Text("Leave park", color = Theme.danger) }, onClick = { menuOpen = false; onLeave() })
            }
        }
    }
}

// region Sheets

@Composable
private fun ParkSettingsSheet(controller: GameController, onDismiss: () -> Unit) {
    val hud = controller.hud
    var price by remember { mutableStateOf(hud.admissionPrice.toFloat()) }
    val limit = controller.admissionPriceLimit.toFloat()
    BottomSheet("Park", onDismiss) {
        SectionCard("Gate") {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Label("Admission", modifier = Modifier.weight(1f))
                Label(CurrencyFormatter.short(price.toDouble()), weight = FontWeight.ExtraBold, color = Theme.money)
            }
            Slider(
                value = price.coerceIn(0f, limit), onValueChange = { price = it; controller.setAdmissionPrice(it.toDouble()) },
                valueRange = 0f..limit,
                colors = SliderDefaults.colors(thumbColor = Theme.accent, activeTrackColor = Theme.accent),
            )
            Label("${"%.0f".format(hud.arrivalsPerMinute)} arrivals a minute at this price.", size = 11.sp, color = Theme.textSecondary)
        }
        SectionCard("Tips") {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Label("Show tips")
                    Label(controller.tipsReadText, size = 11.sp, color = Theme.textSecondary)
                }
                var enabled by remember { mutableStateOf(controller.tipsEnabled) }
                Switch(checked = enabled, onCheckedChange = { enabled = it; controller.setTipsEnabled(it) })
            }
            PillButton("Show all tips again", { controller.resetTips() }, background = Theme.control, foreground = Theme.textPrimary)
        }
        SectionCard("Save") {
            PillButton("Save now", { controller.save() }, symbol = "square.and.arrow.down")
            controller.saveMessage?.let { Label(it, size = 11.sp, color = Theme.textSecondary) }
        }
    }
}

@Composable
private fun AlertsSheet(controller: GameController, onDismiss: () -> Unit) {
    BottomSheet("Alerts", onDismiss, tall = true) {
        if (controller.alerts.isEmpty()) Label("Nothing needs attention.", color = Theme.textSecondary)
        for (alert in controller.alerts.reversed()) {
            val colour = when (alert.severity) {
                AlertSeverity.info -> Theme.accent
                AlertSeverity.warning -> Theme.accentWarm
                AlertSeverity.critical -> Theme.danger
            }
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Theme.control)
                    .clickable(enabled = alert.target != null) { alert.target?.let { controller.focus(it); onDismiss() } }.padding(10.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically,
            ) {
                SymbolIcon(alert.severity.symbolName, colour, 18.dp)
                Column(Modifier.weight(1f)) {
                    Label(alert.message, size = 13.sp)
                    Label(alert.timeLabel, size = 10.sp, color = Theme.textSecondary)
                }
            }
        }
    }
}

@Composable
private fun BoostsSheet(services: AppServices, onDismiss: () -> Unit) {
    BottomSheet("Boosts", onDismiss) {
        Label("Short helpers you can switch on. Rewarded adverts are not wired up in this build yet, so boosts cannot be started.",
            size = 12.sp, color = Theme.textSecondary)
        for (kind in BoostKind.entries) {
            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Theme.control).padding(10.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                SymbolIcon(kind.symbolName, Theme.accentWarm, 22.dp)
                Column(Modifier.weight(1f)) {
                    Label(kind.title, weight = FontWeight.ExtraBold)
                    Label(kind.summary, size = 11.sp, color = Theme.textSecondary)
                }
                services.boosts.remainingLabel(kind)?.let { Label(it, weight = FontWeight.ExtraBold, color = Theme.accent) }
            }
        }
    }
}

@Composable
private fun AchievementsSheet(controller: GameController, onDismiss: () -> Unit) {
    val progress = remember { controller.makeAchievementProgress() }
    BottomSheet("Achievements", onDismiss, tall = true) {
        for (item in progress) {
            val def = item.definition
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Theme.control).padding(10.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    SymbolIcon(def.symbolName, if (item.earnedTier > 0) Theme.money else Theme.textSecondary, 20.dp)
                    Column(Modifier.weight(1f)) {
                        Label(def.name, weight = FontWeight.ExtraBold)
                        Label(def.summary, size = 11.sp, color = Theme.textSecondary)
                    }
                    Label("${item.earnedTier}/${def.tierCount}", weight = FontWeight.ExtraBold)
                }
                if (!item.isComplete) {
                    Box(Modifier.fillMaxWidth().height(4.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.12f))) {
                        Box(Modifier.fillMaxWidth(item.fraction.toFloat()).height(4.dp).clip(CircleShape).background(Theme.accent))
                    }
                    item.nextThreshold?.let { Label("${item.format(item.current)} of ${item.format(it)}", size = 10.sp, color = Theme.textSecondary) }
                }
            }
        }
    }
}

// endregion
