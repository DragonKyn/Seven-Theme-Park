package com.wickedstudios.wonderlot.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wickedstudios.wonderlot.AchievementAward
import com.wickedstudios.wonderlot.CurrencyFormatter
import com.wickedstudios.wonderlot.GameController
import com.wickedstudios.wonderlot.ParkEvent
import com.wickedstudios.wonderlot.TrialOutcome
import com.wickedstudios.wonderlot.TrialResultReport
import com.wickedstudios.wonderlot.TrialSnapshot
import com.wickedstudios.wonderlot.TutorialTip
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

// region Tips

/**
 * A piece of advice, shown once, under the readouts at the top of the screen.
 * Deliberately not a modal: the park keeps running behind it and every control stays live.
 */
@Composable
fun TutorialTipCard(tip: TutorialTip, onDismiss: () -> Unit, onTurnOff: () -> Unit) {
    val shape = RoundedCornerShape(Theme.cornerRadius)
    Row(
        Modifier.fillMaxWidth().panelBackground().border(BorderStroke(1.5.dp, Theme.accentWarm.copy(alpha = 0.55f)), shape).padding(12.dp),
        horizontalArrangement = Arrangement.spacedBy(11.dp),
    ) {
        Box(Modifier.size(38.dp).clip(CircleShape).background(Theme.moneyGradient).border(1.5.dp, Color.White.copy(alpha = 0.5f), CircleShape),
            contentAlignment = Alignment.Center) { SymbolIcon(tip.symbolName, Color.Black.copy(alpha = 0.82f), 19.dp) }

        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Label("TIP", size = 8.sp, weight = FontWeight.ExtraBold, tracking = 2.2f, color = Theme.accentWarm)
            Label(tip.title, size = 15.sp, weight = FontWeight.ExtraBold)
            Label(tip.message, size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(top = 2.dp)) {
                PillButton("Got it", onDismiss)
                PillButton("Turn tips off", onTurnOff, background = Theme.control, foreground = Theme.textSecondary)
            }
        }
    }
}

// endregion

// region Trial tracker

/** The trial's goals, under the HUD, while a trial park is running. */
@Composable
fun TrialTracker(trial: TrialSnapshot, expanded: Boolean, onToggle: () -> Unit) {
    val statusColour = when (trial.outcome) {
        TrialOutcome.won -> Theme.money
        TrialOutcome.lost -> Theme.danger
        TrialOutcome.inProgress -> if (trial.daysLeft <= 1) Theme.accentWarm else Theme.accent
    }
    val statusSymbol = when (trial.outcome) {
        TrialOutcome.won -> "rosette"
        TrialOutcome.lost -> "hourglass.bottomhalf.filled"
        TrialOutcome.inProgress -> "flag.checkered"
    }
    val statusLine = when (trial.outcome) {
        TrialOutcome.won -> "Complete on day ${trial.decidedDay}. Keep building."
        TrialOutcome.lost -> "Out of time. The park is yours to keep."
        TrialOutcome.inProgress -> {
            val days = if (trial.daysLeft == 0) "Last day" else "${trial.daysLeft} day${if (trial.daysLeft == 1) "" else "s"} left"
            "$days  ·  ${trial.metCount} of ${trial.goals.size} goals met"
        }
    }

    Column(Modifier.fillMaxWidth().panelBackground().padding(horizontal = 10.dp, vertical = 8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.clickable(onClick = onToggle), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Box(Modifier.size(24.dp).clip(CircleShape).background(statusColour.copy(alpha = 0.18f)), contentAlignment = Alignment.Center) {
                SymbolIcon(statusSymbol, statusColour, 13.dp)
            }
            Column(Modifier.weight(1f)) {
                Label("TRIAL ${trial.number}  ·  ${trial.title.uppercase()}", size = 9.sp, weight = FontWeight.ExtraBold, tracking = 1f, color = Theme.textSecondary, maxLines = 1)
                Label(statusLine, size = 12.sp, weight = FontWeight.Bold, maxLines = 1)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                for (goal in trial.goals) Box(Modifier.size(7.dp).clip(CircleShape).background(if (goal.isMet) Theme.accent else Color.White.copy(alpha = 0.22f)))
            }
            SymbolIcon(if (expanded) "chevron.up" else "chevron.down", Theme.textSecondary, 12.dp)
        }

        if (expanded) {
            for (goal in trial.goals) {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                        SymbolIcon(if (goal.isMet) "checkmark.circle.fill" else goal.symbolName, if (goal.isMet) Theme.accent else Theme.textSecondary, 13.dp)
                        Label(goal.title, size = 11.sp, maxLines = 1, modifier = Modifier.weight(1f))
                        Label("${goal.currentText} / ${goal.targetText}", size = 11.sp, weight = FontWeight.ExtraBold,
                            color = if (goal.isMet) Theme.accent else Theme.textPrimary)
                    }
                    Box(Modifier.fillMaxWidth().height(4.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.12f))) {
                        Box(Modifier.fillMaxWidth(goal.fraction.toFloat().coerceIn(0.0f, 1f)).height(4.dp).clip(CircleShape)
                            .background(if (goal.isMet) Theme.accent else Theme.accentWarm))
                    }
                }
            }
        }
    }
}

