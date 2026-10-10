package com.wickedstudios.wonderlot.ui

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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wickedstudios.wonderlot.AttractionDetail
import com.wickedstudios.wonderlot.Balance
import com.wickedstudios.wonderlot.CoasterCarStyle
import com.wickedstudios.wonderlot.CoasterContent
import com.wickedstudios.wonderlot.CurrencyFormatter
import com.wickedstudios.wonderlot.FacilityDetail
import com.wickedstudios.wonderlot.GameController
import com.wickedstudios.wonderlot.GuestDetail
import com.wickedstudios.wonderlot.SceneryDetail
import com.wickedstudios.wonderlot.SelectionDetail
import com.wickedstudios.wonderlot.StaffDetail
import com.wickedstudios.wonderlot.StaffRole
import com.wickedstudios.wonderlot.ThoughtMood
import com.wickedstudios.wonderlot.gfx.BuildingArtwork
import com.wickedstudios.wonderlot.gfx.CGSize
import com.wickedstudios.wonderlot.gfx.ParkPalette

/** Wraps whichever inspector matches the current selection. */
@Composable
fun InspectorHost(selection: SelectionDetail, controller: GameController) {
    val title = when (selection) {
        is SelectionDetail.OfGuest -> selection.detail.name
        is SelectionDetail.OfAttraction -> selection.detail.name
        is SelectionDetail.OfFacility -> selection.detail.name
        // Employees say so in the header, because a name on its own reads exactly like a visitor's.
        is SelectionDetail.OfStaff -> "${selection.detail.name}, ${selection.detail.roleName}"
        is SelectionDetail.OfScenery -> selection.detail.name
    }

    Column(Modifier.fillMaxWidth().panelBackground()) {
        Row(Modifier.padding(start = 12.dp, end = 12.dp, top = 10.dp, bottom = 6.dp), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Label(title, size = 15.sp, weight = FontWeight.Bold, modifier = Modifier.weight(1f), maxLines = 1)
            if (selection is SelectionDetail.OfStaff) {
                TextAction("Move", "location.fill", Theme.accent) { controller.beginMovingStaff() }
            }
            if (controller.canRemoveSelected) {
                TextAction("Remove", "trash", Theme.danger) { controller.removeSelected() }
            }
            Box(Modifier.clickable { controller.clearSelection() }) { SymbolIcon("xmark.circle.fill", Theme.textSecondary, 22.dp) }
        }

        Column(
            Modifier.heightIn(max = 280.dp).verticalScroll(rememberScrollState()).padding(start = 12.dp, end = 12.dp, bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            when (selection) {
                is SelectionDetail.OfGuest -> GuestInspector(selection.detail)
                is SelectionDetail.OfAttraction -> AttractionInspector(selection.detail, controller)
                is SelectionDetail.OfFacility -> FacilityInspector(selection.detail, controller)
                is SelectionDetail.OfStaff -> StaffInspector(selection.detail, controller)
                is SelectionDetail.OfScenery -> SceneryInspector(selection.detail, controller)
            }
        }
    }
}

@Composable
private fun TextAction(title: String, symbol: String, tint: Color, onClick: () -> Unit) {
    Row(Modifier.clickable(onClick = onClick).padding(horizontal = 4.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        SymbolIcon(symbol, tint, 14.dp)
        Label(title, size = 12.sp, weight = FontWeight.Bold, color = tint)
    }
}

/** A full-width button used at the foot of inspectors. */
@Composable
fun WideButton(text: String, symbol: String, onClick: () -> Unit, modifier: Modifier = Modifier, background: Color = Theme.control,
               foreground: Color = Theme.textPrimary, enabled: Boolean = true) {
    Row(
        modifier = modifier.clip(RoundedCornerShape(10.dp)).background(if (enabled) background else background.copy(alpha = 0.4f))
            .then(if (enabled) Modifier.clickable(onClick = onClick) else Modifier).padding(vertical = 9.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        SymbolIcon(symbol, foreground, 14.dp)
        Label(text, size = 13.sp, weight = FontWeight.SemiBold, color = foreground)
    }
}

// region Guest

@Composable
private fun GuestInspector(guest: GuestDetail) {
    SectionCard("Right now") {
        Label(guest.activityText, size = 13.sp)
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            StatPill("face.smiling", "${guest.happiness.toInt()}%", tint = Theme.happinessColour(guest.happiness))
            StatPill("wallet.bifold", CurrencyFormatter.short(guest.cash))
            StatPill("clock", guest.timeInParkText)
        }
    }

    SectionCard("Needs") {
        MeterBar("Hunger", guest.hunger, Theme.needColour(guest.hunger))
        MeterBar("Thirst", guest.thirst, Theme.needColour(guest.thirst))
        MeterBar("Restroom", guest.bathroomNeed, Theme.needColour(guest.bathroomNeed))
        MeterBar("Nausea", guest.nausea, Theme.needColour(guest.nausea))
        MeterBar("Energy", guest.energy, Theme.happinessColour(guest.energy))
    }

    SectionCard("Recent thoughts") {
        if (guest.thoughts.isEmpty()) {
            Label("Nothing on their mind yet.", size = 13.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
        } else {
            for (thought in guest.thoughts.take(5)) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Box(Modifier.padding(top = 6.dp).size(5.dp).clip(CircleShape).background(when (thought.mood) {
                        ThoughtMood.positive -> Theme.accent
                        ThoughtMood.neutral -> Theme.textSecondary
                        ThoughtMood.negative -> Theme.danger
                    }))
                    Label(thought.text, size = 13.sp, weight = FontWeight.Normal, color = Theme.textPrimary.copy(alpha = 0.9f))
                }
            }
        }
    }

    SectionCard("This visit") {
        StatRow("Visitor", guest.ageCategory)
        StatRow("Rides experienced", "${guest.ridesRidden}")
        StatRow("Purchases", "${guest.purchases}")
        StatRow("Money spent", CurrencyFormatter.exact(guest.moneySpent))
        guest.prizeName?.let { StatRow("Carrying", it.replaceFirstChar { c -> c.uppercase() }) }
        if (guest.prizesWon > 0) StatRow("Prizes won", "${guest.prizesWon}")
    }

    SectionCard("Personality") {
        MeterBar("Thrill preference", guest.thrillPreference, Theme.accentWarm)
        MeterBar("Patience", guest.patience, Theme.accent)
        MeterBar("Spending", guest.spending, Theme.accent)
    }
}

// endregion

// region Upgrades

/** One upgrade track: what it does, how far it has been taken, and a button to take it one step further. */
@Composable
fun UpgradeRow(title: String, summary: String, symbolName: String, level: Int, maxLevel: Int, cost: Double?, affordable: Boolean,
               onBuy: () -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(9.dp), verticalAlignment = Alignment.Top) {
        Box(Modifier.size(22.dp), contentAlignment = Alignment.Center) {
            SymbolIcon(symbolName, if (level > 0) Theme.accentWarm else Theme.textSecondary, 14.dp)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                Label(title, size = 12.sp, weight = FontWeight.Bold)
                LevelPips(level, maxLevel)
            }
            Label(summary, size = 10.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
        }
        if (cost != null) {
            Box(
                Modifier.height(28.dp).clip(RoundedCornerShape(8.dp)).background(if (affordable) Theme.accent else Theme.control)
                    .then(if (affordable) Modifier.clickable(onClick = onBuy) else Modifier).padding(horizontal = 9.dp),
                contentAlignment = Alignment.Center,
            ) { Label(CurrencyFormatter.short(cost), size = 11.sp, weight = FontWeight.Bold, color = if (affordable) Color.Black else Theme.danger) }
        } else {
            Box(Modifier.height(28.dp), contentAlignment = Alignment.Center) {
                Label("Maxed", size = 10.sp, color = Theme.accentWarm)
            }
        }
    }
}

