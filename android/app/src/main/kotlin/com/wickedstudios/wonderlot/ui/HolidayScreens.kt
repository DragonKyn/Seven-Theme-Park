package com.wickedstudios.wonderlot.ui

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wickedstudios.wonderlot.HolidayRewards
import com.wickedstudios.wonderlot.HolidaySeason
import com.wickedstudios.wonderlot.TrialContent
import com.wickedstudios.wonderlot.TrialDefinition
import com.wickedstudios.wonderlot.app.AppRouter
import com.wickedstudios.wonderlot.app.AppServices
import kotlin.math.PI
import kotlin.math.sin

/** Christmas red and pine green, for everything festive. */
object Festive {
    val red = Color(0.86f, 0.18f, 0.22f)
    val green = Color(0.20f, 0.62f, 0.38f)
    val gold = Color(1.0f, 0.82f, 0.28f)
    val snow = Color(0.97f, 0.98f, 1.0f)
    val bulbs = listOf(Color(0.92f, 0.23f, 0.22f), Color(1.0f, 0.78f, 0.22f), Color(0.28f, 0.78f, 0.42f), Color(0.35f, 0.72f, 0.96f))
    val ribbon: Brush get() = Brush.horizontalGradient(listOf(red, Color(0.62f, 0.10f, 0.16f)))
}

/** Snow drifting down over a whole screen. Cheap: a few dozen circles at positions worked out from the clock. */
@Composable
fun SnowOverlay(modifier: Modifier = Modifier, flakes: Int = 90) {
    val transition = rememberInfiniteTransition(label = "snow")
    val clock by transition.animateFloat(0f, 1000f, infiniteRepeatable(tween(1_000_000, easing = LinearEasing), RepeatMode.Restart), label = "t")
    Canvas(modifier.fillMaxSize()) {
        for (index in 0 until flakes) {
            val a = fract(sin(index * 12.9898) * 43758.5453)
            val b = fract(sin((index * 2 + 2) * 12.9898) * 43758.5453)
            val c = fract(sin((index * 3 + 7) * 12.9898) * 43758.5453)
            val speed = (24 + c * 40) * density
            val sway = sin(clock * (0.5 + c) + index) * 14 * density
            val x = (((a * size.width + sway) % size.width) + size.width) % size.width
            val y = (b * size.height + clock * speed) % size.height
            drawCircle(Festive.snow.copy(alpha = (0.55f + c.toFloat() * 0.35f)), ((1.1 + c * 2.2) * density).toFloat(), Offset(x.toFloat(), y.toFloat()))
        }
    }
}

private fun fract(x: Double): Double = x - kotlin.math.floor(x)

/** A string of coloured lights hanging in a shallow curve across the width. */
@Composable
fun FestiveLights(modifier: Modifier = Modifier) {
    val transition = rememberInfiniteTransition(label = "twinkle")
    val twinkle by transition.animateFloat(0f, 1f, infiniteRepeatable(tween(1400, easing = LinearEasing), RepeatMode.Reverse), label = "tw")
    Canvas(modifier.fillMaxWidth().height(34.dp)) {
        val bulbCount = 13
        val wire = androidx.compose.ui.graphics.Path()
        wire.moveTo(0f, 2f * density)
        wire.quadraticBezierTo(size.width / 2, 26f * density, size.width, 2f * density)
        drawPath(wire, Color(0f, 0f, 0f, 0.55f), style = androidx.compose.ui.graphics.drawscope.Stroke(1.5f * density))
        for (index in 0 until bulbCount) {
            val t = (index + 0.5f) / bulbCount
            val x = size.width * t
            val y = (2f + 24f * 2f * t * (1 - t)) * density
            val lit = if (index % 2 == 0) 0.55f + 0.45f * twinkle else 1f - 0.45f * twinkle
            drawCircle(Festive.bulbs[index % Festive.bulbs.size].copy(alpha = lit), 4.5f * density, Offset(x, y + 4f * density))
        }
    }
}

/** The ribbon under the title during the event. */
@Composable
fun HolidayRibbon(modifier: Modifier = Modifier) {
    Row(
        modifier.clip(CircleShape).background(Festive.ribbon).border(1.dp, Color.White.copy(alpha = 0.45f), CircleShape).padding(horizontal = 12.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        SymbolIcon("snowflake", Color.White, 13.dp)
        Label("HOLIDAY WONDER  ·  ${HolidaySeason.shortDatesLabel.uppercase()}", size = 10.sp, weight = FontWeight.ExtraBold, tracking = 1.2f, color = Color.White, maxLines = 1)
    }
}

/** What the holiday rewards a trial hands over, as a short list. */
@Composable
fun HolidayRewardList(rewardIDs: List<String>) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        for (id in rewardIDs) {
            val reward = HolidayRewards.definition(id) ?: continue
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(30.dp).clip(CircleShape).background(Festive.red), contentAlignment = Alignment.Center) {
                    SymbolIcon(reward.symbolName, Color.White, 16.dp)
                }
                Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
                    Label(reward.title, size = 13.sp, weight = FontWeight.Bold)
                    Label(reward.detail, size = 11.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
                }
            }
        }
    }
}

