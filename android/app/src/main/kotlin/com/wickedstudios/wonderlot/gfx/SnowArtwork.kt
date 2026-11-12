package com.wickedstudios.wonderlot.gfx

import android.graphics.Bitmap
import com.wickedstudios.wonderlot.TerrainType

/**
 * The seasonal dusting of snow over the ground. It is drawn over the ordinary tile, not instead of it, so grass is
 * still grass, a path is still a path, and the layout is as easy to read as ever. Placement is fixed by the tile's
 * look, so the same tile always has the same snow on it.
 */
object SnowArtwork {

    private val white = UIColor(0.97, 0.98, 1.0, 1.0)
    private val shade = UIColor(0.78, 0.85, 0.94, 1.0)

    /** The tile with snow on it, or the tile itself for ground that does not take any. */
    fun dust(base: Bitmap, terrain: TerrainType, variant: Int, mask: Int, style: Int, side: Double): Bitmap {
        if (!takesSnow(terrain)) return base
        val key = "snow-${terrain.name}-$style-$variant-$mask-${side.toInt()}"
        return SpriteFactory.texture(key, CGSize(side, side)) { context, size ->
            context.draw(base, CGRect(0, 0, size.width, size.height))
            overlay(terrain, variant, mask, size)
        }
    }

    private fun takesSnow(terrain: TerrainType): Boolean = when (terrain) {
        TerrainType.grass, TerrainType.path, TerrainType.bridge, TerrainType.rock, TerrainType.forest, TerrainType.water -> true
        else -> false
    }

    /** A little deterministic number generator, so snow never moves about between frames or runs. */
    private class Lcg(seed: Int) {
        private var state = (seed * 2654435761L + 12345L) and 0x7fffffffL
        fun next(): Double {
            state = (state * 1103515245L + 12345L) and 0x7fffffffL
            return (state % 10_000L) / 10_000.0
        }
    }

    private fun patch(size: CGSize, cx: Double, cy: Double, w: Double, h: Double, alpha: Double) {
        val rect = CGRect(size.width * cx - size.width * w / 2, size.height * cy - size.height * h / 2, size.width * w, size.height * h)
        shade.withAlphaComponent(alpha * 0.55).setFill()
        UIBezierPath(ovalIn = rect.offsetBy(0, size.height * h * 0.14)).fill()
        white.withAlphaComponent(alpha).setFill()
        UIBezierPath(ovalIn = rect).fill()
    }

    private fun overlay(terrain: TerrainType, variant: Int, mask: Int, size: CGSize) {
        val rng = Lcg(terrain.ordinal * 131 + variant * 17 + mask * 3)
        when (terrain) {
            TerrainType.grass -> {
                // Most of the lawn under snow, with the odd tuft showing through.
                for (index in 0 until 7) {
                    val w = 0.26 + rng.next() * 0.28
                    patch(size, 0.08 + rng.next() * 0.84, 0.08 + rng.next() * 0.84, w, w * (0.55 + rng.next() * 0.3), 0.92)
                }
            }
            TerrainType.path, TerrainType.bridge -> {
                // A lighter dusting on the walkway, which is walked on.
                for (index in 0 until 5) {
                    val w = 0.16 + rng.next() * 0.20
                    patch(size, 0.10 + rng.next() * 0.80, 0.10 + rng.next() * 0.80, w, w * 0.7, 0.62)
                }
            }
            TerrainType.rock -> {
                for (index in 0 until 4) {
                    val w = 0.26 + rng.next() * 0.2
                    patch(size, 0.12 + rng.next() * 0.76, 0.10 + rng.next() * 0.45, w, w * 0.6, 0.9)
                }
            }
            TerrainType.forest -> {
                for (index in 0 until 6) {
                    val w = 0.18 + rng.next() * 0.2
                    patch(size, 0.10 + rng.next() * 0.80, 0.10 + rng.next() * 0.80, w, w * 0.7, 0.85)
                }
            }
            TerrainType.water -> {
                // A few slivers of ice drifting on the surface.
                white.withAlphaComponent(0.55).setFill()
                for (index in 0 until 3) {
                    val w = 0.14 + rng.next() * 0.12
                    UIBezierPath(ovalIn = CGRect(size.width * (0.10 + rng.next() * 0.70), size.height * (0.10 + rng.next() * 0.78),
                        size.width * w, size.height * w * 0.45)).fill()
                }
            }
            else -> {}
        }
    }
}
