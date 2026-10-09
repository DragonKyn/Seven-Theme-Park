package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.wickedstudios.wonderlot.AppInfo
import com.wickedstudios.wonderlot.TrialContent
import com.wickedstudios.wonderlot.app.AppRouter
import com.wickedstudios.wonderlot.app.AppServices
import com.wickedstudios.wonderlot.gfx.SpriteFactory

/** The ladder of timed challenges, each unlocked by winning the one before. */
@Composable
fun TrialLadderScreen(router: AppRouter, services: AppServices, onClose: () -> Unit) {
    val completed = router.completedTrials.value
    val runs = router.trialRuns.value
    var confirmRestart by remember { mutableStateOf<com.wickedstudios.wonderlot.TrialDefinition?>(null) }

    Box(Modifier.fillMaxSize().background(Color(0.05f, 0.08f, 0.12f)).statusBarsPadding()) {
        Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Label("Trials", size = 24.sp, weight = FontWeight.ExtraBold, modifier = Modifier.weight(1f))
                PillButton("Close", onClose, background = Theme.control, foreground = Theme.textPrimary)
            }
            Label("${completed.size} of ${TrialContent.all.size} complete", size = 12.sp, color = Theme.textSecondary)

            for (trial in TrialContent.all) {
                val unlocked = router.isTrialUnlocked(trial)
                val best = completed[trial.id]
                val run = runs[trial.id]
                Column(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Theme.control).padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                        SymbolIcon(if (!unlocked) "lock.fill" else trial.medal.symbolName, if (best != null) Theme.money else Theme.textSecondary, 24.dp)
                        Column(Modifier.weight(1f)) {
                            Label("TRIAL ${trial.number}", size = 9.sp, weight = FontWeight.ExtraBold, color = Theme.textSecondary)
                            Label(trial.title, size = 16.sp, weight = FontWeight.ExtraBold)
                        }
                        best?.let { Label("Day $it", weight = FontWeight.ExtraBold, color = Theme.money) }
                    }
                    if (unlocked) {
                        Label(trial.briefing, size = 12.sp, color = Theme.textSecondary)
                        Label("${trial.dayLimit} days  ·  ${com.wickedstudios.wonderlot.CurrencyFormatter.short(trial.startingCash)} to start", size = 11.sp, color = Theme.textSecondary)
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            if (run != null) {
                                PillButton("Resume (day ${run.day})", { onClose(); router.resumeTrial(trial) })
                                PillButton("Restart", { confirmRestart = trial }, background = Theme.control, foreground = Theme.textPrimary)
                            } else {
                                PillButton("Start", { onClose(); router.startTrial(trial) })
                            }
                        }
                    } else {
                        Label("Win the previous trial to unlock this one.", size = 11.sp, color = Theme.textSecondary)
                    }
                }
            }
        }
    }

    confirmRestart?.let { trial ->
        ConfirmDialog("Restart ${trial.title}?", "The run in progress will be replaced.", "Restart", destructive = true,
            onConfirm = { confirmRestart = null; onClose(); router.startTrial(trial) }, onDismiss = { confirmRestart = null })
    }
}

@Composable
fun AboutSheet(onDismiss: () -> Unit) {
    BottomSheet("About", onDismiss) {
        Label(AppInfo.gameName, size = 20.sp, weight = FontWeight.ExtraBold)
        Label("Version 1.2.2", size = 12.sp, color = Theme.textSecondary)
        Label("A theme park builder by Wicked Studios. Build rides, hire staff and keep the guests happy.", size = 13.sp)
        Label("Android edition. Saves are kept on this device and are separate from the iOS game.", size = 11.sp, color = Theme.textSecondary)
    }
}

@Composable
fun GraphicsSheet(services: AppServices, onDismiss: () -> Unit) {
    var reduced by remember { mutableStateOf(SpriteFactory.scale < 2.0) }
    BottomSheet("Graphics", onDismiss) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Label("Reduced graphics")
                Label("Draws artwork at lower resolution. Helps older phones; applies to newly drawn art.", size = 11.sp, color = Theme.textSecondary)
            }
            androidx.compose.material3.Switch(checked = reduced, onCheckedChange = {
                reduced = it
                SpriteFactory.scale = if (it) 1.0 else 2.0
            })
        }
    }
}
