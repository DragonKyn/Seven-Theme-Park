package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wickedstudios.wonderlot.AttractionDefinition
import com.wickedstudios.wonderlot.BuildCategory
import com.wickedstudios.wonderlot.BuildableDefinition
import com.wickedstudios.wonderlot.CoasterElementDefinition
import com.wickedstudios.wonderlot.CurrencyFormatter
import com.wickedstudios.wonderlot.GameController
import com.wickedstudios.wonderlot.RideGroup
import com.wickedstudios.wonderlot.TerrainDefinition
import com.wickedstudios.wonderlot.gfx.BuildingArtwork
import com.wickedstudios.wonderlot.gfx.CGSize
import com.wickedstudios.wonderlot.gfx.CoasterElementArtwork
import com.wickedstudios.wonderlot.gfx.ParkPalette
import com.wickedstudios.wonderlot.gfx.TerrainArtwork

/** Category tabs plus the placeable items in the chosen category. */
@Composable
fun BuildMenu(controller: GameController) {
    val pending = controller.pendingDefinition
    if (pending != null) {
        Box(Modifier.fillMaxWidth().panelBackground().padding(10.dp)) { PlacementConfirmBar(controller, pending) }
    } else {
        Catalogue(controller)
    }
}

@Composable
private fun Catalogue(controller: GameController) {
    val build = controller.build
    val items = controller.buildables(build.category)

    Column(
        modifier = Modifier.fillMaxWidth().panelBackground().padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(9.dp),
    ) {
        ToolRow(controller, items.size)
        CategoryGrid(controller)

        if (!build.isDemolishing && build.category == BuildCategory.attraction) RideGroups(controller)
        if (!build.isDemolishing) ItemStrip(controller, items)
        if (!build.isDemolishing && (controller.styleCount > 1 || controller.canTurnSelection)) StyleChips(controller)
        if (!build.isDemolishing && controller.colourChoices.isNotEmpty()) ColourChips(controller)

        val hintIsError = build.ghost != null && !build.ghostValid
        Label(hintText(controller), size = 11.sp, weight = FontWeight.Normal,
            color = if (hintIsError) Theme.danger else Theme.textSecondary)
    }
}

/** The heading, and the two things that are not categories. */
@Composable
private fun ToolRow(controller: GameController, itemCount: Int) {
    val build = controller.build
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Label(
            if (build.isDemolishing) "REMOVING" else build.category.displayName.uppercase(),
            size = 10.sp, weight = FontWeight.ExtraBold,
            color = if (build.isDemolishing) Theme.danger else Theme.textSecondary,
        )
        if (!build.isDemolishing && itemCount > 0) {
            Box(Modifier.clip(CircleShape).background(Theme.control).padding(horizontal = 5.dp, vertical = 1.dp)) {
                Label("$itemCount", size = 9.sp, weight = FontWeight.ExtraBold, color = Theme.textSecondary)
            }
        }
        Box(Modifier.weight(1f))

        if (controller.canDraw) {
            ToolChip("Draw", if (build.isDrawing) "hand.draw.fill" else "hand.draw", build.isDrawing,
                Theme.accentWarm, Theme.textPrimary) { controller.toggleDrawing() }
        }
        // Red at rest as well as when active, so the one destructive control never reads as another category.
        ToolChip("Remove", "trash.fill", build.isDemolishing, Theme.danger, Theme.danger) { controller.enterDemolishMode() }
    }
}

@Composable
private fun ToolChip(title: String, symbol: String, active: Boolean, activeTint: Color, restTint: Color, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .height(28.dp)
            .clip(CircleShape)
            .background(if (active) activeTint else Theme.control)
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        SymbolIcon(symbol, if (active) Color.Black else restTint, 13.dp)
        Label(title, size = 11.sp, weight = FontWeight.Bold, color = if (active) Color.Black else restTint)
    }
}

/** Every category, named, on screen at once: four across and two down. */
@Composable
private fun CategoryGrid(controller: GameController) {
    val rows = BuildCategory.entries.chunked(4)
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        for (row in rows) {
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                for (category in row) {
                    val selected = !controller.build.isDemolishing && controller.build.category == category
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .height(42.dp)
                            .clip(RoundedCornerShape(9.dp))
                            .background(if (selected) Theme.accent else Theme.control)
                            .clickable { controller.enterBuildMode(category) },
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center,
                    ) {
                        SymbolIcon(category.symbolName, if (selected) Color.Black else Theme.textPrimary, 16.dp)
                        Label(category.shortName, size = 9.sp, weight = FontWeight.Bold,
                            color = if (selected) Color.Black else Theme.textPrimary, maxLines = 1)
                    }
                }
            }
        }
    }
}

@Composable
private fun ItemStrip(controller: GameController, items: List<BuildableDefinition>) {
    Row(
        modifier = Modifier.fillMaxWidth().height(86.dp).horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        for (item in items) {
            BuildItemCard(item, controller.build.selectedID == item.id, controller.hud.cash >= item.purchasePrice || controller.hud.mode.hasUnlimitedMoney) {
                controller.select(item.id)
            }
        }
    }
}

