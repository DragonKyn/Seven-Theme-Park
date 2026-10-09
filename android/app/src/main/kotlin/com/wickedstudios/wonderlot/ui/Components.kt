package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wickedstudios.wonderlot.CurrencyFormatter

/** A rounded-bold label, which is what the whole interface is set in. */
@Composable
fun Label(
    text: String,
    modifier: Modifier = Modifier,
    size: TextUnit = 13.sp,
    weight: FontWeight = FontWeight.SemiBold,
    color: Color = Theme.textPrimary,
    maxLines: Int = Int.MAX_VALUE,
) {
    Text(text, modifier = modifier, fontSize = size, fontWeight = weight, color = color, maxLines = maxLines,
        overflow = TextOverflow.Ellipsis)
}

/** Cash on hand, with the day's profit under it. Deliberately the loudest thing on the screen. */
@Composable
fun MoneyPill(cash: Double, todayProfit: Double, isUnlimited: Boolean, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .clip(CircleShape)
            .background(Theme.moneyGradient)
            .border(BorderStroke(1.dp, Color.White.copy(alpha = 0.45f)), CircleShape)
            .padding(horizontal = 10.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        SymbolIcon(if (isUnlimited) "infinity" else "banknote.fill", Color.Black.copy(alpha = 0.72f), 15.dp)
        Column {
            Text(
                if (isUnlimited) "Unlimited" else CurrencyFormatter.short(cash),
                fontSize = 15.sp, fontWeight = FontWeight.ExtraBold, color = Color.Black, maxLines = 1,
            )
            Text(
                if (isUnlimited) "Free build" else "${CurrencyFormatter.delta(todayProfit)} today",
                fontSize = 9.sp, fontWeight = FontWeight.Bold, maxLines = 1,
                color = if (todayProfit < 0) Color(0.52f, 0.09f, 0.06f) else Color.Black.copy(alpha = 0.62f),
            )
        }
    }
}

/** Compact labelled value used across the HUD. */
@Composable
fun StatPill(symbol: String, value: String, modifier: Modifier = Modifier, tint: Color = Theme.textPrimary) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .background(Theme.control)
            .padding(horizontal = 8.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        SymbolIcon(symbol, tint, 13.dp)
        Label(value, size = 13.sp, maxLines = 1)
    }
}

/** Label on the left, value on the right. */
@Composable
fun StatRow(label: String, value: String, modifier: Modifier = Modifier, tint: Color = Theme.textPrimary) {
    Row(modifier = modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Label(label, size = 13.sp, weight = FontWeight.Normal, color = Theme.textSecondary, modifier = Modifier.weight(1f))
        Spacer(Modifier.width(12.dp))
        Label(value, size = 13.sp, color = tint)
    }
}

/** Horizontal 0-100 bar for guest needs. */
@Composable
fun MeterBar(label: String, value: Double, tint: Color, modifier: Modifier = Modifier) {
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Row {
            Label(label, size = 11.sp, weight = FontWeight.Normal, color = Theme.textSecondary, modifier = Modifier.weight(1f))
            Label("${value.toInt()}", size = 11.sp)
        }
        Box(Modifier.fillMaxWidth().height(6.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.16f))) {
            val fraction = (value / 100).coerceIn(0.02, 1.0).toFloat()
            Box(Modifier.fillMaxWidth(fraction).height(6.dp).clip(CircleShape).background(tint))
        }
    }
}

@Composable
fun StarRating(stars: Int, modifier: Modifier = Modifier) {
    Row(modifier = modifier, horizontalArrangement = Arrangement.spacedBy(1.dp)) {
        for (index in 1..5) {
            SymbolIcon("star.fill", if (index <= stars) Theme.accentWarm else Color.White.copy(alpha = 0.3f), 10.dp)
        }
    }
}

/** Titled card used inside the inspectors and dashboards. */
@Composable
fun SectionCard(title: String, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(Color.White.copy(alpha = 0.09f))
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Label(title.uppercase(), size = 11.sp, weight = FontWeight.Bold, color = Theme.textSecondary)
        content()
    }
}

/** An icon-over-label button, as used on the control bar. 40 by 42, like the iOS one; [scale] shrinks it on a narrow screen. */
@Composable
fun ControlButton(symbol: String, title: String, onClick: () -> Unit, modifier: Modifier = Modifier,
                  highlighted: Boolean = false, tint: Color? = null, scale: Float = 1f) {
    Column(
        modifier = modifier
            .size(width = (40 * scale).dp, height = 42.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(if (highlighted) Theme.accentWarm else Theme.control)
            .clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp, Alignment.CenterVertically),
    ) {
        SymbolIcon(symbol, if (highlighted) Color.Black else (tint ?: Theme.textPrimary), 15.dp)
        Text(title, fontSize = 8.sp, fontWeight = FontWeight.SemiBold, maxLines = 1,
            color = if (highlighted) Color.Black else Theme.textPrimary)
    }
}

/** A filled pill button. */
@Composable
fun PillButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    background: Color = Theme.accent,
    foreground: Color = Color.Black,
    symbol: String? = null,
) {
    Row(
        modifier = modifier
            .clip(CircleShape)
            .background(if (enabled) background else Color.White.copy(alpha = 0.12f))
            .then(if (enabled) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(horizontal = 14.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterHorizontally),
    ) {
        if (symbol != null) SymbolIcon(symbol, if (enabled) foreground else Theme.textSecondary, 14.dp)
        Label(text, size = 13.sp, weight = FontWeight.Bold, color = if (enabled) foreground else Theme.textSecondary, maxLines = 1)
    }
}

/** A small round-cornered chip, selected or not. */
@Composable
fun Chip(text: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier, symbol: String? = null) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(10.dp))
            .background(if (selected) Theme.accent else Theme.control)
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        if (symbol != null) SymbolIcon(symbol, if (selected) Color.Black else Theme.textPrimary, 13.dp)
        Label(text, size = 12.sp, weight = FontWeight.Bold, color = if (selected) Color.Black else Theme.textPrimary, maxLines = 1)
    }
}

/** A swatch of a park colour, ringed when chosen. */
@Composable
fun ColourSwatch(colour: Color, selected: Boolean, onClick: () -> Unit, size: Dp = 28.dp) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(colour)
            .border(BorderStroke(if (selected) 3.dp else 1.dp, if (selected) Color.White else Color.Black.copy(alpha = 0.3f)), CircleShape)
            .clickable(onClick = onClick),
    )
}
