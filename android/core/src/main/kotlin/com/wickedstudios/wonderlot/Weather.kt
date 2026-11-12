package com.wickedstudios.wonderlot

/**
 * Snow, which is the only weather the park has. It comes and goes in spells through the holiday event and does
 * nothing at any other time of year. A snowy spell brings a few more people through the gate.
 */
object WeatherSystem {

    fun update(state: GameState) {
        if (!HolidaySeason.isActive(state)) {
            // The event is over: the snow stops, and the next one starts fresh.
            if (state.snowing || state.nextWeatherChangeAt != 0.0) {
                state.snowing = false
                state.nextWeatherChangeAt = 0.0
            }
            return
        }
        if (state.clock.simTime < state.nextWeatherChangeAt) return

        // The first spell of the event is snow, so the park looks the part from the first day.
        state.snowing = !state.snowing
        val days = state.rng.double(if (state.snowing) Balance.snowSpellDays else Balance.clearSpellDays)
        state.nextWeatherChangeAt = state.clock.simTime + days * Balance.dayLength
    }
}