/** The twelve days: every trial in the event, with what each one is worth. */
@Composable
fun HolidayLadder(router: AppRouter, services: AppServices, onOpen: (TrialDefinition) -> Unit) {
    val holiday = services.holiday
    val runs = router.trialRuns.value
    val done = holiday.completedCount()

    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            HolidayRibbon()
            Label("12 Days of Holiday Wonder", size = 20.sp, weight = FontWeight.ExtraBold)
            Label("Twelve parks to build before ${HolidaySeason.datesLabel.substringAfter("to ")}. Every one is open from the first day, and each hands over something for the season: decorations, ride makeovers, rides and a new performer.",
                size = 13.sp, weight = FontWeight.Medium, color = Theme.textSecondary)
            Row(Modifier.padding(top = 4.dp), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                SymbolIcon("gift.fill", Festive.gold, 16.dp)
                Label("$done of ${TrialContent.holiday.size} days done this year", size = 13.sp, weight = FontWeight.Bold)
                Box(Modifier.weight(1f).height(6.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.12f))) {
                    Box(Modifier.fillMaxWidth(done.toFloat() / TrialContent.holiday.size).height(6.dp).clip(CircleShape).background(Festive.ribbon))
                }
            }
        }

        for (trial in TrialContent.holiday) {
            val open = holiday.isOpen(trial)
            val completed = holiday.isCompleted(trial)
            val run = runs[trial.id]
            val shape = RoundedCornerShape(14.dp)
            Column(
                Modifier.fillMaxWidth().clip(shape).background(Color.White.copy(alpha = if (open) 0.09f else 0.04f))
                    .border(if (completed) 2.dp else 1.dp, if (completed) Festive.green else Color.White.copy(alpha = 0.08f), shape)
                    .then(if (open) Modifier.clickable { onOpen(trial) } else Modifier).padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(34.dp).clip(CircleShape).background(if (completed) Festive.green else if (open) Festive.red else Color.White.copy(alpha = 0.25f)),
                        contentAlignment = Alignment.Center) {
                        if (completed) SymbolIcon("checkmark", Color.White, 16.dp)
                        else Label("${trial.number}", size = 14.sp, weight = FontWeight.Black, color = Color.White)
                    }
                    Column(Modifier.weight(1f)) {
                        Label("DAY ${trial.number}", size = 9.sp, weight = FontWeight.ExtraBold, tracking = 1.6f, color = Festive.gold)
                        Label(trial.title, size = 15.sp, weight = FontWeight.ExtraBold, color = if (open) Color.White else Theme.textSecondary, maxLines = 1)
                    }
                    if (open) SymbolIcon("chevron.right", Theme.textSecondary, 12.dp)
                }
                if (open) {
                    for (goal in trial.goals) {
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                            SymbolIcon(goal.symbolName, Color.White.copy(alpha = 0.85f), 12.dp)
                            Label(goal.title, size = 11.sp, weight = FontWeight.Medium, color = Color.White.copy(alpha = 0.85f), maxLines = 1)
                        }
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                        SymbolIcon("gift.fill", Festive.gold, 12.dp)
                        Label("Reward: " + trial.rewardIDs.mapNotNull { HolidayRewards.definition(it)?.title }.joinToString(", "),
                            size = 11.sp, weight = FontWeight.Bold, color = Festive.gold, maxLines = 2)
                    }
                    if (completed) Label("Done this year  ·  ${trial.medal.name}", size = 11.sp, weight = FontWeight.Bold, color = Festive.green)
                    run?.let { Label("Park in progress, day ${it.day}", size = 11.sp, weight = FontWeight.Bold, color = Theme.accent) }
                } else {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                        SymbolIcon("lock.fill", Theme.textSecondary, 12.dp)
                        val needed = trial.needsRewardID?.let { HolidayRewards.definition(it)?.title }
                        Label("Earn ${needed ?: "an earlier reward"} to open", size = 11.sp, weight = FontWeight.SemiBold, color = Theme.textSecondary)
                    }
                }
            }
        }
    }
}

/**
 * The announcement on the main menu while the event is on. Shown at each launch until the player ticks the box, which
 * puts it away until next year's event.
 */
