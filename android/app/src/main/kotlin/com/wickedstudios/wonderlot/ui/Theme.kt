package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.wickedstudios.wonderlot.gfx.UIColor

/**
 * Shared visual language for the interface. The park itself is bright, so the
 * panels over it are a lit blue-slate rather than near-black: dark enough to
 * read white text against grass, light enough to look part of the same game.
 */
object Theme {
    val panelTop = Color(0.20f, 0.27f, 0.38f)
    val panelBottom = Color(0.12f, 0.17f, 0.25f)
    val panel = Color(0.16f, 0.22f, 0.32f, 0.95f)
    val panelRaised = Color(0.24f, 0.31f, 0.42f)
    val panelStroke = Color.White.copy(alpha = 0.16f)
    val control = Color.White.copy(alpha = 0.14f)
    val controlRaised = Color.White.copy(alpha = 0.24f)

    val accent = Color(0.20f, 0.78f, 0.55f)
    val accentWarm = Color(1.00f, 0.72f, 0.28f)
    val danger = Color(0.95f, 0.40f, 0.36f)
    val textPrimary = Color.White
    val textSecondary = Color.White.copy(alpha = 0.70f)

    val money = Color(1.00f, 0.82f, 0.35f)
    val moneyDeep = Color(0.96f, 0.63f, 0.16f)
    val profit = Color(0.38f, 0.88f, 0.55f)
    val loss = Color(0.98f, 0.48f, 0.42f)

    val moneyGradient = Brush.verticalGradient(listOf(money, moneyDeep))
    val panelGradient = Brush.verticalGradient(listOf(panelTop, panelBottom))

    fun profitColour(amount: Double): Color = if (amount < 0) loss else profit

    val cornerRadius = 14.dp

    fun happinessColour(value: Double): Color = when {
        value < 40 -> danger
        value < 70 -> accentWarm
        else -> accent
    }

    /** Needs read "100 is bad", so the colour ramp runs the other way. */
    fun needColour(value: Double): Color = when {
        value < 50 -> accent
        value < 80 -> accentWarm
        else -> danger
    }
}

fun Modifier.panelBackground(cornerRadius: Dp = Theme.cornerRadius): Modifier {
    val shape = RoundedCornerShape(cornerRadius)
    return this
        .shadow(8.dp, shape, ambientColor = Color.Black.copy(alpha = 0.35f), spotColor = Color.Black.copy(alpha = 0.35f))
        .background(Theme.panelGradient, shape)
        .border(BorderStroke(1.dp, Theme.panelStroke), shape)
}

/** Converts a game colour into a Compose colour. */
fun UIColor.compose(): Color = Color(argb)