/** Filled dots for levels bought, hollow for what is left. */
@Composable
fun LevelPips(level: Int, maxLevel: Int) {
    Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
        for (index in 0 until maxOf(maxLevel, 1)) {
            Box(Modifier.size(5.dp).clip(CircleShape).background(if (index < level) Theme.accentWarm else Color.White.copy(alpha = 0.28f)))
        }
    }
}

// endregion

// region Attraction

@Composable
private fun AttractionInspector(attraction: AttractionDetail, controller: GameController) {
    var renaming by remember { mutableStateOf(false) }
    var draft by remember { mutableStateOf("") }

    SectionCard("Status") {
        StatRow("Type", attraction.typeName)
        StatRow("Status", attraction.status, tint = if (attraction.isOpen) Theme.accent else Theme.danger)
        StatRow("Condition", "${attraction.condition.toInt()}%", tint = Theme.happinessColour(attraction.condition))
        StatRow("Queue", "${attraction.queueLength} waiting")
        StatRow("Estimated wait", attraction.waitText)
    }

    SectionCard("Performance") {
        StatRow("Guests today", "${attraction.guestsToday}")
        StatRow("Guests all time", "${attraction.totalGuests}")
        StatRow("Guest satisfaction", attraction.satisfactionText)
        StatRow("Cost per cycle", CurrencyFormatter.exact(attraction.operatingCostPerCycle))
    }

    SectionCard("Ride profile") {
        MeterBar("Excitement", attraction.excitement, Theme.accentWarm)
        MeterBar("Nausea", attraction.nauseaRating, Theme.needColour(attraction.nauseaRating))
        StatRow("Capacity", "${attraction.capacity} per cycle")
        StatRow("Ride time", "${attraction.rideDuration.toInt()}s")
    }

    SectionCard("Paintwork") {
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(7.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.height(24.dp).clip(CircleShape).background(if (attraction.tint == null) Theme.accent else Theme.control)
                    .clickable { controller.setRideTint(null, attraction.id) }.padding(horizontal = 9.dp),
                contentAlignment = Alignment.Center,
            ) { Label("Stock", size = 10.sp, weight = FontWeight.ExtraBold, color = if (attraction.tint == null) Color.Black else Theme.textPrimary) }
            for (colour in CoasterContent.liveries) {
                ColourSwatch(ParkPalette.colour(colour).compose(), colour == attraction.tint, { controller.setRideTint(colour, attraction.id) }, 24.dp)
            }
        }
        Label("Repaints this ride only. Stock puts it back to the colours it came in.", size = 10.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
    }

    if (attraction.isCustomCoaster) CoasterCard(attraction, controller)

    SectionCard("Upgrades") {
        for (upgrade in attraction.upgrades) {
            UpgradeRow(upgrade.displayName, upgrade.summary, upgrade.symbolName, upgrade.level, upgrade.maxLevel, upgrade.cost,
                controller.hud.cash >= (upgrade.cost ?: 0.0) || controller.hud.mode.hasUnlimitedMoney) {
                controller.buyUpgrade(upgrade.kind, attraction.id)
            }
        }
    }

    if (attraction.isImpounded) {
        // Said plainly, because the player's own open switch is still wherever they left it.
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(Theme.danger.copy(alpha = 0.18f)).padding(9.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
        ) {
            SymbolIcon("xmark.seal.fill", Theme.danger, 16.dp)
            Label("Shut by a safety inspector. It cannot take anybody until a mechanic has repaired it.", size = 13.sp, color = Theme.danger)
        }
    }

    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        WideButton(if (attraction.isOpen) "Close ride" else "Open ride", if (attraction.isOpen) "pause.circle.fill" else "play.circle.fill",
            { controller.setRideOpen(!attraction.isOpen, attraction.id) }, Modifier.weight(1f),
            background = if (attraction.isOpen) Theme.danger.copy(alpha = 0.85f) else Theme.accent, foreground = Color.Black,
            enabled = !attraction.isImpounded)
        WideButton("Rename", "pencil", { draft = attraction.name; renaming = true }, Modifier.weight(1f))
        WideButton("Turn", "rotate.right", { controller.turnSelected() }, Modifier.weight(1f))
    }

    if (renaming) {
        TextEntryDialog("Rename ride", draft, onDismiss = { renaming = false }) {
            controller.rename(attraction.id, it)
            renaming = false
        }
    }
}

