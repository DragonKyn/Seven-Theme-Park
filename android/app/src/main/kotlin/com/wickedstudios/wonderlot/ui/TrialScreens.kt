package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.activity.compose.BackHandler
import com.wickedstudios.wonderlot.CurrencyFormatter
import com.wickedstudios.wonderlot.PerkBranch
import com.wickedstudios.wonderlot.PerkContent
import com.wickedstudios.wonderlot.PerkDefinition
import com.wickedstudios.wonderlot.TrialContent
import com.wickedstudios.wonderlot.TrialDefinition
import com.wickedstudios.wonderlot.app.AppRouter
import com.wickedstudios.wonderlot.app.AppServices

private sealed class TrialPage {
    data object Ladder : TrialPage()
    class Briefing(val trial: TrialDefinition) : TrialPage()
    data object Perks : TrialPage()
}

/** The Park Trials ladder: parks to build under a deadline, each one opening when the one before it is beaten. */
@Composable
fun TrialLadderScreen(router: AppRouter, services: AppServices, onClose: () -> Unit) {
    var page by remember { mutableStateOf<TrialPage>(TrialPage.Ladder) }
    // Bumped on any change, because the stores read preferences rather than holding observable state.
    var revision by remember { mutableIntStateOf(0) }
    @Suppress("UNUSED_VARIABLE") val observed = revision

    BackHandler {
        when (page) {
            TrialPage.Ladder -> onClose()
            else -> { page = TrialPage.Ladder; router.refreshTrials() }
        }
    }

    Box(Modifier.fillMaxSize().background(Theme.panelGradient)) {
        when (val current = page) {
            TrialPage.Ladder -> Ladder(router, services, onClose, onOpen = { page = TrialPage.Briefing(it) }, onPerks = { page = TrialPage.Perks })
            is TrialPage.Briefing -> Briefing(current.trial, router, onBack = { page = TrialPage.Ladder }, onLeave = onClose)
            TrialPage.Perks -> PerkTree(router, services, onBack = { page = TrialPage.Ladder; revision += 1 }) { revision += 1 }
        }
    }
}

@Composable
private fun TopBar(title: String, trailing: String, onTrailing: () -> Unit) {
    Row(Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Label(title, size = 18.sp, weight = FontWeight.ExtraBold, modifier = Modifier.weight(1f))
        PillButton(trailing, onTrailing, background = Theme.control, foreground = Theme.textPrimary)
    }
}

@Composable
private fun Ladder(router: AppRouter, services: AppServices, onClose: () -> Unit, onOpen: (TrialDefinition) -> Unit, onPerks: () -> Unit) {
    val completed = router.completedTrials.value
    val runs = router.trialRuns.value
    val unspent = services.perkStore.available(completed.size)

    Column(Modifier.fillMaxSize()) {
        TopBar("Park Trials", "Close", onClose)
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp).padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Label("${TrialContent.all.size} parks, each on a deadline.", size = 20.sp, weight = FontWeight.ExtraBold)
                Label("Meet every goal before the last day closes. Each trial you beat earns its medal and opens the next rung.",
                    size = 13.sp, weight = FontWeight.Medium, color = Theme.textSecondary)
                Row(Modifier.padding(top = 4.dp), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    SymbolIcon("rosette", Theme.money, 16.dp)
                    Label("${completed.size} of ${TrialContent.all.size} medals", size = 13.sp, weight = FontWeight.Bold)
                    Box(Modifier.weight(1f).height(6.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.12f))) {
                        Box(Modifier.fillMaxWidth(completed.size.toFloat() / maxOf(1, TrialContent.all.size)).height(6.dp).clip(CircleShape).background(Theme.moneyGradient))
                    }
                }
            }

            // The other half of the ladder: what beating a rung is worth afterwards.
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Color.White.copy(alpha = 0.09f))
                    .border(if (unspent > 0) 2.dp else 1.dp, if (unspent > 0) Theme.money.copy(alpha = 0.6f) else Color.White.copy(alpha = 0.08f), RoundedCornerShape(14.dp))
                    .clickable(onClick = onPerks).padding(12.dp),
                horizontalArrangement = Arrangement.spacedBy(11.dp), verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.size(38.dp).clip(CircleShape).background(Theme.moneyGradient), contentAlignment = Alignment.Center) {
                    SymbolIcon("seal.fill", Color.Black.copy(alpha = 0.85f), 18.dp)
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Label("Park Perks", size = 15.sp, weight = FontWeight.ExtraBold)
                    Label(
                        when {
                            unspent == 0 && completed.isEmpty() -> "Every trial you beat is worth a permanent bonus"
                            unspent == 0 -> "Every point is spent. Move them whenever you like."
                            unspent == 1 -> "1 point waiting to be spent"
                            else -> "$unspent points waiting to be spent"
                        },
                        size = 12.sp, color = Theme.textSecondary,
                    )
                }
                SymbolIcon("chevron.right", Theme.textSecondary, 13.dp)
            }

            for (trial in TrialContent.all) {
                val unlocked = router.isTrialUnlocked(trial)
                RungCard(trial, unlocked, completed[trial.id], runs[trial.id]?.day, Modifier.then(if (unlocked) Modifier.clickable { onOpen(trial) } else Modifier))
            }
        }
    }
}

