package com.wickedstudios.wonderlot.ui

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.drag
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.activity.compose.BackHandler
import com.wickedstudios.wonderlot.CustomMap
import com.wickedstudios.wonderlot.MapBlueprint
import com.wickedstudios.wonderlot.MapCatalogue
import com.wickedstudios.wonderlot.MapGround
import com.wickedstudios.wonderlot.MapLayout
import java.util.UUID
import kotlin.math.abs

/** What the map editor is painting with. */
private sealed class EditorTool {
    class Paint(val ground: MapGround) : EditorTool()
    data object Gate : EditorTool()
}

/**
 * The map editor's state and rules. The screen draws it and forwards touches; everything about what a touch does
 * lives here.
 */
private class MapEditorModel(editing: CustomMap?) {
    val id: UUID = editing?.id ?: UUID.randomUUID()
    var name by mutableStateOf(editing?.name ?: "")
    var layout by mutableStateOf((editing?.layout ?: MapCatalogue.openMeadow.layout).copy())
    var tool by mutableStateOf<EditorTool>(EditorTool.Paint(MapGround.water))

    /** Radius in tiles, so 0 is a single tile. */
    var brushRadius by mutableIntStateOf(1)

    /** Bumped on every change, since the layout is mutated in place. */
    var revision by mutableIntStateOf(0)
    private val history = ArrayList<MapLayout>()
    var canUndo by mutableStateOf(false)

    /** Call once at the start of a stroke, so a whole drag undoes as one. */
    fun beginStroke() {
        history.add(layout.copy())
        if (history.size > HISTORY_LIMIT) history.removeAt(0)
        canUndo = true
    }

    /** Applies the current tool at a tile. [y] is in map space, 0 at the gate. */
    fun apply(x: Int, y: Int) {
        when (val current = tool) {
            EditorTool.Gate -> {
                if (x < 1 || x > layout.width - 2) return
                layout.entranceX = x
                // The ground in front of a gate has to be open, or the park it makes cannot let anybody in.
                layout.clearGateApproach()
                revision += 1
            }
            is EditorTool.Paint -> {
                for (dy in -brushRadius..brushRadius) {
                    for (dx in -brushRadius..brushRadius) {
                        if (dx * dx + dy * dy > brushRadius * brushRadius + 1) continue
                        if (isGateApproach(x + dx, y + dy)) continue
                        layout.set(current.ground, x + dx, y + dy)
                    }
                }
                revision += 1
            }
        }
    }

    fun undo() {
        val previous = history.removeLastOrNull() ?: return
        layout = previous
        canUndo = history.isNotEmpty()
        revision += 1
    }

    /** Starts again from one of the shipped maps, or from bare grass. */
    fun start(blueprint: MapBlueprint?) {
        beginStroke()
        layout = (blueprint?.layout ?: MapLayout()).copy()
        revision += 1
    }

    /** The tiles in front of the gate are never painted over, so the player can see the way in is kept open. */
    fun isGateApproach(x: Int, y: Int): Boolean = y in 0..MapLayout.clearance && abs(x - layout.entranceX) <= 1

    val trimmedName: String get() = name.trim()
    val buildableTiles: Int get() = layout.buildableCount

    /** Why the map cannot be saved yet, or null when it can. */
    val problem: String?
        get() {
            if (trimmedName.isEmpty()) return "Give the map a name."
            if (buildableTiles < MINIMUM_BUILDABLE_TILES) {
                return "Leave more open grass. A park needs at least $MINIMUM_BUILDABLE_TILES tiles of it."
            }
            return null
        }

    fun makeMap(): CustomMap? {
        if (problem != null) return null
        val finished = layout.copy()
        finished.clearGateApproach()
        return CustomMap(id, trimmedName, finished, System.currentTimeMillis())
    }

    companion object {
        /** A map with less land than this is not one anybody can build a park on. Roughly a tenth of the lot. */
        const val MINIMUM_BUILDABLE_TILES = 360
        val brushRadii = listOf(0, 1, 2, 4)
        private const val HISTORY_LIMIT = 40
    }
}

private val groundColours = mapOf(
    MapGround.grass to Color(0xFF8CC773),
    MapGround.water to Color(0xFF59A1DB),
    MapGround.rock to Color(0xFF8F877F),
    MapGround.forest to Color(0xFF336B3D),
)