// endregion

// region Event cards

private class EventFigure(val value: String, val caption: String)

private sealed class Banner {
    data object None : Banner()
    class Incident(val title: String) : Banner()
    class Destination(val text: String) : Banner()
    class Stamp(val title: String, val passed: Boolean) : Banner()
}

private class EventPresentation(
    val banner: Banner,
    val symbolName: String,
    val tint: Color,
    val deepTint: Color,
    val kicker: String,
    val headline: String,
    val detail: String,
    val figures: List<EventFigure>,
)

private val deepGreen = Color(0.10f, 0.48f, 0.36f)
private val deepRed = Color(0.62f, 0.16f, 0.20f)

private fun presentation(event: ParkEvent): EventPresentation = when (event) {
    is ParkEvent.Promotion -> EventPresentation(
        Banner.None, "iphone.gen3.radiowaves.left.and.right", Color(0.98f, 0.55f, 0.78f), Color(0.62f, 0.36f, 0.92f),
        "GOING VIRAL", event.post.guestName, "posted about ${event.post.rideName}",
        listOf(EventFigure("+${(event.post.boost * 100).toInt()}%", "ARRIVALS"), EventFigure(event.post.durationLabel, "FOR THE NEXT")),
    )

    is ParkEvent.Ejection -> {
        val report = event.report
        EventPresentation(
            Banner.Incident(if (report.wasEscorted) "INCIDENT CLOSED" else "INCIDENT LOGGED"),
            if (report.wasEscorted) "shield.lefthalf.filled" else "shield.slash.fill",
            if (report.wasEscorted) Theme.accent else Theme.danger,
            if (report.wasEscorted) deepGreen else deepRed,
            "PARK SECURITY",
            if (report.wasEscorted) "Your security team escorted out a troublemaker" else "A troublemaker walked out unchallenged",
            report.detail,
            listOf(EventFigure("${report.litterDropped}", "RUBBISH DROPPED"), EventFigure(report.durationLabel, "ON SITE"),
                EventFigure(if (report.wasEscorted) "REMOVED" else "NO COVER", "OUTCOME")),
        )
    }

    is ParkEvent.Review -> {
        val review = event.review
        EventPresentation(
            Banner.None, if (review.isBad) "hand.thumbsdown.fill" else "star.bubble.fill",
            if (review.isBad) Theme.danger else Theme.money, if (review.isBad) deepRed else Theme.moneyDeep,
            "${review.starLine}   REVIEWED", review.headline, review.detail,
            if (review.ratingSwing == 0.0) listOf(EventFigure(review.criticName, "LEFT BY"))
            else listOf(EventFigure("${if (review.ratingSwing > 0) "+" else ""}${review.ratingSwing.toInt()}", "PARK RATING"),
                EventFigure(review.durationLabel, "FOR THE NEXT")),
        )
    }

    is ParkEvent.Inspection -> {
        val report = event.report
        EventPresentation(
            Banner.Stamp(if (report.passed) "CERTIFICATE ISSUED" else "PROHIBITION NOTICE", report.passed),
            if (report.passed) "checkmark.seal.fill" else "xmark.seal.fill",
            if (report.passed) Theme.accent else Theme.danger, if (report.passed) deepGreen else deepRed,
            "SAFETY INSPECTION", report.headline, report.detail,
            if (report.passed) listOf(EventFigure("${report.condition.toInt()}%", "CONDITION"), EventFigure("+${report.bonus.toInt()}", "PARK RATING"),
                EventFigure(report.durationLabel, "FOR THE NEXT"))
            else listOf(EventFigure("${report.condition.toInt()}%", "CONDITION"), EventFigure(CurrencyFormatter.compact(report.fine), "FINE"),
                EventFigure("CLOSED", "UNTIL REPAIRED")),
        )
    }

    is ParkEvent.TourBus -> {
        val report = event.report
        EventPresentation(
            Banner.Destination(report.groupName), "bus.doubledecker.fill", Theme.money, Theme.moneyDeep,
            "TOUR BUS ARRIVING", report.headline, report.detail,
            listOf(EventFigure("${report.count}", "ON BOARD"), EventFigure("${report.childCount}", "CHILDREN"),
                EventFigure("${report.count - report.childCount}", "ADULTS")),
        )
    }
}