@Composable
private fun CoasterCard(attraction: AttractionDetail, controller: GameController) {
    SectionCard("Your coaster") {
        StatRow("Track laid", "${attraction.trackLength} tiles")
        val coaster = attraction.coaster
        if (coaster != null) {
            StatRow("Circuit", if (coaster.isLoop) "Closed loop" else "Open line", tint = if (coaster.isLoop) Theme.accent else Theme.accentWarm)
            StatRow("Elements", if (coaster.elementCount == 0) "None"
            else "${coaster.elementCount}, ${coaster.kindCount} kind${if (coaster.kindCount == 1) "" else "s"}")
            StatRow("Intensity", attraction.intensityText)
            for (note in coaster.advice) {
                Row(horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                    SymbolIcon("lightbulb", Theme.textSecondary, 12.dp)
                    Label(note, size = 10.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
                }
            }
        }

        Label("LIVERY", size = 9.sp, weight = FontWeight.Bold, color = Theme.textSecondary)
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(7.dp)) {
            for (colour in CoasterContent.liveries) {
                ColourSwatch(ParkPalette.colour(colour).compose(), colour == attraction.livery, { controller.setCoasterLivery(colour, attraction.id) }, 24.dp)
            }
        }

        Label("TRACK", size = 9.sp, weight = FontWeight.Bold, color = Theme.textSecondary)
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(7.dp)) {
            for (colour in CoasterContent.liveries) {
                ColourSwatch(ParkPalette.colour(colour).compose(), colour == controller.state.coasterTrackColour,
                    { controller.setCoasterTrackColour(colour) }, 24.dp)
            }
        }
        Label("Repaints every piece of coaster track in the park.", size = 10.sp, weight = FontWeight.Normal, color = Theme.textSecondary)

        Label("CARS", size = 9.sp, weight = FontWeight.Bold, color = Theme.textSecondary)
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            for (style in CoasterCarStyle.entries) {
                Chip(style.displayName, style == attraction.carStyle, { controller.setCoasterCarStyle(style, attraction.id) })
            }
        }
    }
}