private val gateColour = Color(0xFFF5BD4D)

/** Draw a map: paint the ground with a finger, choose where the gate goes, and name it. */
@Composable
fun MapEditorScreen(editing: CustomMap?, onSave: (CustomMap) -> Unit, onCancel: () -> Unit) {
    val model = remember { MapEditorModel(editing) }
    var startMenu by remember { mutableStateOf(false) }
    @Suppress("UNUSED_VARIABLE") val observed = model.revision

    BackHandler(onBack = onCancel)

    Column(Modifier.fillMaxSize().background(Theme.panelGradient)) {
        Row(Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Label("Draw a Map", size = 18.sp, weight = FontWeight.ExtraBold, modifier = Modifier.weight(1f))
            PillButton("Cancel", onCancel, background = Theme.control, foreground = Theme.textPrimary)
            PillButton("Save", { model.makeMap()?.let(onSave) }, enabled = model.problem == null)
        }

        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp).padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)) {
            BasicTextField(
                value = model.name, onValueChange = { model.name = it }, singleLine = true,
                textStyle = TextStyle(color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.SemiBold),
                cursorBrush = SolidColor(Theme.accent),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                decorationBox = { inner ->
                    Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(Color.White.copy(alpha = 0.12f)).padding(12.dp)) {
                        if (model.name.isEmpty()) Label("Map name", size = 20.sp, color = Theme.textSecondary)
                        inner()
                    }
                },
            )

            Canvas(model)
            Tools(model)
            if (model.tool is EditorTool.Paint) BrushSizes(model)

            Row(verticalAlignment = Alignment.CenterVertically) {
                Row(Modifier.clickable(enabled = model.canUndo) { model.undo() }.padding(vertical = 6.dp), horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically) {
                    SymbolIcon("arrow.uturn.backward", if (model.canUndo) Color.White else Theme.textSecondary, 16.dp)
                    Label("Undo", size = 14.sp, weight = FontWeight.SemiBold, color = if (model.canUndo) Color.White else Theme.textSecondary)
                }
                Box(Modifier.weight(1f))
                Box {
                    Row(Modifier.clickable { startMenu = true }.padding(vertical = 6.dp), horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        SymbolIcon("square.on.square", Color.White, 16.dp)
                        Label("Start from", size = 14.sp, weight = FontWeight.SemiBold)
                    }
                    DropdownMenu(expanded = startMenu, onDismissRequest = { startMenu = false }) {
                        DropdownMenuItem(text = { Text("Blank grass") }, onClick = { startMenu = false; model.start(null) })
                        for (blueprint in MapCatalogue.all) {
                            DropdownMenuItem(text = { Text(blueprint.name) }, onClick = { startMenu = false; model.start(blueprint) })
                        }
                    }
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Label(
                    if (model.tool is EditorTool.Gate) "Tap along the bottom edge to move the gate. The dashed strip in front of it always stays open."
                    else "Drag to paint. Water can be bridged in the park; rock and forest can never be built on.",
                    size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary,
                )
                val problem = model.problem
                if (problem != null) {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                        SymbolIcon("exclamationmark.circle.fill", Theme.accentWarm, 14.dp)
                        Label(problem, size = 12.sp, weight = FontWeight.SemiBold, color = Theme.accentWarm)
                    }
                } else {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                        SymbolIcon("checkmark.circle.fill", Theme.accent, 14.dp)
                        Label("${model.buildableTiles} tiles of open grass. Ready to save.", size = 12.sp, weight = FontWeight.SemiBold, color = Theme.accent)
                    }
                }
            }
        }
    }
}