@Composable
private fun StyleChips(controller: GameController) {
    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        if (controller.canTurnSelection) {
            Row(
                modifier = Modifier.height(26.dp).clip(CircleShape).background(Theme.accentWarm)
                    .clickable { controller.turnSelection() }.padding(horizontal = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                SymbolIcon("rotate.right", Color.Black, 12.dp)
                Label("Turn · ${controller.facingName}", size = 10.sp, weight = FontWeight.ExtraBold, color = Color.Black)
            }
        }
        if (controller.styleCount > 1) {
            StyleChip(controller, null, "Mixed")
            for (index in 0 until controller.styleCount) StyleChip(controller, index, "Style ${index + 1}")
        }
    }
}

@Composable
private fun StyleChip(controller: GameController, variant: Int?, title: String) {
    val selected = controller.build.variant == variant
    Row(
        modifier = Modifier.height(26.dp).clip(CircleShape).background(if (selected) Theme.accent else Theme.control)
            .clickable { controller.chooseStyle(variant) }.padding(horizontal = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        val appearance = controller.selectedDefinition?.previewAppearance
        if (variant != null && appearance != null) {
            val bitmap = BuildingArtwork.previewImage(appearance.withVariant(variant), CGSize(60.0, 60.0))
            Image(bitmap.asImageBitmap(), null, Modifier.size(16.dp))
        } else {
            SymbolIcon("shuffle", if (selected) Color.Black else Theme.textPrimary, 11.dp)
        }
        Label(title, size = 10.sp, weight = FontWeight.Bold, color = if (selected) Color.Black else Theme.textPrimary)
    }
}

@Composable
private fun ColourChips(controller: GameController) {
    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically) {
        val none = controller.build.colour == null
        Box(
            Modifier.height(26.dp).clip(CircleShape).background(if (none) Theme.accent else Theme.control)
                .clickable { controller.chooseColour(null) }.padding(horizontal = 9.dp),
            contentAlignment = Alignment.Center,
        ) { Label("Classic", size = 10.sp, weight = FontWeight.Bold, color = if (none) Color.Black else Theme.textPrimary) }

        for (colour in controller.colourChoices) {
            val selected = controller.build.colour == colour
            ColourSwatch(ParkPalette.colour(colour).compose(), selected, { controller.chooseColour(colour) }, 24.dp)
        }
    }
}

@Composable
private fun RideGroups(controller: GameController) {
    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        GroupChip(controller, null, "All", "square.grid.2x2.fill")
        for (group in RideGroup.entries) GroupChip(controller, group, group.displayName, group.symbolName)
    }
}

@Composable
private fun GroupChip(controller: GameController, group: RideGroup?, title: String, symbol: String) {
    val selected = controller.build.rideGroup == group
    Chip(title, selected, { controller.showRideGroup(group) }, symbol = symbol)
}

private fun hintText(controller: GameController): String {
    val build = controller.build
    if (build.isDemolishing) return "Tap anything you want to remove. Walkways refund a little; rides refund half."
    val reason = build.ghostReason
    if (reason != null && build.ghost != null) return reason
    if (build.isDrawing) return "Drawing: drag one finger to lay a run. Two fingers move the map."
    if (controller.canDraw) {
        val name = controller.selectedDefinition?.displayName?.lowercase() ?: "this"
        return "Tap to place $name. Drag moves the map. Turn on Draw to lay a run."
    }
    return when (build.category) {
        BuildCategory.transport -> "Drag out a loop of track, then put stations on it. Guests ride between them."
        BuildCategory.coaster -> "Drag out a closed circuit of track, drop different elements on it with room between them, then put a station beside it. Tap the station to see how the design is judged."
        BuildCategory.scenery -> "Tap open ground to decorate. Guests are happier near it, and the rating notices."
        else -> "Tap the map to line something up. You can turn it and check it before paying."
    }
}

@Composable
private fun BuildItemCard(definition: BuildableDefinition, isSelected: Boolean, affordable: Boolean, onTap: () -> Unit) {
    val shape = RoundedCornerShape(10.dp)
    Row(
        modifier = Modifier
            .width(150.dp)
            .clip(shape)
            .background(if (isSelected) Color.White.copy(alpha = 0.22f) else Color.White.copy(alpha = 0.11f))
            .border(BorderStroke(2.dp, if (isSelected) Theme.accent else Color.Transparent), shape)
            .clickable(onClick = onTap)
            .padding(8.dp),
        horizontalArrangement = Arrangement.spacedBy(7.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Thumbnail(definition)
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Label(definition.displayName, size = 12.sp, weight = FontWeight.Bold, maxLines = 1)
            Label(CurrencyFormatter.short(definition.purchasePrice), size = 11.sp, weight = FontWeight.Normal,
                color = if (affordable) Theme.accent else Theme.danger)
            Label("${definition.footprint.width}×${definition.footprint.height} tiles", size = 9.sp,
                weight = FontWeight.Normal, color = Theme.textSecondary)
        }
    }
}

