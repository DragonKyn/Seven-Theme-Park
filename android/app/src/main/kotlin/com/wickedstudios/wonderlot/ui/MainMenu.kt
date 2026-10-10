package com.wickedstudios.wonderlot.ui

import android.graphics.Bitmap
import androidx.compose.animation.core.tween
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
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
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.material3.Text
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.DropdownMenu
import androidx.compose.foundation.combinedClickable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wickedstudios.wonderlot.AppInfo
import com.wickedstudios.wonderlot.Balance
import com.wickedstudios.wonderlot.CurrencyFormatter
import com.wickedstudios.wonderlot.GameMode
import com.wickedstudios.wonderlot.MapBlueprint
import com.wickedstudios.wonderlot.MapCatalogue
import com.wickedstudios.wonderlot.MapGround
import com.wickedstudios.wonderlot.SaveGameService
import com.wickedstudios.wonderlot.SaveSlotSummary
import com.wickedstudios.wonderlot.TrialContent
import com.wickedstudios.wonderlot.GameController
import com.wickedstudios.wonderlot.app.GraphicsBudget
import com.wickedstudios.wonderlot.app.AppRouter
import com.wickedstudios.wonderlot.app.AppServices
import kotlinx.coroutines.delay

/**
 * The title screen, over a live park running the real simulation. The park
 * behind it is the best thing on the screen, so the menu keeps out of its way.
 */
@Composable
fun MainMenuScreen(router: AppRouter, services: AppServices) {
    var showingNewGame by remember { mutableStateOf(false) }
    var showingTrials by remember { mutableStateOf(false) }
    var showingAbout by remember { mutableStateOf(false) }
    var showingGraphics by remember { mutableStateOf(false) }
    var slotToDelete by remember { mutableStateOf<Int?>(null) }
    // Built off the main thread: the live park behind the menu takes a while to set up, and the menu should not wait for it.
    var demo by remember { mutableStateOf<GameController?>(null) }
    LaunchedEffect(Unit) {
        if (!GraphicsBudget.isReduced) demo = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Default) { services.demoController() }
    }
    val tick = remember { mutableIntStateOf(0) }

    LaunchedEffect(Unit) {
        router.refreshSlots()
        router.refreshTrials()
        if (router.opensLadderOnMenu) {
            router.opensLadderOnMenu = false
            showingTrials = true
        }
    }

    val slots = router.slotSummaries.value
    val mostRecent = router.mostRecentSlot

    Box(Modifier.fillMaxSize()) {
        val backdrop = demo
        if (backdrop != null) {
            ParkViewHost(backdrop, interactive = false, modifier = Modifier.fillMaxSize(), onVersion = { tick.intValue = it })
        } else {
            Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color(0.20f, 0.44f, 0.62f), Color(0.36f, 0.66f, 0.45f)))))
        }

        Box(
            Modifier.fillMaxSize().background(
                Brush.verticalGradient(
                    0.00f to Color.Black.copy(alpha = 0.70f),
                    0.30f to Color.Black.copy(alpha = 0.20f),
                    0.46f to Color.Black.copy(alpha = 0.12f),
                    1.00f to Color.Black.copy(alpha = 0.78f),
                ),
            ),
        )

        Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
            Masthead(Modifier.padding(top = 22.dp))
            Spacer(Modifier.weight(1f))

            Column(
                Modifier.padding(horizontal = 24.dp).padding(bottom = 22.dp).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                if (mostRecent != null && slots[mostRecent] != null) {
                    val summary = slots[mostRecent]!!
                    MenuButton("Continue", "${summary.parkName}, day ${summary.day}", "play.fill", prominent = true) {
                        router.loadGame(mostRecent)
                    }
                }
                MenuButton("Park Trials", "${router.completedTrials.value.size} of ${TrialContent.all.size} medals · parks on a deadline",
                    "flag.checkered", prominent = false) { showingTrials = true }
                MenuButton("New Park", "Pick a map, normal or free build", "plus", prominent = slots.isEmpty()) {
                    showingNewGame = true
                }

                Column(verticalArrangement = Arrangement.spacedBy(7.dp)) {
                    Label("SAVED PARKS", size = 10.sp, weight = FontWeight.ExtraBold, tracking = 1.6f, color = Color.White.copy(alpha = 0.62f),
                        modifier = Modifier.padding(start = 4.dp))
                    for (slot in 0 until SaveGameService.slotCount) {
                        SaveSlotRow(slot, slots[slot], onLoad = { router.loadGame(slot) }, onDelete = { slotToDelete = slot })
                    }
                }

                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally)) {
                    FooterLink("About ${AppInfo.gameName}", "heart.fill", Theme.danger) { showingAbout = true }
                    FooterLink("Graphics", "slider.horizontal.3", Theme.accent) { showingGraphics = true }
                }
            }
        }
    }

    if (showingNewGame) {
        NewParkSheet(router, slots, firstEmptySlot(slots), onDismiss = { showingNewGame = false }) { name, mode, map, slot ->
            router.startNewGame(name, mode, map, slot)
            showingNewGame = false
        }
    }

    val doomed = slotToDelete
    if (doomed != null) {
        val summary = slots[doomed]
        ConfirmDialog(
            title = "Delete this park?",
            message = if (summary != null) "${summary.parkName} is on day ${summary.day}. This cannot be undone." else "This cannot be undone.",
            confirmText = "Delete", cancelText = "Keep it", destructive = true,
            onConfirm = { router.deleteSave(doomed); slotToDelete = null },
            onDismiss = { slotToDelete = null },
        )
    }

    if (showingTrials) TrialLadderScreen(router, services, onClose = { showingTrials = false })
    if (showingAbout) AboutSheet(onDismiss = { showingAbout = false })
    if (showingGraphics) GraphicsSheet(services, onDismiss = { showingGraphics = false })
}