/** The card that appears when something happens in the park that the player did not cause. */
@Composable
fun EventCard(event: ParkEvent, remaining: Double, onDismiss: () -> Unit) {
    val style = remember(event.id) { presentation(event) }
    val shown = remember(event.id) { Animatable(0f) }
    LaunchedEffect(event.id) { shown.animateTo(1f, spring(dampingRatio = 0.64f, stiffness = Spring.StiffnessMediumLow)) }

    Box(
        Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.32f * shown.value))
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onDismiss),
        contentAlignment = Alignment.Center,
    ) {
        val shape = RoundedCornerShape(20.dp)
        Column(
            Modifier.widthIn(max = 310.dp).graphicsLayer { scaleX = 0.75f + 0.25f * shown.value; scaleY = scaleX; alpha = shown.value.coerceIn(0f, 1f) }
                .clip(shape).background(Theme.panelGradient).border(1.5.dp, style.tint.copy(alpha = 0.6f), shape).clickable(onClick = onDismiss),
        ) {
            EventBanner(style.banner)

            Column(Modifier.padding(start = 20.dp, end = 20.dp, top = 16.dp, bottom = 14.dp), horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Box(Modifier.size(62.dp).clip(CircleShape).background(Brush.linearGradient(listOf(style.tint, style.deepTint)))
                    .border(2.dp, Color.White.copy(alpha = 0.5f), CircleShape), contentAlignment = Alignment.Center) {
                    SymbolIcon(style.symbolName, Color.White, 28.dp)
                }
                Label(style.kicker, size = 9.sp, weight = FontWeight.ExtraBold, tracking = 2.4f, color = style.tint)
                Text21(style.headline)
                Label(style.detail, size = 13.sp, color = Color.White.copy(alpha = 0.85f), modifier = Modifier.fillMaxWidth())
                if (style.figures.isNotEmpty()) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        for (figure in style.figures) {
                            Column(Modifier.weight(1f).clip(RoundedCornerShape(10.dp)).background(Color.White.copy(alpha = 0.10f)).padding(vertical = 8.dp),
                                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                Label(figure.value, size = 16.sp, weight = FontWeight.ExtraBold, color = style.tint, maxLines = 1)
                                Label(figure.caption, size = 8.sp, weight = FontWeight.ExtraBold, tracking = 1.2f, color = Color.White.copy(alpha = 0.6f))
                            }
                        }
                    }
                }
                Label("Tap to carry on", size = 10.sp, color = Color.White.copy(alpha = 0.45f))
            }

            // How long is left. A card with a bar running down feels like a decision the player can beat by tapping.
            Box(Modifier.fillMaxWidth().height(3.dp).background(Color.White.copy(alpha = 0.10f))) {
                Box(Modifier.fillMaxWidth(max(0.0, min(1.0, remaining)).toFloat()).height(3.dp).background(style.tint.copy(alpha = 0.75f)))
            }
        }
    }
}