@Composable
private fun RungCard(trial: TrialDefinition, unlocked: Boolean, bestDay: Int?, runDay: Int?, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(14.dp)
    Box(modifier) {
        Row(
            Modifier.fillMaxWidth().clip(shape).background(Color.White.copy(alpha = if (unlocked) 0.09f else 0.04f))
                .border(if (bestDay != null) 2.dp else 1.dp, if (bestDay != null) Theme.accent.copy(alpha = 0.75f) else Color.White.copy(alpha = 0.08f), shape)
                .padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Box {
                val thumbnail = remember(trial.id) { mapThumbnail(trial.map) }
                Image(thumbnail.asImageBitmap(), null, Modifier.padding(6.dp).size(70.dp).clip(RoundedCornerShape(9.dp)).alpha(if (unlocked) 1f else 0.45f),
                    filterQuality = FilterQuality.None)
                if (bestDay != null) {
                    Box(Modifier.size(24.dp).clip(CircleShape).background(Theme.accent).border(1.5.dp, Color.White.copy(alpha = 0.8f), CircleShape),
                        contentAlignment = Alignment.Center) { SymbolIcon("checkmark", Color.White, 13.dp) }
                } else {
                    Box(Modifier.size(22.dp).clip(CircleShape).background(if (unlocked) Theme.money else Color.White.copy(alpha = 0.5f)), contentAlignment = Alignment.Center) {
                        Label("${trial.number}", size = 12.sp, weight = FontWeight.Black, color = Color.Black.copy(alpha = 0.85f))
                    }
                }
            }

            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Label(trial.title, size = 15.sp, weight = FontWeight.ExtraBold, color = if (unlocked) Color.White else Theme.textSecondary,
                        maxLines = 1, modifier = Modifier.weight(1f))
                    if (unlocked) SymbolIcon("chevron.right", Theme.textSecondary, 12.dp)
                }
                Label(trial.map.name, size = 10.sp, weight = FontWeight.Bold, color = Theme.textSecondary)
                if (unlocked) {
                    for (goal in trial.goals) {
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                            SymbolIcon(goal.symbolName, Color.White.copy(alpha = 0.85f), 12.dp)
                            Label(goal.title, size = 11.sp, weight = FontWeight.Medium, color = Color.White.copy(alpha = 0.85f), maxLines = 1)
                        }
                    }
                    Label("${trial.dayLimit} days  ·  starts with ${CurrencyFormatter.short(trial.startingCash)}", size = 10.sp,
                        weight = FontWeight.SemiBold, color = Theme.textSecondary)
                    bestDay?.let {
                        Label("Completed on day $it  ·  ${trial.medal.name}", size = 11.sp, weight = FontWeight.Bold, color = Theme.accent)
                    }
                    runDay?.let { Label("Park in progress, day $it", size = 11.sp, weight = FontWeight.Bold, color = Theme.accent) }
                } else {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                        SymbolIcon("lock.fill", Theme.textSecondary, 12.dp)
                        Label("Beat trial ${trial.number - 1} to open", size = 11.sp, weight = FontWeight.SemiBold, color = Theme.textSecondary)
                    }
                }
            }
        }
        if (bestDay != null) {
            Box(Modifier.align(Alignment.BottomEnd).padding(end = 10.dp, bottom = 10.dp)) { CompleteStamp() }
        }
    }
}