/** The first slot with nothing in it, or null when every slot holds a park. */
private fun firstEmptySlot(slots: Map<Int, SaveSlotSummary>): Int? {
    for (slot in 0 until SaveGameService.slotCount) if (slots[slot] == null) return slot
    return null
}

@Composable
private fun Masthead(modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(7.dp)) {
        androidx.compose.material3.Text(
            AppInfo.gameName,
            style = TextStyle(
                fontSize = 46.sp, fontWeight = FontWeight.ExtraBold,
                brush = Theme.moneyGradient,
                shadow = androidx.compose.ui.graphics.Shadow(Color.Black.copy(alpha = 0.55f), blurRadius = 20f),
            ),
        )
        Tagline()
        Box(Modifier.width(190.dp).height(1.dp).background(
            Brush.horizontalGradient(listOf(Color.Transparent, Color.White.copy(alpha = 0.55f), Color.Transparent))))
    }
}

@Composable
private fun MenuButton(title: String, subtitle: String, symbol: String, prominent: Boolean, onClick: () -> Unit) {
    val shape = RoundedCornerShape(Theme.cornerRadius)
    val foreground = if (prominent) Color.Black.copy(alpha = 0.88f) else Color.White
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(if (prominent) Theme.moneyGradient else Brush.verticalGradient(
                listOf(Theme.panelTop.copy(alpha = 0.92f), Theme.panelBottom.copy(alpha = 0.92f))))
            .border(BorderStroke(1.dp, Color.White.copy(alpha = if (prominent) 0.45f else 0.18f)), shape)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.size(34.dp).clip(CircleShape).background(if (prominent) Color.Black.copy(alpha = 0.14f) else Color.White.copy(alpha = 0.14f)),
            contentAlignment = Alignment.Center) { SymbolIcon(symbol, foreground, 17.dp) }
        Column(Modifier.weight(1f)) {
            Label(title, size = 17.sp, weight = FontWeight.ExtraBold, color = foreground)
            Label(subtitle, size = 11.sp, weight = FontWeight.Medium, color = foreground.copy(alpha = 0.72f), maxLines = 1)
        }
        SymbolIcon("chevron.right", foreground.copy(alpha = 0.45f), 14.dp)
    }
}

