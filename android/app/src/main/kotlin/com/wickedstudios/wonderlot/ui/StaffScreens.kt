package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wickedstudios.wonderlot.CurrencyFormatter
import com.wickedstudios.wonderlot.EntertainerAct
import com.wickedstudios.wonderlot.GameController
import com.wickedstudios.wonderlot.MascotCostume
import com.wickedstudios.wonderlot.ParkColour
import com.wickedstudios.wonderlot.Staff
import com.wickedstudios.wonderlot.StaffContent
import com.wickedstudios.wonderlot.StaffDetail
import com.wickedstudios.wonderlot.StaffRole
import com.wickedstudios.wonderlot.StaffStyle
import com.wickedstudios.wonderlot.gfx.CGSize
import com.wickedstudios.wonderlot.gfx.ParkPalette
import com.wickedstudios.wonderlot.gfx.StaffArtwork

private enum class StaffSort(val title: String) { byName("Name"), mostTasks("Most done"), idleFirst("Idle first") }

/** Hiring, firing and the wage bill. */
@Composable
fun StaffSheet(controller: GameController, onDismiss: () -> Unit) {
    var hiring by remember { mutableStateOf<StaffRole?>(null) }
    var filter by remember { mutableStateOf<StaffRole?>(null) }
    var sort by remember { mutableStateOf(StaffSort.byName) }
    val state = controller.state

    fun countOf(role: StaffRole) = state.staff.count { it.role == role }
    fun members(role: StaffRole): List<Staff> {
        val people = state.staff.filter { it.role == role }
        return when (sort) {
            StaffSort.byName -> people.sortedBy { it.name }
            StaffSort.mostTasks -> people.sortedByDescending { it.tasksCompleted }
            StaffSort.idleFirst -> people.sortedWith(compareByDescending<Staff> { it.isIdle }.thenBy { it.name })
        }
    }

    val present = StaffRole.entries.filter { countOf(it) > 0 }
    val shownRoles = if (filter != null && filter in present) listOf(filter!!) else present

    BottomSheet("Staff", onDismiss, tall = true) {
        SectionCard("Payroll") {
            StatRow("Employees", "${state.staff.size}")
            StatRow("Wages per day", CurrencyFormatter.short(state.dailyPayroll))
            Label("Wages are charged continuously through the day, whether or not there is work to do.", size = 11.sp,
                weight = FontWeight.Normal, color = Theme.textSecondary)
        }

        SectionCard("Hire") {
            for (definition in StaffContent.all) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
                    SymbolIcon(definition.symbolName, Theme.accent, 22.dp, Modifier.padding(top = 2.dp))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Label(definition.displayName, size = 14.sp, weight = FontWeight.Bold)
                        Label(definition.summary, size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
                        Label("${CurrencyFormatter.short(definition.hiringCost)} to hire · ${CurrencyFormatter.short(definition.dailyWage)}/day",
                            size = 11.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
                    }
                    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Label("${state.staffCount(definition.role)}", size = 16.sp, weight = FontWeight.Bold)
                        PillButton("Hire", {
                            // Mascots and entertainers come in kinds, so hiring one goes to the screen where the kind is chosen.
                            if (definition.role == StaffRole.mascot || definition.role == StaffRole.entertainer) hiring = definition.role
                            else controller.hireStaff(definition.role)
                        }, enabled = controller.canHire(definition.role))
                    }
                }
            }
        }

        SectionCard("On the payroll") {
            if (state.staff.isEmpty()) {
                Label("Nobody hired yet.", size = 13.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
            } else {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Chip("All ${state.staff.size}", filter == null, { filter = null })
                    for (role in present) Chip("${role.pluralName} ${countOf(role)}", filter == role, { filter = role })
                }
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    for (option in StaffSort.entries) Chip(option.title, sort == option, { sort = option })
                }
                Label("Tap an employee to go to them in the park.", size = 11.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
            }
        }

        for (role in shownRoles) {
            val people = members(role)
            SectionCard("${role.pluralName} · ${people.size}") {
                for (member in people) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        // Everything but the fire button takes you to them.
                        Row(
                            Modifier.weight(1f).clickable { controller.focusStaff(member.id); onDismiss() },
                            horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically,
                        ) {
                            SymbolIcon(member.definition?.symbolName ?: "person.fill", Theme.accent, 18.dp)
                            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                                Label(member.name, size = 14.sp, weight = FontWeight.Normal)
                                Label(member.roleTitle, size = 11.sp, color = Theme.accent)
                                Label(StaffDetail.describe(member, state), size = 11.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
                            }
                            Label("${member.tasksCompleted} done", size = 11.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
                        }
                        Box(Modifier.clickable { controller.fireStaff(member.id) }.padding(6.dp)) {
                            SymbolIcon("person.badge.minus", Theme.danger, 18.dp)
                        }
                    }
                }
            }
        }
    }

    hiring?.let { role ->
        StaffHireSheet(role, controller, onDismiss = { hiring = null })
    }
}

