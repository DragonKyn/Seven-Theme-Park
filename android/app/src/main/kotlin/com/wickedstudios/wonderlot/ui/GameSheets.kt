package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Switch
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wickedstudios.wonderlot.AchievementContent
import com.wickedstudios.wonderlot.AchievementDefinition
import com.wickedstudios.wonderlot.AchievementProgress
import com.wickedstudios.wonderlot.AlertSeverity
import com.wickedstudios.wonderlot.CarParkContent
import com.wickedstudios.wonderlot.CurrencyFormatter
import com.wickedstudios.wonderlot.GameController
import com.wickedstudios.wonderlot.GuestEconomics
import com.wickedstudios.wonderlot.ParkAlert
import com.wickedstudios.wonderlot.ParkColour
import com.wickedstudios.wonderlot.TrialContent
import com.wickedstudios.wonderlot.TrialDefinition
import com.wickedstudios.wonderlot.app.AppServices
import com.wickedstudios.wonderlot.app.GraphicsBudget
import com.wickedstudios.wonderlot.gfx.ParkPalette

/** Top bar: the four numbers that matter, plus the clock. Two rows, laid out as on iOS. */
@Composable
fun Hud(controller: GameController, onOpenFinance: () -> Unit, onAlerts: () -> Unit, onSettings: () -> Unit) {
    val hud = controller.hud
    Column(Modifier.fillMaxWidth().panelBackground().padding(8.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            // The number people tap when they want to know where it went.
            Box(Modifier.clickable(onClick = onOpenFinance)) {
                MoneyPill(hud.cash, hud.todayProfit, hud.mode.hasUnlimitedMoney)
            }
            StatPill("person.2.fill", "${hud.guestCount}")
            StatPill("face.smiling", "${hud.averageHappiness.toInt()}%", tint = Theme.happinessColour(hud.averageHappiness))

            Box(Modifier.weight(1f))

            Box(contentAlignment = Alignment.TopEnd) {
                Box(Modifier.size(28.dp).clip(CircleShape).background(Theme.control).clickable(onClick = onAlerts), contentAlignment = Alignment.Center) {
                    SymbolIcon("bell.fill", Theme.textPrimary, 14.dp)
                }
                if (controller.alerts.isNotEmpty()) {
                    Box(Modifier.size(7.dp).clip(CircleShape).background(Theme.danger))
                }
            }

            // Named, because a bare gear in the corner of a game reads as the app's settings.
            Row(
                Modifier.height(28.dp).clip(CircleShape).background(Theme.control).clickable(onClick = onSettings).padding(horizontal = 9.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically,
            ) {
                SymbolIcon("gearshape.fill", Theme.textPrimary, 12.dp)
                Label("Park", size = 11.sp, weight = FontWeight.Bold)
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            // The park's own name opens the park's own settings.
            Row(Modifier.weight(1f, fill = false).clickable(onClick = onSettings), horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(verticalArrangement = Arrangement.spacedBy(1.dp), modifier = Modifier.weight(1f, fill = false)) {
                    Label(hud.parkName, size = 12.sp, weight = FontWeight.Bold, maxLines = 1)
                    StarRating(hud.starRating)
                }
                SymbolIcon("chevron.right", Theme.textSecondary, 9.dp)
            }

            Box(Modifier.weight(1f))

            StatPill("star.fill", "${hud.parkRating.toInt()}")
            StatPill("ticket", CurrencyFormatter.short(hud.admissionPrice))
            StatPill("clock", "Day ${hud.day} · ${hud.clockLabel}")
        }
    }
}

// region Notices

/** The park's notice board: severity legible before any of the words are. */
@Composable
fun AlertsSheet(controller: GameController, onDismiss: () -> Unit) {
    val alerts = controller.alerts
    var problemsOnly by remember { mutableStateOf(false) }
    val problems = alerts.count { it.severity != AlertSeverity.info }
    val visible = if (problemsOnly) alerts.filter { it.severity != AlertSeverity.info } else alerts
    val summary = when {
        alerts.isEmpty() -> "Nothing to report"
        problems == 0 -> "${alerts.size} recent, all routine"
        else -> "$problems need${if (problems == 1) "s" else ""} attention"
    }

    BottomSheet("Notices", onDismiss, tall = true, trailing = {
        Label(summary, size = 11.sp, weight = FontWeight.SemiBold, color = Theme.textSecondary, modifier = Modifier.padding(end = 10.dp))
    }) {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            NoticeChip("Everything", !problemsOnly, alerts.size) { problemsOnly = false }
            NoticeChip("Needs attention", problemsOnly, problems) { problemsOnly = true }
        }

        if (visible.isEmpty()) {
            Column(Modifier.fillMaxWidth().padding(vertical = 40.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                SymbolIcon(if (problemsOnly) "checkmark.seal.fill" else "bell.slash.fill", if (problemsOnly) Theme.accent else Theme.textSecondary, 32.dp)
                Label(if (problemsOnly) "Nothing needs you" else "No notices yet", size = 15.sp, weight = FontWeight.ExtraBold)
                Label(
                    if (problemsOnly) "The park is running itself for the moment." else "Breakdowns, queues and anything else worth knowing will appear here.",
                    size = 12.sp, weight = FontWeight.Medium, color = Theme.textSecondary, modifier = Modifier.padding(horizontal = 24.dp),
                )
            }
        }

        for (alert in visible) NoticeRow(alert) { target -> controller.focus(target); onDismiss() }
    }
}

@Composable
private fun NoticeChip(title: String, active: Boolean, count: Int, onClick: () -> Unit) {
    Row(
        Modifier.height(30.dp).clip(CircleShape).background(if (active) Theme.accentWarm else Theme.control).clickable(onClick = onClick).padding(horizontal = 11.dp),
        horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        Label(title, size = 12.sp, weight = FontWeight.Bold, color = if (active) Color.Black.copy(alpha = 0.85f) else Theme.textSecondary, maxLines = 1)
        Box(Modifier.clip(CircleShape).background(Color.Black.copy(alpha = if (active) 0.22f else 0.28f)).padding(horizontal = 5.dp, vertical = 1.dp)) {
            Label("$count", size = 10.sp, weight = FontWeight.ExtraBold, color = if (active) Color.Black.copy(alpha = 0.85f) else Theme.textSecondary)
        }
    }
}

@Composable
private fun NoticeRow(alert: ParkAlert, onSelect: (com.wickedstudios.wonderlot.ParkTarget) -> Unit) {
    val colour = when (alert.severity) {
        AlertSeverity.info -> Theme.accent
        AlertSeverity.warning -> Theme.accentWarm
        AlertSeverity.critical -> Theme.danger
    }
    val target = alert.target
    Row(
        Modifier.fillMaxWidth().height(IntrinsicSize.Min).clip(RoundedCornerShape(11.dp))
            .background(Color.White.copy(alpha = if (alert.severity == AlertSeverity.info) 0.07f else 0.11f))
            .clickable(enabled = target != null) { target?.let(onSelect) },
    ) {
        // A full-height rail in the severity colour: the part that reads from across the room.
        Box(Modifier.width(4.dp).fillMaxHeight().background(colour))
        Row(Modifier.weight(1f).padding(horizontal = 11.dp, vertical = 10.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            SymbolIcon(alert.severity.symbolName, colour, 16.dp, Modifier.padding(top = 1.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Label(alert.message, size = 13.sp, weight = FontWeight.SemiBold)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Label(alert.timeLabel, size = 10.sp, weight = FontWeight.Bold, color = Theme.textSecondary)
                    if (target != null) Label("TAP TO SHOW ME", size = 9.sp, weight = FontWeight.ExtraBold, color = Theme.accent)
                }
            }
            if (target != null) SymbolIcon("chevron.right", Theme.textSecondary, 12.dp, Modifier.padding(top = 2.dp))
        }
    }
}

// endregion

// region Park settings

/** Park-wide settings: the gate price, the car park, the colours and the uniform, then the tips and graphics. */
@Composable
fun ParkSettingsSheet(controller: GameController, services: AppServices, onDismiss: () -> Unit) {
    val hud = controller.hud
    val state = controller.state
    var price by remember { mutableStateOf(hud.admissionPrice.toFloat()) }
    val limit = controller.admissionPriceLimit.toFloat()
    var tips by remember { mutableStateOf(controller.tipsEnabled) }

    val acceptable = GuestEconomics.acceptableAdmission(state.attractions.size, state.parkRating)
    val willingness = GuestEconomics.admissionWillingness(hud.admissionPrice, acceptable)
    val advice = when {
        willingness < 0.15 -> "Almost nobody thinks this park is worth the price."
        willingness < 0.4 -> "Most people are turned away by this price."
        willingness < 0.7 -> "A fair price for what the park offers right now."
        else -> "Great value — expect a steady stream of visitors."
    }

    BottomSheet(hud.parkName, onDismiss, tall = true) {
        Label("PARK SETTINGS", size = 10.sp, weight = FontWeight.ExtraBold, color = Theme.textSecondary)

        SectionCard("Admission price") {
            Label(CurrencyFormatter.short(price.toDouble()), size = 34.sp, weight = FontWeight.ExtraBold)
            Slider(
                value = price.coerceIn(0f, limit),
                onValueChange = { price = Math.round(it).toFloat(); controller.setAdmissionPrice(price.toDouble()) },
                valueRange = 0f..limit, steps = maxOf(0, limit.toInt() - 1),
                colors = SliderDefaults.colors(thumbColor = Theme.accent, activeTrackColor = Theme.accent),
            )
            Label(advice, size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
        }

        SectionCard("Car park") {
            val cost = controller.carParkUpgradeCost()
            UpgradeRow(CarParkContent.name(state.carParkLevel), CarParkContent.summary, "car.fill", state.carParkLevel, CarParkContent.maxLevel,
                cost, hud.cash >= (cost ?: 0.0)) { controller.upgradeCarPark() }
        }

        SectionCard("Park colours") {
            Label("MAIN", size = 10.sp, weight = FontWeight.ExtraBold, color = Theme.textSecondary)
            ColourRow(state.scheme.primary) { controller.setSchemePrimary(it) }
            Label("TRIM", size = 10.sp, weight = FontWeight.ExtraBold, color = Theme.textSecondary, modifier = Modifier.padding(top = 4.dp))
            ColourRow(state.scheme.trim) { controller.setSchemeTrim(it) }
            Label(
                "Lamps, benches, bins, picnic tables, flags, arches, fountains and the clock tower are painted in these. Rides and plants keep their own colours.",
                size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary,
            )
        }

        SectionCard("Staff uniform") {
            ColourRow(state.uniformColour) { controller.setUniformColour(it) }
            Label("Every employee wears this. Their hat and their tools still say which job they do.", size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
        }

        SectionCard("Tips") {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Label("Show helpful tips", modifier = Modifier.weight(1f))
                Switch(checked = tips, onCheckedChange = { tips = it; controller.setTipsEnabled(it) })
            }
            Label("Each tip appears once, when the park is in a state it applies to. ${controller.tipsReadText}.", size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
            Label("Show all tips again", size = 12.sp, weight = FontWeight.SemiBold, color = Theme.accent,
                modifier = Modifier.clickable { controller.resetTips() }.padding(vertical = 4.dp))
        }

        SectionCard("Graphics") {
            StatRow("Detail", if (GraphicsBudget.isReduced) "Compatibility" else "Full detail")
            Label("How hard the park works this phone. Nothing here changes the park itself. Change it from the main menu.", size = 12.sp,
                weight = FontWeight.Normal, color = Theme.textSecondary)
        }

        SectionCard("Right now") {
            StatRow("Arrivals", String.format(java.util.Locale.US, "%.1f guests per minute", hud.arrivalsPerMinute))
            StatRow("Guests in park", "${hud.guestCount}")
            StatRow("Park rating", "${hud.parkRating.toInt()} / 100")
        }

        Label("Guests judge the gate price against how much there is to do. Add rides and raise your rating before you raise the price.",
            size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
    }
}

/** A row of swatches. A fixed shortlist, because every colour has to stay legible on a small figure against grass. */
@Composable
private fun ColourRow(selected: ParkColour, onSelect: (ParkColour) -> Unit) {
    val choices = listOf(ParkColour.teal, ParkColour.blue, ParkColour.indigo, ParkColour.violet, ParkColour.red,
        ParkColour.orange, ParkColour.amber, ParkColour.green, ParkColour.charcoal, ParkColour.cream)
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        for (colour in choices) {
            val isSelected = colour == selected
            Box(
                Modifier.size(26.dp).clip(CircleShape).background(ParkPalette.colour(colour).compose())
                    .border(if (isSelected) 3.dp else 1.dp, if (isSelected) Color.White else Color.Black.copy(alpha = 0.15f), CircleShape)
                    .clickable { onSelect(colour) },
            )
        }
    }
}

// endregion

// region Achievements

/** The achievement list: what has been earned, what is next, and how far off it is. */
@Composable
fun AchievementsSheet(controller: GameController, services: AppServices, onDismiss: () -> Unit) {
    val progress = remember { controller.makeAchievementProgress() }
    val medals = services.trialProgress.completed
    val earnedTiers = progress.sumOf { it.earnedTier }
    val totalPaid = progress.sumOf { item -> (1..item.earnedTier).sumOf { item.definition.reward(it) } }

    BottomSheet("Achievements", onDismiss, tall = true) {
        if (!controller.hud.mode.earnsAchievements) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                SymbolIcon("infinity", Theme.textSecondary, 16.dp)
                Label("This park is a free build. Achievements are not awarded.", size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
            }
        }

        SectionCard("Totals") {
            StatRow("Tiers earned", "$earnedTiers of ${AchievementContent.totalTiers}")
            StatRow("Awards paid", CurrencyFormatter.short(totalPaid))
        }

        SectionCard("Park Trials medals") {
            for (trial in TrialContent.all) TrialMedalRow(trial, medals[trial.id])
            Label("Earned by beating each trial on the ladder. Medals belong to you rather than to a park, so they count in every park you play.",
                size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
        }

        SectionCard("Achievements") {
            for (item in progress) AchievementRow(item)
        }
    }
}

@Composable
private fun AchievementRow(item: AchievementProgress) {
    Row(horizontalArrangement = Arrangement.spacedBy(11.dp), modifier = Modifier.padding(vertical = 3.dp)) {
        Box(Modifier.size(28.dp), contentAlignment = Alignment.Center) {
            SymbolIcon(item.definition.symbolName, if (item.earnedTier > 0) Theme.accent else Theme.textSecondary, 18.dp)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                Label(item.definition.name, size = 14.sp, weight = FontWeight.SemiBold, maxLines = 1, modifier = Modifier.weight(1f, fill = false))
                if (item.earnedTier > 0) {
                    Box(Modifier.clip(CircleShape).background(Theme.accent.copy(alpha = 0.22f)).padding(horizontal = 5.dp, vertical = 1.dp)) {
                        Label(AchievementDefinition.tierName(item.earnedTier), size = 10.sp, weight = FontWeight.ExtraBold)
                    }
                }
                Box(Modifier.weight(1f))
                Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                    for (index in 0 until maxOf(item.definition.tierCount, 1)) {
                        Box(Modifier.size(5.dp).clip(CircleShape).background(if (index < item.earnedTier) Theme.accent else Color.White.copy(alpha = 0.25f)))
                    }
                }
            }
            Label(item.definition.summary, size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
            val next = item.nextThreshold
            if (next != null) {
                Box(Modifier.fillMaxWidth().height(4.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.16f))) {
                    Box(Modifier.fillMaxWidth(item.fraction.toFloat().coerceIn(0.01f, 1f)).height(4.dp).clip(CircleShape).background(Theme.accent))
                }
                Row {
                    Label("${item.format(item.current)} of ${item.format(next)}", size = 10.sp, weight = FontWeight.Medium, color = Theme.textSecondary, modifier = Modifier.weight(1f))
                    Label("${CurrencyFormatter.short(item.definition.reward(item.earnedTier + 1))} next", size = 10.sp, weight = FontWeight.Medium, color = Theme.textSecondary)
                }
            } else {
                Label("Every tier earned.", size = 10.sp, weight = FontWeight.Bold, color = Theme.accent)
            }
        }
    }
}

@Composable
private fun TrialMedalRow(trial: TrialDefinition, bestDay: Int?) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(vertical = 2.dp).then(if (bestDay != null) Modifier else Modifier.background(Color.Transparent))) {
        Box(Modifier.size(36.dp).clip(CircleShape).then(if (bestDay != null) Modifier.background(Theme.moneyGradient) else Modifier.background(Color.White.copy(alpha = 0.15f))),
            contentAlignment = Alignment.Center) {
            SymbolIcon(trial.medal.symbolName, if (bestDay != null) Color.Black.copy(alpha = 0.8f) else Theme.textSecondary, 18.dp)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Label(trial.medal.name, size = 14.sp, weight = FontWeight.SemiBold, color = if (bestDay != null) Color.White else Color.White.copy(alpha = 0.7f))
            Label("Trial ${trial.number}: ${trial.title}", size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
        }
        if (bestDay != null) Label("Day $bestDay", size = 12.sp, weight = FontWeight.Bold, color = Theme.textSecondary)
        else SymbolIcon("lock.fill", Theme.textSecondary, 13.dp)
    }
}

// endregion
