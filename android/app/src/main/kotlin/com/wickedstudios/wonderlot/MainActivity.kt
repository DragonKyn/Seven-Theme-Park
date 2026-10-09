package com.wickedstudios.wonderlot

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.wickedstudios.wonderlot.app.AppRouter
import com.wickedstudios.wonderlot.app.WonderLotApp
import com.wickedstudios.wonderlot.ui.RootScreen

class MainActivity : ComponentActivity() {
    private lateinit var router: AppRouter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val services = (application as WonderLotApp).services
        router = AppRouter(services)

        // The park is the whole screen.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, window.decorView).apply {
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            hide(WindowInsetsCompat.Type.systemBars())
        }

        setContent {
            RootScreen(router = router, services = services)
        }

        services.ads.start(this)
    }

    override fun onStop() {
        super.onStop()
        // Guard against the app being killed in the background.
        router.saveActiveGame()
    }
}