@Composable
private fun Briefing(trial: TrialDefinition, router: AppRouter, onBack: () -> Unit, onLeave: () -> Unit) {
    val run = router.trialRuns.value[trial.id]
    val bestDay = router.completedTrials.value[trial.id]
    var confirmingRestart by remember { mutableStateOf(false) }

    Column(Modifier.fillMaxSize()) {
        TopBar("Trial ${trial.number}", "Back", onBack)
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 18.dp).padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                val thumbnail = remember(trial.id) { mapThumbnail(trial.map) }
                Image(thumbnail.asImageBitmap(), null, Modifier.widthIn(max = 220.dp).fillMaxWidth().aspectRatio(1f).clip(RoundedCornerShape(14.dp)),
                    filterQuality = FilterQuality.None)
                if (bestDay != null) CompleteStamp(1.6f)
            }

            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Label("TRIAL ${trial.number}  ·  ${trial.map.name.uppercase()}", size = 10.sp, weight = FontWeight.ExtraBold, color = Theme.money)
                Label(trial.title, size = 26.sp, weight = FontWeight.ExtraBold)
                Label(trial.briefing, size = 14.sp, weight = FontWeight.Medium, color = Color.White.copy(alpha = 0.85f))
            }

            InfoSection("GOALS, ALL AT ONCE") {
                for (goal in trial.goals) Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    SymbolIcon(goal.symbolName, Color.White, 16.dp)
                    Label(goal.title, size = 14.sp)
                }
            }

            InfoSection("RULES") {
                Rule("calendar", "Finish by the end of day ${trial.dayLimit}")
                Rule("banknote", "Start with ${CurrencyFormatter.short(trial.startingCash)}")
                trial.maxAdmission?.let { Rule("ticket", "Gate price capped at ${CurrencyFormatter.short(it)}") }
                Rule(trial.medal.symbolName, "Medal: ${trial.medal.name}")
            }

            bestDay?.let {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    SymbolIcon(trial.medal.symbolName, Theme.money, 16.dp)
                    Label("Medal earned. Best finish: day $it.", size = 13.sp, weight = FontWeight.Bold, color = Theme.money)
                }
            }

            if (run != null) {
                BigButton("Resume, day ${run.day}", "play.fill") { onLeave(); router.resumeTrial(trial) }
                Box(Modifier.fillMaxWidth().height(42.dp).clip(RoundedCornerShape(12.dp)).background(Color.White.copy(alpha = 0.12f))
                    .clickable { confirmingRestart = true }, contentAlignment = Alignment.Center) {
                    Label("Start over from day one", size = 14.sp, weight = FontWeight.Bold)
                }
            } else {
                BigButton(if (bestDay == null) "Begin trial" else "Play again", "flag.checkered") { onLeave(); router.startTrial(trial) }
            }

            Label("Trials keep their own saves. They never use one of your three park slots.", size = 11.sp, weight = FontWeight.Medium,
                color = Theme.textSecondary, modifier = Modifier.fillMaxWidth())
        }
    }

    if (confirmingRestart) {
        ConfirmDialog("Start this trial over?",
            "The park you have on day ${run?.day ?: 1} is replaced with a fresh one. Medals you have earned are kept.",
            "Start over", destructive = true,
            onConfirm = { confirmingRestart = false; onLeave(); router.startTrial(trial) }, onDismiss = { confirmingRestart = false })
    }
}