// endregion

// region Facility

@Composable
private fun FacilityInspector(facility: FacilityDetail, controller: GameController) {
    if (facility.sellsGoods) {
        SectionCard("Pricing") {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Label(CurrencyFormatter.exact(facility.price), size = 20.sp, weight = FontWeight.Bold, modifier = Modifier.weight(1f))
                val sentimentColour = facility.sentiment?.let {
                    when {
                        it < 0.4 -> Theme.danger
                        it < 0.65 -> Theme.accentWarm
                        else -> Theme.accent
                    }
                } ?: Theme.textSecondary
                Label(facility.sentimentText, size = 12.sp, color = sentimentColour)
            }

            val maxPrice = maxOf(facility.referencePrice * 3, 5.0).toFloat()
            Slider(
                value = facility.price.toFloat().coerceIn(0f, maxPrice),
                onValueChange = { controller.setPrice((Math.round(it * 2) / 2.0), facility.id) },
                valueRange = 0f..maxPrice,
                colors = SliderDefaults.colors(thumbColor = Theme.accent, activeTrackColor = Theme.accent),
            )

            StatRow("Cost per item", CurrencyFormatter.exact(facility.unitCost))
            StatRow("Profit per sale", CurrencyFormatter.exact(facility.profitPerSale),
                tint = if (facility.profitPerSale > 0) Theme.accent else Theme.danger)
            StatRow("Guests think it is fair at", CurrencyFormatter.exact(facility.referencePrice))
        }
    }

    SectionCard(if (facility.sellsGoods) "Trade" else "Use") {
        StatRow("Type", facility.typeName)
        controller.guestInterest(facility.id)?.let { StatRow("Guests", it) }
        StatRow("Queue", "${facility.queueLength} waiting")
        StatRow("${facility.visitorNoun} today", "${facility.customersToday}")
        StatRow("${facility.visitorNoun} all time", "${facility.totalCustomers}")
        facility.cleaningProgress?.let {
            StatRow("Janitor at work", "${(it * 100).toInt()}% cleaned, shut meanwhile", tint = Theme.accentWarm)
        }
        facility.soiling?.let {
            StatRow("Condition", if (it > Balance.dirtyFacilityThreshold) "Needs servicing" else "Fine",
                tint = if (it > Balance.dirtyFacilityThreshold) Theme.danger else Theme.accent)
        }
        if (facility.isGame) StatRow("Prizes given", "${facility.prizesGiven}")
        if (facility.sellsGoods) {
            StatRow("Revenue today", CurrencyFormatter.short(facility.revenueToday))
            StatRow("Revenue all time", CurrencyFormatter.short(facility.totalRevenue))
            StatRow("Stock cost all time", CurrencyFormatter.short(facility.totalCost))
            val gross = facility.totalRevenue - facility.totalCost
            StatRow("Gross profit", CurrencyFormatter.signed(gross), tint = if (gross >= 0) Theme.accent else Theme.danger)
        }
    }

    if (facility.upgrades.isNotEmpty()) {
        SectionCard("Improvements") {
            for (upgrade in facility.upgrades) {
                UpgradeRow(upgrade.displayName, upgrade.summary, upgrade.symbolName, upgrade.level, upgrade.maxLevel, upgrade.cost,
                    controller.hud.cash >= (upgrade.cost ?: 0.0) || controller.hud.mode.hasUnlimitedMoney) {
                    controller.buyShopUpgrade(upgrade.kind, facility.id)
                }
            }
        }
    }

    WideButton(if (facility.isOpen) "Close" else "Open", if (facility.isOpen) "pause.circle.fill" else "play.circle.fill",
        { controller.setFacilityOpen(!facility.isOpen, facility.id) }, Modifier.fillMaxWidth(),
        background = if (facility.isOpen) Theme.danger.copy(alpha = 0.85f) else Theme.accent, foreground = Color.Black)
    WideButton("Turn", "rotate.right", { controller.turnSelected() }, Modifier.fillMaxWidth())
}

