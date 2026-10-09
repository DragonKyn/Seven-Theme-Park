package com.wickedstudios.wonderlot.ui

import androidx.compose.runtime.Composable
import com.wickedstudios.wonderlot.app.AppRouter
import com.wickedstudios.wonderlot.app.AppServices

@Composable
fun RootScreen(router: AppRouter, services: AppServices) {
    when (val screen = router.screen) {
        is AppRouter.Screen.Menu -> MainMenuScreen(router, services)
        is AppRouter.Screen.Game -> GameScreen(screen.controller, router, services)
    }

    val error = router.errorMessage
    if (error != null) {
        ConfirmDialog(
            title = "Something went wrong",
            message = error,
            confirmText = "OK",
            cancelText = "Close",
            onConfirm = { router.errorMessage = null },
            onDismiss = { router.errorMessage = null },
        )
    }
}
