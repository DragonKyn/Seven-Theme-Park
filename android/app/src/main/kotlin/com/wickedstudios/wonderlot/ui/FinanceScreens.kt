package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wickedstudios.wonderlot.CurrencyFormatter
import com.wickedstudios.wonderlot.FinancePoint
import com.wickedstudios.wonderlot.FinanceRange
import com.wickedstudios.wonderlot.FinanceSeriesKind
import com.wickedstudios.wonderlot.GameController
import kotlin.math.max
import kotlin.math.min

/** The colours the money graph is drawn in. */
object FinanceChartPalette {
    fun colour(series: FinanceSeriesKind): Color = when (series) {
        FinanceSeriesKind.profit -> Color(0.13f, 0.64f, 0.36f)
        FinanceSeriesKind.revenue -> Color(0.82f, 0.58f, 0.10f)
        FinanceSeriesKind.expenses -> Color(0.85f, 0.29f, 0.26f)
        FinanceSeriesKind.wages -> Color(0.55f, 0.62f, 0.95f)
        FinanceSeriesKind.maintenance -> Color(0.98f, 0.62f, 0.30f)
        FinanceSeriesKind.inventory -> Color(0.45f, 0.82f, 0.85f)
        FinanceSeriesKind.construction -> Color(0.83f, 0.60f, 0.95f)
        FinanceSeriesKind.utilities -> Color(0.75f, 0.78f, 0.82f)
    }

    /** Profit last, so its thicker line is drawn over the rest. */
    fun ordered(visible: Set<FinanceSeriesKind>): List<FinanceSeriesKind> =
        FinanceSeriesKind.entries.filter { it in visible }.sortedWith { a, b ->
            when {
                a == FinanceSeriesKind.profit -> 1
                b == FinanceSeriesKind.profit -> -1
                else -> a.name.compareTo(b.name)
            }
        }

    fun lineWidth(series: FinanceSeriesKind): Float = if (series == FinanceSeriesKind.profit) 2.8f else 1.6f

    /** At most six labels along the bottom, however many columns there are. */
    fun axisIndices(points: List<FinancePoint>): List<Int> {
        if (points.size <= 1) return points.map { it.id }
        val step = max(1, points.size / 6)
        return points.map { it.id }.filter { it % step == 0 }
    }
}

/** The park's money over time: profit thick with the ground shaded under it, the rest behind it. */
@Composable
private fun FinanceChart(points: List<FinancePoint>, visible: Set<FinanceSeriesKind>) {
    val labelColour = Theme.textSecondary

    Canvas(Modifier.fillMaxWidth().height(190.dp)) {
        val density = this.density
        val leftGutter = 40f * density
        val bottomGutter = 16f * density
        val topInset = 6f * density
        val plotLeft = leftGutter
        val plotTop = topInset
        val plotWidth = max(1f, size.width - leftGutter - 4f * density)
        val plotHeight = max(1f, size.height - topInset - bottomGutter)
        val plotBottom = plotTop + plotHeight

        // Every visible number, and always zero, so break-even is on the chart.
        var lowest = 0.0
        var highest = 0.0
        for (series in FinanceChartPalette.ordered(visible)) for (point in points) {
            val value = series.amount(point)
            lowest = min(lowest, value)
            highest = max(highest, value)
        }
        if (highest - lowest < 1) highest = lowest + 1
        val padding = (highest - lowest) * 0.08
        val low = lowest - padding
        val high = highest + padding

        fun x(index: Int): Float = if (points.size > 1) plotLeft + index * (plotWidth / (points.size - 1)) else plotLeft + plotWidth / 2
        fun y(value: Double): Float = plotBottom - ((value - low) / (high - low)).toFloat() * plotHeight

        // Grid.
        for (step in 0..4) {
            val value = low + (high - low) * step / 4
            val position = y(value)
            drawLine(labelColour.copy(alpha = 0.25f), Offset(plotLeft, position), Offset(plotLeft + plotWidth, position), 1f)
        }
        // Break-even, so a line below it is unmistakably a loss.
        drawLine(labelColour.copy(alpha = 0.6f), Offset(plotLeft, y(0.0)), Offset(plotLeft + plotWidth, y(0.0)), 1f,
            pathEffect = PathEffect.dashPathEffect(floatArrayOf(6f, 6f)))

        if (points.size > 1) {
            if (FinanceSeriesKind.profit in visible) {
                val area = Path()
                area.moveTo(x(0), y(0.0))
                for ((index, point) in points.withIndex()) area.lineTo(x(index), y(point.profit))
                area.lineTo(x(points.size - 1), y(0.0))
                area.close()
                val colour = FinanceChartPalette.colour(FinanceSeriesKind.profit)
                drawPath(area, Brush.verticalGradient(listOf(colour.copy(alpha = 0.28f), colour.copy(alpha = 0.02f)), plotTop, plotBottom))
            }
            for (series in FinanceChartPalette.ordered(visible)) {
                val path = Path()
                for ((index, point) in points.withIndex()) {
                    val px = x(index)
                    val py = y(series.amount(point))
                    if (index == 0) path.moveTo(px, py) else path.lineTo(px, py)
                }
                drawPath(path, FinanceChartPalette.colour(series),
                    style = Stroke(FinanceChartPalette.lineWidth(series) * density, cap = StrokeCap.Round, join = StrokeJoin.Round))
            }
        }

        // Labels.
        val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
            color = labelColour.hashCode().let { android.graphics.Color.argb(200, 255, 255, 255) }
            textSize = 9f * density
        }
        paint.textAlign = android.graphics.Paint.Align.RIGHT
        for (step in 0..4) {
            val value = low + (high - low) * step / 4
            drawContext.canvas.nativeCanvas.drawText(CurrencyFormatter.compact(value), plotLeft - 5f * density, y(value) + 3f * density, paint)
        }
        paint.textAlign = android.graphics.Paint.Align.CENTER
        val wanted = FinanceChartPalette.axisIndices(points).toSet()
        for ((index, point) in points.withIndex()) {
            if (point.id in wanted) drawContext.canvas.nativeCanvas.drawText(point.shortLabel, x(index), plotBottom + 12f * density, paint)
        }
    }
}