// endregion

// region Staff

@Composable
private fun StaffInspector(member: StaffDetail, controller: GameController) {
    SectionCard("Right now") {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            SymbolIcon(member.symbolName, Theme.accent, 22.dp)
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Label(member.roleName, size = 13.sp)
                Label(member.activityText, size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
            }
        }
    }

    SectionCard("Record") {
        StatRow("Tasks completed", "${member.tasksCompleted}")
        StatRow("Wage", "${CurrencyFormatter.short(member.dailyWage)} per day")
    }

    if (member.role == StaffRole.mascot || member.role == StaffRole.entertainer) {
        SectionCard(if (member.role == StaffRole.mascot) "Costume" else "Act") {
            StaffStyleEditor(member.role, member.style, controller.state.uniformColour) { controller.setStaffStyle(member.id, it) }
        }
    }

    SectionCard("Training") {
        UpgradeRow(member.trainingTitle, "Walks faster, works faster, and costs more to keep.", "graduationcap.fill",
            member.trainingLevel, member.maxTrainingLevel, member.trainingCost,
            controller.hud.cash >= (member.trainingCost ?: 0.0) || controller.hud.mode.hasUnlimitedMoney) {
            controller.trainStaff(member.id)
        }
    }

    if (member.isOnOrders) {
        WideButton("Back to normal work", "arrow.counterclockwise", { controller.releaseStaff(member.id) }, Modifier.fillMaxWidth())
    }

    WideButton("Dismiss employee", "person.badge.minus", { controller.fireStaff(member.id) }, Modifier.fillMaxWidth(),
        background = Theme.danger.copy(alpha = 0.85f), foreground = Color.Black)
}

// endregion

// region Scenery

@Composable
private fun SceneryInspector(item: SceneryDetail, controller: GameController) {
    if (item.styleCount > 1) {
        SectionCard("Style") {
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                for (index in 0 until item.styleCount) {
                    val selected = item.variant % item.styleCount == index
                    val bitmap = BuildingArtwork.previewImage(item.appearance.withVariant(index), CGSize(80.0, 80.0))
                    Box(
                        Modifier.clip(RoundedCornerShape(9.dp)).background(Theme.control)
                            .border(2.dp, if (selected) Theme.accent else Color.Transparent, RoundedCornerShape(9.dp))
                            .clickable { controller.setSceneryStyle(index) }.padding(4.dp),
                    ) { Image(bitmap.asImageBitmap(), null, Modifier.size(40.dp)) }
                }
            }
        }
    }

    if (item.colourChoices.isNotEmpty()) {
        SectionCard("Colour") {
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(
                    Modifier.height(30.dp).clip(CircleShape).background(if (item.colour == null) Theme.accent else Theme.control)
                        .clickable { controller.setSceneryColour(null) }.padding(horizontal = 10.dp),
                    contentAlignment = Alignment.Center,
                ) { Label("Classic", size = 11.sp, weight = FontWeight.Bold, color = if (item.colour == null) Color.Black else Theme.textPrimary) }
                for (colour in item.colourChoices) {
                    ColourSwatch(ParkPalette.colour(colour).compose(), item.colour == colour, { controller.setSceneryColour(colour) })
                }
            }
        }
    }

    WideButton("Turn", "rotate.right", { controller.turnSelected() }, Modifier.fillMaxWidth(), background = Theme.accentWarm, foreground = Color.Black)
}

// endregion

/** A one-line text prompt. */
@Composable
fun TextEntryDialog(title: String, initial: String, onDismiss: () -> Unit, onSave: (String) -> Unit) {
    var text by remember { mutableStateOf(initial) }
    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = Theme.panelRaised,
        title = { androidx.compose.material3.Text(title, color = Theme.textPrimary, fontWeight = FontWeight.Bold) },
        text = {
            Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(Color.White.copy(alpha = 0.12f)).padding(12.dp)) {
                BasicTextField(value = text, onValueChange = { text = it.take(32) }, singleLine = true,
                    textStyle = TextStyle(color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.SemiBold),
                    cursorBrush = SolidColor(Theme.accent), modifier = Modifier.fillMaxWidth())
            }
        },
        confirmButton = {
            androidx.compose.material3.TextButton(onClick = { onSave(text) }) {
                androidx.compose.material3.Text("Save", color = Theme.accent, fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            androidx.compose.material3.TextButton(onClick = onDismiss) { androidx.compose.material3.Text("Cancel", color = Theme.textPrimary) }
        },
    )
}
