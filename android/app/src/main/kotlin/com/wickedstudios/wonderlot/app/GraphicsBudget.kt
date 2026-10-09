package com.wickedstudios.wonderlot.app

import android.app.ActivityManager
import android.content.Context
import com.wickedstudios.wonderlot.Balance
import com.wickedstudios.wonderlot.KeyValueStore
import com.wickedstudios.wonderlot.gfx.SpriteFactory

/** How much of the park's detail the phone is asked to draw. */
enum class GraphicsMode(val title: String) {
    /** Full detail on a phone that can take it, compatibility on one that cannot. What almost everybody should leave it on. */
    automatic("Automatic"),

    /** Full detail, whatever the phone. For a player who does not mind a lower frame rate. */
    full("Full detail"),

    /** The lighter park, whatever the phone. For a warm afternoon and a nearly flat battery. */
    compatibility("Compatibility"),
}

/**
 * What this particular phone is. There is no list of model numbers: a list goes stale. The question is simply
 * whether this is a phone short on memory, which is what decides whether sixty frames a second and full-size artwork
 * are affordable.
 */
object DeviceProfile {
    private var memoryMegabytes = 4096L
    private var lowRam = false

    fun init(context: Context) {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo()
        manager.getMemoryInfo(info)
        memoryMegabytes = info.totalMem / (1024 * 1024)
        lowRam = manager.isLowRamDevice
    }

    val isLegacyHardware: Boolean get() = lowRam || memoryMegabytes < 3000

    /** Roughly what the phone is, for the settings screen to show. */
    val summary: String get() = "Android ${android.os.Build.VERSION.RELEASE}, ${"%.1f".format(memoryMegabytes / 1024.0)} GB of memory"
}

/**
 * What the drawing code reads, and where the setting actually lives. The renderer and the artwork caches are not
 * observers of anything, so the setting is a plain value they can ask for once a frame or once a texture.
 */
object GraphicsBudget {
    private const val MODE_KEY = "display.graphicsMode"
    private var store: KeyValueStore? = null

    fun init(context: Context, store: KeyValueStore) {
        this.store = store
        DeviceProfile.init(context)
        // Read once and then fixed for the life of the process: the textures are cached, and a park half drawn at one
        // scale and half at another would look wrong. A change is honoured by artwork drawn afterwards, and in full on
        // the next launch.
        SpriteFactory.scale = if (isReduced) 1.0 else 2.0
    }

    var mode: GraphicsMode
        get() = store?.getString(MODE_KEY)?.let { name -> GraphicsMode.entries.firstOrNull { it.name == name } } ?: GraphicsMode.automatic
        set(value) {
            store?.putString(MODE_KEY, value.name)
        }

    /** Whether the park should be drawn the lighter way, right now. */
    val isReduced: Boolean
        get() = when (mode) {
            GraphicsMode.automatic -> DeviceProfile.isLegacyHardware
            GraphicsMode.full -> false
            GraphicsMode.compatibility -> true
        }

    /** Milliseconds between frames. Half rate on an old phone is far steadier than a full rate it cannot hold. */
    val frameIntervalMillis: Long get() = if (isReduced) 33L else 0L

    /** How many guests are drawn at once. The park still simulates all of them; this is only how many figures are shown. */
    val guestSprites: Int get() = if (isReduced) 130 else Balance.maxGuests

    /** Thought bubbles on screen together. */
    val bubbles: Int get() = if (isReduced) 3 else 10

    /** Simulation steps allowed in one frame before the backlog is dropped. */
    val maxTicksPerFrame: Int get() = if (isReduced) 12 else Balance.maxTicksPerFrame
}