@Composable
private fun BigButton(title: String, symbol: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().height(50.dp).clip(RoundedCornerShape(14.dp)).background(Theme.moneyGradient).clickable(onClick = onClick),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically,
    ) {
        SymbolIcon(symbol, Color.Black.copy(alpha = 0.88f), 18.dp)
        Label(title, size = 17.sp, weight = FontWeight.ExtraBold, color = Color.Black.copy(alpha = 0.88f))
    }
}

@Composable
private fun InfoSection(title: String, content: @Composable () -> Unit) {
    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Color.White.copy(alpha = 0.08f)).padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Label(title, size = 10.sp, weight = FontWeight.ExtraBold, color = Theme.textSecondary)
        content()
    }
}

@Composable
private fun Rule(symbol: String, text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
        SymbolIcon(symbol, Color.White.copy(alpha = 0.9f), 15.dp)
        Label(text, size = 13.sp, color = Color.White.copy(alpha = 0.9f))
    }
}

/** A rubber stamp, set at an angle, that says a trial is done. */
@Composable
fun CompleteStamp(scale: Float = 1f) {
    val shape = RoundedCornerShape((6 * scale).dp)
    Row(
        Modifier.rotate(-9f).clip(shape).background(Theme.panelBottom.copy(alpha = 0.85f)).border((2 * scale).dp, Theme.accent, shape)
            .padding(horizontal = (9 * scale).dp, vertical = (4 * scale).dp),
        horizontalArrangement = Arrangement.spacedBy((4 * scale).dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        SymbolIcon("checkmark.seal.fill", Theme.accent, (13 * scale).dp)
        Label("COMPLETE", size = (12 * scale).sp, weight = FontWeight.Black, color = Theme.accent)
    }
}

// region Perk tree

/**
 * Where the points trials pay out get spent. One point per trial beaten, against more ranks than there are points,
 * so two players who beat every trial still end up running different parks.
 */
@Composable
private fun PerkTree(router: AppRouter, services: AppServices, onBack: () -> Unit, onChange: () -> Unit) {
    val store = services.perkStore
    var revision by remember { mutableIntStateOf(0) }
    @Suppress("UNUSED_VARIABLE") val observed = revision
    var confirmingReset by remember { mutableStateOf(false) }
    val medals = router.completedTrials.value.size
    val available = store.available(medals)

    Column(Modifier.fillMaxSize()) {
        TopBar("Park Perks", "Done", onBack)
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp).padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(46.dp).clip(CircleShape).then(if (available > 0) Modifier.background(Theme.moneyGradient) else Modifier.background(Theme.control)),
                        contentAlignment = Alignment.Center) {
                        Label("$available", size = 20.sp, weight = FontWeight.Black, color = if (available > 0) Color.Black.copy(alpha = 0.85f) else Theme.textSecondary)
                    }
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Label(if (available == 1) "1 point to spend" else "$available points to spend", size = 17.sp, weight = FontWeight.ExtraBold)
                        Label("$medals of ${TrialContent.all.size} trials beaten  ·  ${store.spent} spent", size = 12.sp, weight = FontWeight.SemiBold, color = Theme.textSecondary)
                    }
                }
                Label(
                    if (medals == 0) "Every trial you beat is worth one point. Beat the first one and this fills up."
                    else "These apply to every park you build, in every mode. Move them about as often as you like.",
                    size = 13.sp, weight = FontWeight.Medium, color = Theme.textSecondary,
                )
            }

            for (branch in PerkBranch.entries) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(7.dp), verticalAlignment = Alignment.CenterVertically) {
                        SymbolIcon(branch.symbolName, Theme.accentWarm, 14.dp)
                        Label(branch.displayName.uppercase(), size = 11.sp, weight = FontWeight.ExtraBold, color = Theme.accentWarm, modifier = Modifier.weight(1f))
                        Label("${store.spent(branch)} spent here", size = 10.sp, weight = FontWeight.Bold, color = Theme.textSecondary)
                    }
                    Label(branch.summary, size = 12.sp, weight = FontWeight.Medium, color = Theme.textSecondary)
                    for (perk in PerkContent.inBranch(branch)) {
                        PerkRow(perk, store.rank(perk),
                            locked = store.spent(perk.branch) < perk.requires && store.rank(perk) == 0,
                            canBuy = store.canSpend(perk, medals), canRefund = store.canRefund(perk),
                            onSpend = { store.spend(perk, medals); revision += 1; onChange() },
                            onRefund = { store.refund(perk); revision += 1; onChange() })
                    }
                }
            }

            Box(Modifier.fillMaxWidth().height(40.dp).clip(RoundedCornerShape(11.dp)).background(Color.White.copy(alpha = 0.10f))
                .clickable(enabled = store.spent > 0) { confirmingReset = true }, contentAlignment = Alignment.Center) {
                Label("Take every point back", size = 13.sp, weight = FontWeight.Bold, color = if (store.spent > 0) Color.White else Theme.textSecondary)
            }
        }
    }

    if (confirmingReset) {
        ConfirmDialog("Take every point back?", "Your medals are kept. Only where the points are spent changes.", "Take them all back", destructive = true,
            onConfirm = { store.reset(); confirmingReset = false; revision += 1; onChange() }, onDismiss = { confirmingReset = false })
    }
}