@Composable
fun FinanceSheet(controller: GameController, onDismiss: () -> Unit) {
    var range by remember { mutableStateOf(FinanceRange.today) }
    var visible by remember { mutableStateOf(setOf(FinanceSeriesKind.profit, FinanceSeriesKind.revenue, FinanceSeriesKind.expenses)) }
    val snapshot = controller.makeFinanceSnapshot()
    val points = controller.makeFinanceSeries(range)

    BottomSheet("Finances", onDismiss, tall = true) {
        SectionCard("Trend") {
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                for (option in FinanceRange.entries) Chip(option.displayName, range == option, { range = option })
            }
            if (points.size < 2) {
                Column(Modifier.fillMaxWidth().height(130.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                    SymbolIcon("chart.line.uptrend.xyaxis", Theme.textSecondary, 26.dp)
                    Label("The books are filed once an hour. Come back after the park has been open a while.", size = 12.sp,
                        weight = FontWeight.Normal, color = Theme.textSecondary, modifier = Modifier.padding(top = 6.dp))
                }
            } else {
                FinanceChart(points, visible)
            }

            for (group in listOf(FinanceSeriesKind.entries.filter { it.isHeadline }, FinanceSeriesKind.entries.filter { !it.isHeadline })) {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    for (option in group) {
                        val on = option in visible
                        Row(
                            Modifier.height(26.dp).clip(CircleShape)
                                .background(if (on) FinanceChartPalette.colour(option).copy(alpha = 0.30f) else Theme.control)
                                .clickable { visible = if (on) visible - option else visible + option }.padding(horizontal = 9.dp),
                            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp),
                        ) {
                            Box(Modifier.size(7.dp).clip(CircleShape).background(FinanceChartPalette.colour(option)))
                            Label(option.displayName, size = 11.sp, color = if (on) Theme.textPrimary else Theme.textSecondary)
                        }
                    }
                }
            }
        }

        SectionCard("Today") {
            summaryRow("Revenue", snapshot.todayTotalRevenue, Theme.profit)
            summaryRow("Expenses", snapshot.todayTotalExpenses, Theme.loss)
            summaryRow("Profit", snapshot.todayProfit, Theme.profitColour(snapshot.todayProfit))
            snapshot.yesterdayProfit?.let { summaryRow("Yesterday", it, Theme.profitColour(it)) }
        }

        SectionCard("Today - revenue") { for (line in snapshot.todayRevenue) StatRow(line.label, CurrencyFormatter.exact(line.amount)) }
        SectionCard("Today - expenses") { for (line in snapshot.todayExpenses) StatRow(line.label, CurrencyFormatter.exact(line.amount)) }

        SectionCard("Lifetime") {
            summaryRow("Total revenue", snapshot.lifetimeTotalRevenue, Theme.profit)
            summaryRow("Total expenses", snapshot.lifetimeTotalExpenses, Theme.loss)
            summaryRow("Total profit", snapshot.lifetimeProfit, Theme.profitColour(snapshot.lifetimeProfit))
        }

        SectionCard("Lifetime breakdown") {
            for (line in snapshot.lifetimeRevenue) StatRow(line.label, CurrencyFormatter.short(line.amount))
            for (line in snapshot.lifetimeExpenses) StatRow(line.label, CurrencyFormatter.short(line.amount))
        }
    }
}

