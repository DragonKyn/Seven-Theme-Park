import Foundation

/// Snow, which is the only weather the park has. It comes and goes in spells
/// through the holiday event and does nothing at any other time of year. A
/// snowy spell brings a few more people through the gate.
enum WeatherSystem {

    static func update(state: GameState) {
        guard HolidaySeason.isActive(for: state) else {
            // The event is over: the snow stops, and the next one starts fresh.
            if state.snowing || state.nextWeatherChangeAt != 0 {
                state.snowing = false
                state.nextWeatherChangeAt = 0
            }
            return
        }
        guard state.clock.simTime >= state.nextWeatherChangeAt else { return }

        // The first spell of the event is snow, so the park looks the part
        // from the first day.
        state.snowing.toggle()
        let days = state.rng.double(state.snowing ? Balance.snowSpellDays : Balance.clearSpellDays)
        state.nextWeatherChangeAt = state.clock.simTime + days * Balance.dayLength
    }
}