/** Choosing who to hire, for the two roles that come in more than one kind. */
@Composable
fun StaffHireSheet(role: StaffRole, controller: GameController, onDismiss: () -> Unit) {
    var style by remember {
        mutableStateOf(
            when (role) {
                StaffRole.mascot -> StaffStyle(costume = MascotCostume.bear)
                StaffRole.entertainer -> StaffStyle(act = EntertainerAct.classic)
                else -> StaffStyle.standard
            },
        )
    }
    val definition = StaffContent.definition(role)

    BottomSheet(if (role == StaffRole.mascot) "Hire a Mascot" else "Hire an Entertainer", onDismiss, tall = true, trailing = {
        PillButton("Hire", { if (controller.hireStaff(role, style)) onDismiss() }, enabled = controller.canHire(role))
        Box(Modifier.width(8.dp))
    }) {
        StaffStyleEditor(role, style, controller.state.uniformColour) { style = it }
        if (definition != null) {
            Label("${CurrencyFormatter.short(definition.hiringCost)} to hire, then ${CurrencyFormatter.short(definition.dailyWage)} a day. " +
                "You can change the look any time from their panel in the park.",
                size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
        }
    }
}

private val staffColourChoices = listOf(
    ParkColour.red, ParkColour.orange, ParkColour.amber, ParkColour.yellow, ParkColour.lime, ParkColour.green,
    ParkColour.teal, ParkColour.cyan, ParkColour.blue, ParkColour.indigo, ParkColour.violet, ParkColour.pink,
    ParkColour.white, ParkColour.cream, ParkColour.sand, ParkColour.brown, ParkColour.slate, ParkColour.charcoal,
)

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun StaffColourPicker(selected: ParkColour, onSelect: (ParkColour) -> Unit) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        for (colour in staffColourChoices) {
            ColourSwatch(ParkPalette.colour(colour).compose(), colour == selected, { onSelect(colour) }, 28.dp)
        }
    }
}

/**
 * Picks an entertainer's act, or a mascot's costume and colours. The same view
 * hires somebody and changes them afterwards, so what is offered when choosing
 * and what can be changed later are never two lists.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun StaffStyleEditor(role: StaffRole, style: StaffStyle, uniform: ParkColour, onChange: (StaffStyle) -> Unit) {
    val look = style.look(role)

    @Composable
    fun portrait() {
        val bitmap = StaffArtwork.previewImage(look, uniform, CGSize(252.0, 264.0))
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            Image(bitmap.asImageBitmap(), null, Modifier.height(120.dp), contentScale = ContentScale.Fit)
        }
    }

    @Composable
    fun colourRow(title: String, current: ParkColour, onSelect: (ParkColour) -> Unit) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Label(title.uppercase(), size = 10.sp, weight = FontWeight.ExtraBold, color = Theme.textSecondary)
            StaffColourPicker(current, onSelect)
        }
    }

    @Composable
    fun tile(label: String, bitmapLook: com.wickedstudios.wonderlot.StaffLook, selected: Boolean, onClick: () -> Unit) {
        val shape = RoundedCornerShape(10.dp)
        val bitmap = StaffArtwork.previewImage(bitmapLook, uniform, CGSize(126.0, 132.0))
        Column(
            Modifier.width(78.dp).clip(shape).background(Color.White.copy(alpha = if (selected) 0.25f else 0.10f))
                .border(2.dp, if (selected) Theme.accent else Color.Transparent, shape).clickable(onClick = onClick).padding(5.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            Image(bitmap.asImageBitmap(), null, Modifier.height(50.dp), contentScale = ContentScale.Fit)
            Label(label, size = 10.sp, weight = FontWeight.Bold, maxLines = 1)
        }
    }

    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        when (role) {
            StaffRole.mascot -> {
                portrait()
                Label("COSTUME", size = 10.sp, weight = FontWeight.ExtraBold, color = Theme.textSecondary)
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    for (costume in MascotCostume.entries) {
                        tile(costume.displayName, StaffStyle(costume = costume).look(StaffRole.mascot), look.costume == costume) {
                            // A new costume comes in its own colours, all at once as one change.
                            onChange(style.copy(costume = costume, primary = null, secondary = null, trim = null))
                        }
                    }
                }
                colourRow("Fur or feathers", look.primary) { onChange(style.copy(primary = it)) }
                colourRow(look.costume.secondaryLabel, look.secondary) { onChange(style.copy(secondary = it)) }
                colourRow("Bow tie and shoes", look.trim) { onChange(style.copy(trim = it)) }
                PillButton("Back to the original colours", {
                    onChange(style.copy(primary = null, secondary = null, trim = null))
                }, background = Theme.control, foreground = Theme.textPrimary)
            }

            StaffRole.entertainer -> {
                portrait()
                Label("ACT", size = 10.sp, weight = FontWeight.ExtraBold, color = Theme.textSecondary)
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    for (act in EntertainerAct.entries) {
                        tile(act.displayName, StaffStyle(act = act).look(StaffRole.entertainer), look.act == act) {
                            onChange(style.copy(act = act, primary = null))
                        }
                    }
                }
                Label(look.act.summary, size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
                if (look.act.usesColour) colourRow(look.act.colourLabel, look.primary) { onChange(style.copy(primary = it)) }
            }

            else -> {}
        }
    }
}

/** Shown while the player is choosing where to move an employee to. */
@Composable
fun StaffMoveBar(controller: GameController) {
    val name = controller.movingStaffName ?: "them"
    val pending = controller.pendingStaffMove
    Row(
        Modifier.fillMaxWidth().panelBackground().padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        SymbolIcon("location.fill", Theme.accent, 16.dp)
        Label(if (pending == null) "Tap a walkway to move $name" else "Move $name to the marked spot?", size = 13.sp, maxLines = 1,
            modifier = Modifier.weight(1f))
        Label("Cancel", size = 13.sp, modifier = Modifier.clickable { controller.cancelStaffMove() }.padding(6.dp))
        PillButton("Move", { controller.confirmStaffMove() }, enabled = pending != null)
    }
}
