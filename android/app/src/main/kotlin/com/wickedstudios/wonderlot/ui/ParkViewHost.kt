package com.wickedstudios.wonderlot.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import com.wickedstudios.wonderlot.GameController
import com.wickedstudios.wonderlot.render.ParkRenderer
import com.wickedstudios.wonderlot.render.ParkView

/**
 * The park itself, drawn by the renderer. [onVersion] is told whenever the
 * controller has something new for the interface to show, which is what makes
 * the Compose side redraw from the same state the park runs on.
 */
@Composable
fun ParkViewHost(
    controller: GameController,
    interactive: Boolean,
    modifier: Modifier = Modifier,
    onVersion: (Int) -> Unit,
) {
    val renderer = remember(controller) { ParkRenderer(controller, interactive) }
    AndroidView(
        modifier = modifier,
        factory = { context -> ParkView(context, controller, renderer, onVersion) },
        update = { },
    )
}