@Composable
private fun Canvas(model: MapEditorModel) {
    @Suppress("UNUSED_VARIABLE") val observed = model.revision
    val layout = model.layout
    val bitmap = remember(model.revision) { render(layout) }

    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val side = maxWidth
        val sidePx = with(LocalDensity.current) { side.toPx() }
        Box(
            Modifier.size(side).clip(RoundedCornerShape(10.dp)).border(1.dp, Color.White.copy(alpha = 0.15f), RoundedCornerShape(10.dp))
                .pointerInput(Unit) {
                    awaitEachGesture {
                        val down = awaitFirstDown(requireUnconsumed = false)
                        model.beginStroke()
                        paint(model, down.position.x, down.position.y, sidePx)
                        down.consume()
                        drag(down.id) { change ->
                            paint(model, change.position.x, change.position.y, sidePx)
                            change.consume()
                        }
                    }
                },
        ) {
            Image(bitmap.asImageBitmap(), null, Modifier.fillMaxSize(), filterQuality = FilterQuality.None)
            androidx.compose.foundation.Canvas(Modifier.fillMaxSize()) {
                // The clear strip in front of the gate, outlined so it is obvious that painting there does nothing.
                val cellW = size.width / layout.width
                val cellH = size.height / layout.height
                drawRect(
                    Color.White.copy(alpha = 0.85f),
                    topLeft = androidx.compose.ui.geometry.Offset((layout.entranceX - 1) * cellW, size.height - (MapLayout.clearance + 1) * cellH),
                    size = androidx.compose.ui.geometry.Size(cellW * 3, (MapLayout.clearance + 1) * cellH),
                    style = androidx.compose.ui.graphics.drawscope.Stroke(
                        1.dp.toPx(), pathEffect = androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(6f, 6f)),
                    ),
                )
            }
        }
    }
}

private fun paint(model: MapEditorModel, px: Float, py: Float, side: Float) {
    val layout = model.layout
    if (px < 0 || py < 0 || px >= side || py >= side) return
    val x = (px / side * layout.width).toInt()
    // Screen rows run downward; map rows count up from the gate.
    val y = layout.height - 1 - (py / side * layout.height).toInt()
    model.apply(x, y)
}

private fun render(layout: MapLayout): Bitmap {
    val bitmap = Bitmap.createBitmap(layout.width, layout.height, Bitmap.Config.ARGB_8888)
    for (y in 0 until layout.height) {
        for (x in 0 until layout.width) {
            val colour = groundColours[layout.ground(x, y)] ?: Color.Black
            bitmap.setPixel(x, layout.height - 1 - y, android.graphics.Color.argb(255, (colour.red * 255).toInt(), (colour.green * 255).toInt(), (colour.blue * 255).toInt()))
        }
    }
    bitmap.setPixel(layout.entranceX.coerceIn(0, layout.width - 1), layout.height - 1, gateColour.toArgbInt())
    return bitmap
}

private fun Color.toArgbInt(): Int = android.graphics.Color.argb(255, (red * 255).toInt(), (green * 255).toInt(), (blue * 255).toInt())

@Composable
private fun Tools(model: MapEditorModel) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        for (ground in MapGround.entries) {
            val selected = (model.tool as? EditorTool.Paint)?.ground == ground
            ToolButton(ground.displayName, selected, Modifier.weight(1f), { model.tool = EditorTool.Paint(ground) }) {
                Box(Modifier.size(26.dp).clip(RoundedCornerShape(5.dp)).background(groundColours[ground] ?: Color.Gray))
            }
        }
        ToolButton("Gate", model.tool is EditorTool.Gate, Modifier.weight(1f), { model.tool = EditorTool.Gate }) {
            Box(Modifier.size(26.dp), contentAlignment = Alignment.Center) { SymbolIcon("door.left.hand.open", gateColour, 20.dp) }
        }
    }
}

@Composable
private fun ToolButton(title: String, selected: Boolean, modifier: Modifier, onClick: () -> Unit, swatch: @Composable () -> Unit) {
    val shape = RoundedCornerShape(10.dp)
    Column(
        modifier.clip(shape).background(if (selected) Theme.accent.copy(alpha = 0.22f) else Color.White.copy(alpha = 0.10f))
            .border(2.dp, if (selected) Theme.accent else Color.Transparent, shape).clickable(onClick = onClick).padding(vertical = 7.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        swatch()
        Label(title, size = 10.sp, weight = FontWeight.SemiBold, maxLines = 1)
    }
}

@Composable
private fun BrushSizes(model: MapEditorModel) {
    val names = listOf("Fine", "Small", "Medium", "Large")
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Label("Brush", size = 13.sp, weight = FontWeight.SemiBold, color = Theme.textSecondary)
        for ((index, radius) in MapEditorModel.brushRadii.withIndex()) {
            Chip(names[index], model.brushRadius == radius, { model.brushRadius = radius }, Modifier.weight(1f))
        }
    }
}