@Composable
private fun summaryRow(label: String, value: Double, tint: Color) {
    StatRow(label, CurrencyFormatter.signed(value), tint = tint)
}

/** The management dashboard: everything the player needs to diagnose why the park is doing well or badly. */
@Composable
fun ManagementSheet(controller: GameController, onDismiss: () -> Unit) {
    val snapshot = controller.makeDashboardSnapshot()

    BottomSheet("Management", onDismiss, tall = true) {
        SectionCard("Overview") {
            StatRow("Cash", CurrencyFormatter.short(snapshot.cash))
            StatRow("Guests in park", "${snapshot.guestCount}")
            StatRow("Park rating", "${snapshot.parkRating.toInt()} / 100  (${snapshot.starRating} stars)")
            StatRow("Profit today", CurrencyFormatter.signed(snapshot.todayProfit))
            StatRow("Arrivals", String.format(java.util.Locale.US, "%.1f per minute", snapshot.arrivalsPerMinute))
        }
        SectionCard("Guests") {
            StatRow("Average happiness", "${snapshot.averageHappiness.toInt()}%")
            StatRow("Average hunger", "${snapshot.averageHunger.toInt()}")
            StatRow("Average thirst", "${snapshot.averageThirst.toInt()}")
            StatRow("Average energy", "${snapshot.averageEnergy.toInt()}")
            StatRow("Common complaint", snapshot.commonComplaint ?: "None yet")
        }
        SectionCard("Attractions") {
            StatRow("Total rides", "${snapshot.attractionCount}")
            StatRow("Closed rides", "${snapshot.closedAttractions}")
            StatRow("Average queue", String.format(java.util.Locale.US, "%.1f", snapshot.averageQueueLength))
            StatRow("Most popular", snapshot.mostPopular ?: "No data")
            snapshot.leastPopular?.let { StatRow("Least popular", it) }
            StatRow("Facilities", "${snapshot.facilityCount}")
        }
        SectionCard("Upkeep and looks") {
            StatRow("Park cleanliness", "${(snapshot.cleanliness * 100).toInt()}%")
            StatRow("Littered tiles", "${snapshot.litteredTiles}")
            StatRow("Decoration", "${(snapshot.beauty * 100).toInt()}%")
            StatRow("Scenery placed", "${snapshot.sceneryCount}")
            StatRow("Broken rides", "${snapshot.brokenRides}")
        }
        SectionCard("Staff") {
            StatRow("Employees", "${snapshot.staffCount}")
            StatRow("Wages per day", CurrencyFormatter.short(snapshot.dailyPayroll))
            StatRow("Currently on a task", "${snapshot.staffOnTask}")
            for (entry in snapshot.staffByRole) StatRow(entry.id, "${entry.count}")
        }
        SectionCard("Rating breakdown") {
            for (line in snapshot.ratingLines) {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Row { Label(line.id, size = 13.sp, modifier = Modifier.weight(1f)); Label("${(line.value * 100).toInt()}%", size = 13.sp) }
                    MeterBar("Weight ${(line.weight * 100).toInt()}%", line.value * 100,
                        if (line.value > 0.6) Theme.accent else if (line.value > 0.35) Theme.accentWarm else Theme.danger)
                }
            }
            Label("Weights are normalised over the components listed, so the score always spans the full 0-100 range.", size = 10.sp,
                weight = FontWeight.Normal, color = Theme.textSecondary)
        }
        SectionCard("Finance") {
            StatRow("Revenue today", CurrencyFormatter.short(snapshot.finance.todayTotalRevenue))
            StatRow("Expenses today", CurrencyFormatter.short(snapshot.finance.todayTotalExpenses))
            StatRow("Lifetime profit", CurrencyFormatter.signed(snapshot.finance.lifetimeProfit))
        }
    }
}