@Composable
private fun Text21(text: String) {
    androidx.compose.material3.Text(text, color = Color.White, fontSize = 21.sp, fontWeight = FontWeight.ExtraBold, textAlign = TextAlign.Center)
}

@Composable
private fun EventBanner(banner: Banner) {
    when (banner) {
        is Banner.None -> {}

        is Banner.Incident -> Box(Modifier.fillMaxWidth().height(34.dp), contentAlignment = Alignment.Center) {
            Canvas(Modifier.fillMaxSize()) {
                drawRect(Theme.accentWarm.copy(alpha = 0.30f), size = size)
                val width = 12.dp.toPx()
                val step = width * 2
                var x = -size.height
                while (x < size.width + size.height) {
                    val stripe = Path()
                    stripe.moveTo(x, size.height)
                    stripe.lineTo(x + size.height, 0f)
                    stripe.lineTo(x + size.height + width, 0f)
                    stripe.lineTo(x + width, size.height)
                    stripe.close()
                    drawPath(stripe, Theme.accentWarm.copy(alpha = 0.55f))
                    x += step
                }
            }
            Box(Modifier.clip(CircleShape).background(Color.Black.copy(alpha = 0.72f)).padding(horizontal = 12.dp, vertical = 3.dp)) {
                Label(banner.title, size = 10.sp, weight = FontWeight.Black, tracking = 3f, color = Color.White)
            }
        }

        is Banner.Destination -> Column {
            Box(Modifier.fillMaxWidth().background(Color.Black.copy(alpha = 0.80f)).padding(vertical = 9.dp), contentAlignment = Alignment.Center) {
                androidx.compose.material3.Text(banner.text.uppercase(), color = Theme.money, fontSize = 13.sp, fontWeight = FontWeight.ExtraBold,
                    fontFamily = FontFamily.Monospace, letterSpacing = 2.sp, maxLines = 1)
            }
            Box(Modifier.fillMaxWidth().height(2.dp).background(Theme.moneyDeep.copy(alpha = 0.8f)))
        }

        is Banner.Stamp -> {
            val colour = if (banner.passed) Theme.accent else Theme.danger
            Column {
                Box(Modifier.fillMaxWidth().background(colour.copy(alpha = 0.18f)).padding(vertical = 9.dp), contentAlignment = Alignment.Center) {
                    Label(banner.title, size = 10.sp, weight = FontWeight.Black, tracking = 3f, color = colour)
                }
                Box(Modifier.fillMaxWidth().height(2.dp).background(colour.copy(alpha = 0.55f)))
            }
        }
    }
}

// endregion

// region Achievement celebration