@Composable
private fun PerkRow(perk: PerkDefinition, rank: Int, locked: Boolean, canBuy: Boolean, canRefund: Boolean, onSpend: () -> Unit, onRefund: () -> Unit) {
    val shape = RoundedCornerShape(13.dp)
    Column(
        Modifier.fillMaxWidth().clip(shape).background(Color.White.copy(alpha = if (locked) 0.04f else 0.08f))
            .border(if (rank > 0) 1.5.dp else 1.dp, if (rank > 0) Theme.accent.copy(alpha = 0.55f) else Color.White.copy(alpha = 0.07f), shape)
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(9.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            SymbolIcon(if (locked) "lock.fill" else perk.symbolName, if (rank > 0) Theme.accent else Theme.textSecondary, 17.dp, Modifier.padding(top = 2.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Label(perk.displayName, size = 15.sp, weight = FontWeight.ExtraBold, color = if (locked) Theme.textSecondary else Color.White)
                Label(
                    if (locked) "Opens once ${perk.requires} points are spent in ${perk.branch.displayName.lowercase()}." else perk.summary(rank),
                    size = 12.sp, weight = FontWeight.Medium, color = Theme.textSecondary,
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(3.dp), modifier = Modifier.padding(top = 4.dp)) {
                for (index in 0 until perk.maxRank) {
                    Box(Modifier.size(8.dp).clip(CircleShape).background(if (index < rank) Theme.accent else Color.White.copy(alpha = 0.18f)))
                }
            }
        }
        if (!locked) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Box(Modifier.weight(1f).height(34.dp).clip(RoundedCornerShape(9.dp))
                    .then(if (canBuy) Modifier.background(Theme.moneyGradient) else Modifier.background(Theme.control))
                    .clickable(enabled = canBuy, onClick = onSpend), contentAlignment = Alignment.Center) {
                    Label(if (rank == perk.maxRank) "Full" else "Spend a point", size = 12.sp, weight = FontWeight.ExtraBold,
                        color = if (canBuy) Color.Black.copy(alpha = 0.85f) else Theme.textSecondary)
                }
                Box(Modifier.weight(1f).height(34.dp).clip(RoundedCornerShape(9.dp)).background(Color.White.copy(alpha = if (canRefund) 0.14f else 0.06f))
                    .clickable(enabled = canRefund, onClick = onRefund), contentAlignment = Alignment.Center) {
                    Label("Take back", size = 12.sp, weight = FontWeight.ExtraBold, color = if (canRefund) Color.White else Theme.textSecondary)
                }
            }
        }
    }
}

// endregion
