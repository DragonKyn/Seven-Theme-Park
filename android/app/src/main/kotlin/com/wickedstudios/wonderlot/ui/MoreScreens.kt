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
