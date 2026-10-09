package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wickedstudios.wonderlot.AppInfo
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * The rotating tagline under the title, laid down by a coaster car.
 *
 * A car runs the crest of a hill from left to right and each letter drops into place just behind it, so the line
 * reads as track being laid rather than as text fading in. When the line has been up long enough the whole thing
 * lifts away and the next one is run out.
 */
@Composable
fun Tagline(taglines: List<String> = AppInfo.taglines) {
    var index by remember { mutableIntStateOf(0) }
    // Seconds since this line started to be laid.
    var clock by remember { mutableDoubleStateOf(0.0) }

    val line = taglines[index % taglines.size]
    val run = max(line.length, 1) * LETTER_DELAY
    val exitAt = DWELL + run
    val finishAt = exitAt + line.length * LETTER_DELAY + EXIT_SETTLE + 0.24

    LaunchedEffect(index) {
        clock = 0.0
        var start = -1L
        while (true) {
            androidx.compose.runtime.withFrameNanos { now ->
                if (start < 0) start = now
                clock = (now - start) / 1_000_000_000.0
            }
            if (clock >= finishAt) break
        }
        index = (index + 1) % taglines.size
    }

    val density = LocalDensity.current
    Box(Modifier.height(30.dp).wrapContentWidth(), contentAlignment = Alignment.Center) {
        Row(horizontalArrangement = Arrangement.spacedBy(0.6.dp), verticalAlignment = Alignment.CenterVertically) {
            for ((position, character) in line.withIndex()) {
                val laid = laid(clock, position, exitAt)
                val hill = -ARC * sin(position.toDouble() / max(line.length - 1, 1) * PI)
                if (character == ' ') {
                    Box(Modifier.width(4.dp).height(1.dp))
                } else {
                    Label(
                        character.toString(), size = 12.sp, weight = FontWeight.Bold, color = Color.White.copy(alpha = 0.9f),
                        modifier = Modifier.offset(y = (hill + (1 - laid) * 14).dp).alpha(laid.toFloat().coerceIn(0f, 1f)),
                    )
                }
            }
        }

        // The car runs exactly the width of the line.
        val carSpan = run + 0.3
        val travel = (clock / carSpan).coerceIn(0.0, 1.0)
        if (travel < 1.0) {
            val eased = travel * travel * (3 - 2 * travel)
            Canvas(Modifier.fillMaxSize()) {
                val carLength = CAR_LENGTH.dp.toPx()
                val carHeight = CAR_HEIGHT.dp.toPx()
                val x = -carLength + (size.width + 4.dp.toPx() + carLength) * eased.toFloat()
                val y = size.height / 2 - ARC.dp.toPx() - carHeight
                val fade = (1.0 - eased).toFloat()
                drawRoundRect(Theme.accentWarm.copy(alpha = fade), Offset(x, y), Size(carLength, carHeight), CornerRadius(carHeight / 2))
                drawCircle(Theme.danger.copy(alpha = fade), carHeight / 2, Offset(x + carLength - carHeight / 2, y + carHeight / 2))
                drawCircle(Color.White.copy(alpha = 0.9f * fade), carHeight * 0.21f, Offset(x + carLength * 0.24f + carHeight * 0.21f, y + carHeight / 2 - 1f))
            }
        }
    }
}

/** How far a letter has landed, 0 to 1, with a little overshoot on the way in and a clean lift on the way out. */
private fun laid(clock: Double, position: Int, exitAt: Double): Double {
    val enter = (clock - position * LETTER_DELAY) / 0.5
    val landed = if (enter <= 0) 0.0 else 1 - exp(-7 * enter) * cos(11 * enter)
    val leave = (clock - exitAt - position * LETTER_DELAY) / EXIT_SETTLE
    val lifted = if (leave <= 0) 0.0 else min(1.0, leave)
    return landed.coerceIn(0.0, 1.05) * (1 - lifted)
}

private const val LETTER_DELAY = 0.035
private const val DWELL = 4.6
private const val EXIT_SETTLE = 0.3
private const val ARC = 7f
private const val CAR_LENGTH = 26f
private const val CAR_HEIGHT = 15f