@Composable
private fun FooterLink(title: String, symbol: String, tint: Color, onClick: () -> Unit) {
    Row(
        Modifier.clip(CircleShape).background(Color.Black.copy(alpha = 0.30f)).clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        SymbolIcon(symbol, tint, 11.dp)
        Label(title, size = 11.sp, color = Color.White.copy(alpha = 0.75f), maxLines = 1)
    }
}

// region Save slots

@Composable
private fun SaveSlotRow(slot: Int, summary: SaveSlotSummary?, onLoad: () -> Unit, onDelete: () -> Unit) {
    val shape = RoundedCornerShape(12.dp)
    if (summary == null) {
        Row(
            Modifier.fillMaxWidth().height(40.dp).border(BorderStroke(1.dp, Color.White.copy(alpha = 0.16f)), shape).padding(horizontal = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Label("Slot ${slot + 1}", size = 12.sp, color = Color.White.copy(alpha = 0.45f), modifier = Modifier.weight(1f))
            Label("Empty", size = 11.sp, weight = FontWeight.Medium, color = Color.White.copy(alpha = 0.35f))
        }
        return
    }

    Row(
        Modifier.fillMaxWidth().clip(shape).background(Color.Black.copy(alpha = 0.34f))
            .border(BorderStroke(1.dp, Color.White.copy(alpha = 0.12f)), shape).padding(10.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Label(summary.parkName, size = 14.sp, weight = FontWeight.Bold, maxLines = 1)
                if (summary.mode != GameMode.normal) {
                    Box(Modifier.clip(CircleShape).background(Theme.accent.copy(alpha = 0.35f)).padding(horizontal = 5.dp, vertical = 2.dp)) {
                        SymbolIcon(summary.mode.symbolName, Color.White, 11.dp)
                    }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                StarRating(starsFor(summary.parkRating))
                Label("Day ${summary.day}", size = 10.sp, weight = FontWeight.Medium, color = Color.White.copy(alpha = 0.7f))
                Label("${summary.guestCount} guests", size = 10.sp, weight = FontWeight.Medium, color = Color.White.copy(alpha = 0.7f))
            }
            // The balance gets its own chip on its own line.
            Box(Modifier.clip(CircleShape).background(Theme.moneyGradient).padding(horizontal = 8.dp, vertical = 2.dp)) {
                Label(if (summary.mode == GameMode.freeBuild) "Unlimited" else CurrencyFormatter.compact(summary.cash),
                    size = 12.sp, weight = FontWeight.ExtraBold, color = Color.Black.copy(alpha = 0.85f), maxLines = 1)
            }
        }
        Box(Modifier.height(30.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.92f)).clickable(onClick = onLoad).padding(horizontal = 12.dp),
            contentAlignment = Alignment.Center) { Label("Load", size = 12.sp, weight = FontWeight.Bold, color = Color.Black) }
        Box(Modifier.size(30.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.12f)).clickable(onClick = onDelete),
            contentAlignment = Alignment.Center) { SymbolIcon("trash", Color.White.copy(alpha = 0.85f), 14.dp) }
    }
}

/** Mirrors the park's star rating. The summary stores the raw rating so the menu never opens a save. */
private fun starsFor(rating: Double): Int = when {
    rating < 20 -> 1
    rating < 40 -> 2
    rating < 60 -> 3
    rating < 80 -> 4
    else -> 5
}

// endregion

// region New park