/** The party popper that goes off when an achievement tier is earned. */
@Composable
fun CelebrationCard(award: AchievementAward, onDismiss: () -> Unit) {
    val cardIn = remember(award.id) { Animatable(0f) }
    val burst = remember(award.id) { Animatable(0f) }
    LaunchedEffect(award.id) {
        cardIn.animateTo(1f, spring(dampingRatio = 0.62f, stiffness = Spring.StiffnessMediumLow))
    }
    LaunchedEffect(award.id) { burst.animateTo(1f, tween(1900, easing = FastOutSlowInEasing)) }

    Box(
        Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.28f * cardIn.value))
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onDismiss),
        contentAlignment = Alignment.Center,
    ) {
        Confetti(burst.value)

        val shape = RoundedCornerShape(22.dp)
        Column(
            Modifier.padding(horizontal = 40.dp).graphicsLayer { scaleX = 0.7f + 0.3f * cardIn.value; scaleY = scaleX; alpha = cardIn.value.coerceIn(0f, 1f) }
                .clip(shape).background(Theme.panelGradient).border(1.5.dp, Theme.accentWarm.copy(alpha = 0.55f), shape)
                .padding(horizontal = 26.dp, vertical = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(9.dp),
        ) {
            Box(Modifier.size(62.dp).clip(CircleShape).background(Theme.moneyGradient).border(2.dp, Color.White.copy(alpha = 0.55f), CircleShape),
                contentAlignment = Alignment.Center) { SymbolIcon(award.symbolName, Color.Black.copy(alpha = 0.82f), 32.dp) }
            Label("ACHIEVEMENT UNLOCKED", size = 9.sp, weight = FontWeight.ExtraBold, tracking = 2.4f, color = Theme.accentWarm)
            androidx.compose.material3.Text(award.name, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, textAlign = TextAlign.Center)
            Box(Modifier.clip(CircleShape).background(Color.White.copy(alpha = 0.12f)).padding(horizontal = 9.dp, vertical = 2.dp)) {
                Label("Tier ${award.tierName}", size = 12.sp, weight = FontWeight.ExtraBold, color = Color.White.copy(alpha = 0.8f))
            }
            // What was actually achieved. The name alone does not say.
            androidx.compose.material3.Text(award.accomplishment, color = Theme.accent, fontSize = 14.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
            androidx.compose.material3.Text(award.summary, color = Color.White.copy(alpha = 0.62f), fontSize = 11.sp, textAlign = TextAlign.Center)
            award.nextTarget?.let { Label("Next: $it", size = 10.sp, color = Color.White.copy(alpha = 0.45f)) }
            Box(Modifier.clip(CircleShape).background(Theme.moneyGradient).padding(horizontal = 14.dp, vertical = 6.dp)) {
                Label("${CurrencyFormatter.short(award.reward)} awarded", size = 13.sp, weight = FontWeight.ExtraBold, color = Color.Black.copy(alpha = 0.85f))
            }
        }
    }
}

/** Paper thrown up and out from behind the card, then falling. The pieces are fixed so the burst is the same every time. */
@Composable
private fun Confetti(progress: Float) {
    val palette = listOf(Theme.money, Theme.accent, Theme.accentWarm, Theme.danger, Color(0.45f, 0.70f, 0.98f), Color(0.80f, 0.55f, 0.95f))
    Canvas(Modifier.fillMaxSize()) {
        val density = this.density
        val centre = Offset(size.width / 2, size.height / 2)
        for (index in 0 until 44) {
            val delay = (index % 7) * 0.035f
            val local = ((progress - delay) / (1f - delay)).coerceIn(0f, 1f)
            if (local <= 0f) continue
            val angle = index * 2.39996f
            val reach = 120f + ((index * 37) % 130)
            val dx = cos(angle) * reach * density
            val dy = (sin(angle) * reach * 0.75f + ((index * 53) % 180)) * density
            val spin = ((index * 71) % 720) - 360f
            val pieceWidth = (5f + (index % 4) * 2.5f) * density
            val eased = 1f - (1f - local) * (1f - local)
            val position = Offset(centre.x + dx * eased, centre.y + dy * eased)
            val pieceAlpha = 1f - local
            graphicsLayerRotate(position, spin * eased) {
                drawRect(palette[index % palette.size].copy(alpha = pieceAlpha), position - Offset(pieceWidth / 2, pieceWidth * 0.85f),
                    Size(pieceWidth, pieceWidth * 1.7f))
            }
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.graphicsLayerRotate(pivot: Offset, degrees: Float, draw: () -> Unit) {
    rotate(degrees, pivot) { draw() }
}

// endregion

// region Trial result

@Composable
fun TrialResultCard(report: TrialResultReport, onKeepPlaying: () -> Unit, onLeave: () -> Unit) {
    val shown = remember { Animatable(0f) }
    LaunchedEffect(Unit) { shown.animateTo(1f, spring(dampingRatio = 0.66f, stiffness = Spring.StiffnessMediumLow)) }

    val trial = report.result.trial
    val won = report.result.won
    val number = trial?.number ?: 0
    val medalSymbol = trial?.medal?.symbolName ?: "rosette"
    val detail = if (won) {
        val limit = trial?.dayLimit ?: report.result.day
        val spare = max(0, limit - report.result.day)
        if (spare > 0) "Every goal met on day ${report.result.day}, with $spare day${if (spare == 1) "" else "s"} to spare."
        else "Every goal met on day ${report.result.day}, right at the wire."
    } else "Day ${report.result.day} closed with goals still short. Try again from the ladder, or keep this park as a sandbox."
    val medalLine = if (won && report.isFirstWin) trial?.let { "Achievement: ${it.medal.name}" } else null
    val unlockLine = if (won && report.isFirstWin) report.nextTrial?.let { "Unlocked: Trial ${it.number}, ${it.title}" } else null
    val accent = if (won) Theme.money else Theme.danger

    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.55f * shown.value)), contentAlignment = Alignment.Center) {
        val shape = RoundedCornerShape(22.dp)
        Column(
            Modifier.padding(horizontal = 24.dp).widthIn(max = 340.dp)
                .graphicsLayer { scaleX = 0.8f + 0.2f * shown.value; scaleY = scaleX; alpha = shown.value.coerceIn(0f, 1f) }
                .clip(shape).background(Theme.panelGradient).border(1.5.dp, accent.copy(alpha = 0.6f), shape).padding(22.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Box(Modifier.size(84.dp).clip(CircleShape).background(if (won) Theme.moneyGradient else Brush.linearGradient(listOf(Color.White.copy(alpha = 0.12f), Color.White.copy(alpha = 0.12f))))
                .border(2.dp, Color.White.copy(alpha = 0.5f), CircleShape), contentAlignment = Alignment.Center) {
                SymbolIcon(if (won) medalSymbol else "hourglass.bottomhalf.filled", if (won) Color.Black.copy(alpha = 0.8f) else Theme.danger, 36.dp)
            }
            Label(if (won) "TRIAL $number COMPLETE" else "TRIAL $number · OUT OF TIME", size = 10.sp, weight = FontWeight.ExtraBold, tracking = 2.2f, color = accent)
            androidx.compose.material3.Text(trial?.title ?: "Trial", color = Color.White, fontSize = 24.sp, fontWeight = FontWeight.ExtraBold, textAlign = TextAlign.Center)
            androidx.compose.material3.Text(detail, color = Color.White.copy(alpha = 0.82f), fontSize = 13.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)

            medalLine?.let {
                Row(Modifier.clip(CircleShape).background(Theme.moneyGradient).padding(horizontal = 12.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
                    SymbolIcon("rosette", Color.Black.copy(alpha = 0.85f), 14.dp)
                    Label(it, size = 12.sp, weight = FontWeight.Bold, color = Color.Black.copy(alpha = 0.85f))
                }
            }
            unlockLine?.let {
                Row(horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
                    SymbolIcon("lock.open.fill", Theme.accent, 14.dp)
                    Label(it, size = 12.sp, weight = FontWeight.Bold, color = Theme.accent)
                }
            }

            Box(Modifier.fillMaxWidth().height(44.dp).clip(RoundedCornerShape(12.dp)).background(Theme.moneyGradient).clickable(onClick = onLeave),
                contentAlignment = Alignment.Center) {
                Label(if (won) "Back to the ladder" else "Back to the menu", size = 15.sp, weight = FontWeight.ExtraBold, color = Color.Black.copy(alpha = 0.88f))
            }
            Box(Modifier.fillMaxWidth().height(40.dp).clip(RoundedCornerShape(12.dp)).background(Color.White.copy(alpha = 0.12f)).clickable(onClick = onKeepPlaying),
                contentAlignment = Alignment.Center) { Label("Keep playing this park", size = 14.sp, weight = FontWeight.Bold) }
        }
    }
}

// endregion

@Suppress("unused")
private val keep = Pair(LinearEasing, GameController::class)
