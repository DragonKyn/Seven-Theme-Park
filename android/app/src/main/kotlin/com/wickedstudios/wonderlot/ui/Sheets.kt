package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

/**
 * A panel that rises from the bottom over a dimmed park. [tall] fills most of
 * the screen, for lists; otherwise it is as high as its content.
 */
@Composable
fun BottomSheet(
    title: String,
    onDismiss: () -> Unit,
    tall: Boolean = false,
    trailing: @Composable (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black.copy(alpha = 0.45f))
                .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onDismiss),
            contentAlignment = Alignment.BottomCenter,
        ) {
            val shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .then(if (tall) Modifier.fillMaxHeight(0.88f) else Modifier.heightIn(max = 640.dp))
                    .clip(shape)
                    .background(Theme.panelGradient)
                    .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) {}
                    .navigationBarsPadding(),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(title, color = Theme.textPrimary, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold,
                        modifier = Modifier.weight(1f))
                    trailing?.invoke()
                    Box(
                        Modifier.clip(RoundedCornerShape(50)).background(Theme.control).clickable(onClick = onDismiss)
                            .padding(horizontal = 12.dp, vertical = 6.dp),
                    ) { Label("Done", size = 13.sp, weight = FontWeight.Bold) }
                }
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f, fill = tall)
                        .verticalScroll(rememberScrollState())
                        .padding(start = 16.dp, end = 16.dp, bottom = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    content = content,
                )
            }
        }
    }
}

/** A yes/no question with a destructive confirmation. */
@Composable
fun ConfirmDialog(
    title: String,
    message: String,
    confirmText: String,
    cancelText: String = "Cancel",
    destructive: Boolean = false,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = Theme.panelRaised,
        title = { Text(title, color = Theme.textPrimary, fontWeight = FontWeight.Bold) },
        text = { Text(message, color = Theme.textSecondary) },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(confirmText, color = if (destructive) Theme.danger else Theme.accent, fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(cancelText, color = Theme.textPrimary) } },
    )
}