@Composable
fun HolidayAnnouncement(services: AppServices, onDismiss: () -> Unit, onSeeTrials: () -> Unit) {
    var hideUntilNextYear by remember { mutableStateOf(false) }
    fun close(then: () -> Unit) {
        if (hideUntilNextYear) services.holiday.hideAnnouncement()
        onDismiss()
        then()
    }

    androidx.activity.compose.BackHandler { close {} }
    run {
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.6f)).clickable(
            interactionSource = remember { androidx.compose.foundation.interaction.MutableInteractionSource() }, indication = null) { close {} },
            contentAlignment = Alignment.Center) {
            val shape = RoundedCornerShape(22.dp)
            Column(
                Modifier.padding(horizontal = 22.dp).widthIn(max = 380.dp).clip(shape).background(Theme.panelGradient)
                    .border(1.5.dp, Festive.gold.copy(alpha = 0.7f), shape)
                    .clickable(interactionSource = remember { androidx.compose.foundation.interaction.MutableInteractionSource() }, indication = null) {},
            ) {
                // A red banner with lights, snow falling over the card.
                Box(Modifier.fillMaxWidth().background(Festive.ribbon).padding(top = 14.dp, bottom = 10.dp), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Label("THE HOLIDAY EVENT", size = 10.sp, weight = FontWeight.ExtraBold, tracking = 3f, color = Color.White.copy(alpha = 0.85f))
                        androidx.compose.material3.Text("Holiday Wonder", color = Color.White, fontSize = 28.sp, fontWeight = FontWeight.ExtraBold, textAlign = TextAlign.Center)
                    }
                }
                FestiveLights(Modifier.padding(horizontal = 6.dp))

                Column(Modifier.verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(bottom = 18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Color.White.copy(alpha = 0.10f)).padding(10.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically) {
                        SymbolIcon("calendar", Festive.gold, 16.dp)
                        Label("${HolidaySeason.datesLabel}  ·  ${HolidaySeason.daysLeft()} days left", size = 13.sp, weight = FontWeight.ExtraBold, color = Festive.gold)
                    }

                    announcementRow("snowflake", "11 new rides", "Seven Christmas rides and four for New Year's, from the Reindeer Carousel to the Ball Drop Tower.")
                    announcementRow("person.fill", "Santa and Mrs. Claus", "Two new entertainers, each with a bonus of their own.")
                    announcementRow("gift.fill", "12 Days of Holiday Wonder", "Twelve festive trials with a tab of their own in Park Trials.")
                    announcementRow("paintbrush.fill", "Exclusive rewards", "Earn decorations, ride makeovers and new rides, and keep them for every future holiday.")
                    announcementRow("party.popper.fill", "Company holiday parties", "Big office outings arrive by the busload with five times the spending money.")
                    Label("Snow is falling, the ground is white, and it all ends on January 5. Come and play.", size = 12.sp, weight = FontWeight.Medium,
                        color = Theme.textSecondary, modifier = Modifier.fillMaxWidth())

                    Row(Modifier.clickable { hideUntilNextYear = !hideUntilNextYear }.padding(vertical = 2.dp), horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(22.dp).clip(RoundedCornerShape(6.dp)).background(if (hideUntilNextYear) Festive.green else Color.White.copy(alpha = 0.12f))
                            .border(1.dp, Color.White.copy(alpha = 0.35f), RoundedCornerShape(6.dp)), contentAlignment = Alignment.Center) {
                            if (hideUntilNextYear) SymbolIcon("checkmark", Color.White, 14.dp)
                        }
                        Label("Don't show this again until next year", size = 13.sp, weight = FontWeight.SemiBold)
                    }

                    Row(Modifier.fillMaxWidth().height(48.dp).clip(RoundedCornerShape(14.dp)).background(Festive.ribbon).clickable { close(onSeeTrials) },
                        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically) {
                        SymbolIcon("gift.fill", Color.White, 18.dp)
                        Label("See the 12 Days", size = 16.sp, weight = FontWeight.ExtraBold, color = Color.White)
                    }
                    Box(Modifier.fillMaxWidth().height(42.dp).clip(RoundedCornerShape(12.dp)).background(Color.White.copy(alpha = 0.12f)).clickable { close {} },
                        contentAlignment = Alignment.Center) { Label("Let's play", size = 14.sp, weight = FontWeight.Bold) }
                }
            }
            SnowOverlay(Modifier.fillMaxSize(), flakes = 60)
        }
    }
}

@Composable
private fun announcementRow(symbol: String, title: String, detail: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.Top) {
        Box(Modifier.size(30.dp).clip(CircleShape).background(Festive.red), contentAlignment = Alignment.Center) { SymbolIcon(symbol, Color.White, 16.dp) }
        Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Label(title, size = 14.sp, weight = FontWeight.ExtraBold)
            Label(detail, size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
        }
    }
}

@Suppress("unused")
private val keepPi = PI