/** The same artwork the map draws, so what you pick is what you get. */
@Composable
fun Thumbnail(definition: BuildableDefinition, side: Int = 38) {
    val appearance = definition.previewAppearance
    when {
        definition is CoasterElementDefinition -> {
            // Elements are wide and thin, so the thumbnail keeps their shape.
            val bitmap = CoasterElementArtwork.previewImage(definition.motif,
                CGSize(definition.footprint.width * 44.0, definition.visualHeight * 44.0), definition.trackLine)
            Image(bitmap.asImageBitmap(), null, Modifier.width((definition.footprint.width * 11).dp).height((definition.visualHeight * 11).dp),
                contentScale = ContentScale.FillBounds)
        }
        appearance != null -> {
            val bitmap = BuildingArtwork.previewImage(appearance, CGSize(114.0, 114.0))
            Image(bitmap.asImageBitmap(), null, Modifier.size(side.dp))
        }
        definition is TerrainDefinition -> {
            val bitmap = TerrainArtwork.previewImage(definition.terrain, definition.style, CGSize(114.0, 114.0))
            Image(bitmap.asImageBitmap(), null, Modifier.size(side.dp).clip(RoundedCornerShape(6.dp)))
        }
        else -> Box(Modifier.size(side.dp).clip(RoundedCornerShape(6.dp)).background(Color.White.copy(alpha = 0.2f)))
    }
}

/**
 * Shown while a placement is lined up but not yet paid for: what it is, what
 * it costs, which way round it is, and the three things the player can do about it.
 */
@Composable
fun PlacementConfirmBar(controller: GameController, definition: BuildableDefinition) {
    val check = controller.pendingCheck
    val isValid = check?.isValid ?: false
    val affordable = controller.hud.cash >= definition.purchasePrice || controller.hud.mode.hasUnlimitedMoney

    Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(9.dp)) {
            Thumbnail(definition, 40)
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Label(definition.displayName, size = 13.sp, weight = FontWeight.Bold, maxLines = 1)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Label(CurrencyFormatter.short(definition.purchasePrice), size = 12.sp, weight = FontWeight.ExtraBold,
                        color = if (affordable) Theme.money else Theme.danger)
                    Label("${controller.pendingFootprint.width}×${controller.pendingFootprint.height} tiles", size = 10.sp,
                        weight = FontWeight.Normal, color = Theme.textSecondary)
                }
            }
        }

        // Sliding and turning, side by side. Up is north, which is up the screen.
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            for ((symbol, dx, dy) in listOf(Triple("arrow.left", -1, 0), Triple("arrow.down", 0, -1),
                Triple("arrow.up", 0, 1), Triple("arrow.right", 1, 0))) {
                Box(
                    Modifier.size(width = 38.dp, height = 34.dp).clip(RoundedCornerShape(9.dp)).background(Theme.control)
                        .clickable { controller.nudgePending(dx, dy) },
                    contentAlignment = Alignment.Center,
                ) { SymbolIcon(symbol, Theme.textPrimary, 15.dp) }
            }
            Box(Modifier.weight(1f))
            if (definition.canRotate) {
                Row(
                    Modifier.height(34.dp).clip(RoundedCornerShape(9.dp)).background(Theme.accentWarm)
                        .clickable { controller.rotatePending() }.padding(horizontal = 11.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    SymbolIcon("rotate.right", Color.Black, 13.dp)
                    Label("Turn", size = 11.sp, weight = FontWeight.ExtraBold, color = Color.Black)
                }
            }
        }

        Label(check?.reason ?: "Drag it around the map or nudge it a tile at a time. Two fingers move the map.",
            size = 11.sp, weight = FontWeight.Normal, color = if (isValid) Theme.textSecondary else Theme.danger, maxLines = 2)

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Box(
                Modifier.weight(1f).height(38.dp).clip(RoundedCornerShape(10.dp)).background(Theme.control)
                    .clickable { controller.cancelPending() },
                contentAlignment = Alignment.Center,
            ) { Label("Cancel", size = 13.sp, weight = FontWeight.Bold) }
            Row(
                Modifier.weight(1f).height(38.dp).clip(RoundedCornerShape(10.dp))
                    .background(if (isValid) Theme.accent else Theme.control)
                    .then(if (isValid) Modifier.clickable { controller.confirmPending() } else Modifier),
                horizontalArrangement = Arrangement.spacedBy(5.dp, Alignment.CenterHorizontally),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                SymbolIcon("hammer.fill", if (isValid) Color.Black else Theme.textSecondary, 14.dp)
                Label("Build it", size = 13.sp, weight = FontWeight.ExtraBold, color = if (isValid) Color.Black else Theme.textSecondary)
            }
        }
    }
}