@Composable
private fun NewParkSheet(
    router: AppRouter,
    summaries: Map<Int, SaveSlotSummary>,
    suggestedSlot: Int?,
    onDismiss: () -> Unit,
    onStart: (String, GameMode, MapBlueprint, Int) -> Unit,
) {
    var parkName by remember { mutableStateOf("") }
    var mode by remember { mutableStateOf(GameMode.normal) }
    var slot by remember { mutableStateOf(suggestedSlot) }
    var mapID by remember { mutableStateOf(MapCatalogue.openMeadowID) }
    var confirmingReplace by remember { mutableStateOf(false) }
    val openEditor = { map: com.wickedstudios.wonderlot.CustomMap? ->
        router.editor = AppRouter.EditorRequest(map) { saved -> router.saveCustomMap(saved); mapID = "custom.${saved.id}" }
    }
    var deleting by remember { mutableStateOf<MapBlueprint?>(null) }
    val maps = router.availableMaps
    val selectedMap = maps.firstOrNull { it.id == mapID } ?: MapCatalogue.openMeadow

    fun start() {
        val chosen = slot ?: return
        if (summaries[chosen] != null) confirmingReplace = true else onStart(parkName, mode, selectedMap, chosen)
    }

    BottomSheet("New Park", onDismiss, tall = true, closeLabel = "Cancel", trailing = {
        PillButton("Start", { start() }, enabled = slot != null)
        Spacer(Modifier.width(8.dp))
    }) {
        SectionCard("Park name") {
            Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(Color.White.copy(alpha = 0.12f)).padding(12.dp)) {
                if (parkName.isEmpty()) Label("New Park", color = Theme.textSecondary, weight = FontWeight.Normal)
                BasicTextField(
                    value = parkName, onValueChange = { parkName = it.take(28) }, singleLine = true,
                    textStyle = TextStyle(color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.SemiBold),
                    cursorBrush = SolidColor(Theme.accent), modifier = Modifier.fillMaxWidth(),
                )
            }
        }

        SectionCard("Map") {
            MapPicker(maps, mapID, onSelect = { mapID = it },
                onCreate = { openEditor(null) },
                onEdit = { openEditor(router.customMap(it.id.removePrefix("custom."))) },
                onDelete = { deleting = it })
        }
        Label("Hold a map you drew to edit or delete it.", size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary,
            modifier = Modifier.padding(horizontal = 4.dp))

        SectionCard("Mode") {
            for (option in GameMode.sandboxModes) {
                val selected = mode == option
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp))
                        .background(if (selected) Color.White.copy(alpha = 0.14f) else Color.Transparent)
                        .clickable { mode = option }.padding(8.dp),
                    horizontalArrangement = Arrangement.spacedBy(11.dp),
                ) {
                    SymbolIcon(option.symbolName, if (selected) Theme.accent else Theme.textSecondary, 20.dp)
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Label(option.displayName, size = 14.sp, weight = FontWeight.Bold)
                        Label(option.summary, size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
                    }
                    if (selected) SymbolIcon("checkmark.circle.fill", Theme.accent, 18.dp)
                }
            }
        }

        SectionCard("Save slot") {
            for (index in 0 until SaveGameService.slotCount) {
                val selected = slot == index
                val existing = summaries[index]
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp))
                        .background(if (selected) Color.White.copy(alpha = 0.14f) else Color.Transparent)
                        .clickable { slot = index }.padding(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Label(if (existing != null) "Slot ${index + 1}, overwrite ${existing.parkName}" else "Slot ${index + 1}, empty",
                        size = 13.sp, modifier = Modifier.weight(1f))
                    if (selected) SymbolIcon("checkmark.circle.fill", Theme.accent, 18.dp)
                }
            }
            if (suggestedSlot == null) {
                Label("All three slots are full. Pick the park to replace; you will be asked to confirm before anything is deleted.",
                    size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
            }
        }

        Label(
            when (mode) {
                GameMode.normal -> "You start with ${CurrencyFormatter.short(Balance.startingCash)}, a park entrance and a short walkway. Everything else is up to you."
                GameMode.trial -> "Trials are started from the Park Trials ladder."
                GameMode.freeBuild -> "Build without paying for any of it. The books still record what everything would have cost, so the finance screen still tells you whether the park could support itself."
            },
            size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary,
        )
    }

    deleting?.let { map ->
        ConfirmDialog("Delete ${map.name}?", "The map is removed for good. Parks already built on it are not affected.", "Delete", destructive = true,
            onConfirm = {
                router.customMap(map.id.removePrefix("custom."))?.let { router.deleteCustomMap(it.id) }
                if (mapID == map.id) mapID = MapCatalogue.openMeadowID
                deleting = null
            },
            onDismiss = { deleting = null })
    }

    if (confirmingReplace) {
        val chosen = slot
        val existing = chosen?.let { summaries[it] }
        ConfirmDialog(
            title = "Replace this park?",
            message = if (existing != null) "${existing.parkName} in slot ${(chosen ?: 0) + 1} will be deleted for good to make room. This cannot be undone." else "",
            confirmText = "Replace it", cancelText = "Keep it", destructive = true,
            onConfirm = { confirmingReplace = false; if (chosen != null) onStart(parkName, mode, selectedMap, chosen) },
            onDismiss = { confirmingReplace = false },
        )
    }
}

@OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
private fun MapPicker(
    maps: List<MapBlueprint>, selectedID: String, onSelect: (String) -> Unit,
    onCreate: () -> Unit, onEdit: (MapBlueprint) -> Unit, onDelete: (MapBlueprint) -> Unit,
) {
    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        for (map in maps) {
            val selected = map.id == selectedID
            val shape = RoundedCornerShape(12.dp)
            var menu by remember { mutableStateOf(false) }
            Box {
                Column(
                    Modifier.width(128.dp).clip(shape).background(Color.White.copy(alpha = if (selected) 0.20f else 0.10f))
                        .border(BorderStroke(2.dp, if (selected) Theme.accent else Color.Transparent), shape)
                        .combinedClickable(onClick = { onSelect(map.id) }, onLongClick = { if (map.isCustom) menu = true })
                        .padding(8.dp),
                    verticalArrangement = Arrangement.spacedBy(5.dp),
                ) {
                    val thumbnail = remember(map.id, map.layout.ground.hashCode()) { mapThumbnail(map) }
                    Image(thumbnail.asImageBitmap(), null, Modifier.fillMaxWidth().height(112.dp).clip(RoundedCornerShape(8.dp)),
                        filterQuality = FilterQuality.None)
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                        Label(map.name, size = 12.sp, weight = FontWeight.Bold, maxLines = 1, modifier = Modifier.weight(1f, fill = false))
                        if (map.isCustom) SymbolIcon("person.fill", Theme.textSecondary, 10.dp)
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                        for (dot in 1..5) {
                            Box(Modifier.size(6.dp).clip(CircleShape).background(if (dot <= map.difficulty) Theme.accentWarm else Color.White.copy(alpha = 0.25f)))
                        }
                    }
                    Label(map.summary, size = 10.sp, weight = FontWeight.Normal, color = Theme.textSecondary, maxLines = 3)
                    if (map.isCustom) Label("Hold to edit or delete", size = 9.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
                }
                DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                    DropdownMenuItem(text = { Text("Edit map") }, onClick = { menu = false; onEdit(map) })
                    DropdownMenuItem(text = { Text("Delete map", color = Theme.danger) }, onClick = { menu = false; onDelete(map) })
                }
            }
        }

        // A card for drawing a new one.
        val dashed = RoundedCornerShape(12.dp)
        Column(
            Modifier.width(128.dp).height(212.dp).clip(dashed).border(BorderStroke(1.5.dp, Theme.accent.copy(alpha = 0.6f)), dashed)
                .clickable(onClick = onCreate).padding(10.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
        ) {
            SymbolIcon("pencil", Theme.accent, 28.dp)
            Label("Draw your own", size = 12.sp, weight = FontWeight.Bold)
            Label("Paint water, rock and forest, and put the gate where you like.", size = 10.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
        }
    }
}

internal fun mapThumbnail(map: MapBlueprint): Bitmap {
    val layout = map.layout
    val bitmap = Bitmap.createBitmap(layout.width, layout.height, Bitmap.Config.ARGB_8888)
    val colours = mapOf(
        MapGround.grass to 0xFF8CC773.toInt(),
        MapGround.water to 0xFF59A1DB.toInt(),
        MapGround.rock to 0xFF8F877F.toInt(),
        MapGround.forest to 0xFF336B3D.toInt(),
    )
    for (y in 0 until layout.height) {
        for (x in 0 until layout.width) {
            // North is up the screen, so row zero (the gate) is the bottom of the picture.
            bitmap.setPixel(x, layout.height - 1 - y, colours[layout.ground(x, y)] ?: 0)
        }
    }
    // The gate.
    bitmap.setPixel(layout.entranceX.coerceIn(0, layout.width - 1), layout.height - 1, 0xFFF5BD4D.toInt())
    return bitmap
}

// endregion
