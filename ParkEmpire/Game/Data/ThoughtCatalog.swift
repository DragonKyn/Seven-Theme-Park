import Foundation

/// Guest thoughts are generated from simulation state, not picked at random,
/// so reading a guest's thought list explains what the park is doing to them.
enum ThoughtCatalog {

    static func need(hunger: Double,
                     thirst: Double,
                     bathroom: Double,
                     energy: Double) -> (String, ThoughtMood, ThoughtIcon)? {
        if bathroom > 90 { return ("I really need a restroom.", .negative, .restroom) }
        if thirst > 85 { return ("I'm so thirsty.", .negative, .drink) }
        if hunger > 85 { return ("I'm starving.", .negative, .food) }
        if energy < 18 { return ("My feet are killing me.", .negative, .tired) }
        if bathroom > 70 { return ("I should find a restroom soon.", .neutral, .restroom) }
        if hunger > 70 { return ("I'm getting hungry.", .neutral, .food) }
        if thirst > 70 { return ("I could go for a drink.", .neutral, .drink) }
        if energy < 32 { return ("I need somewhere to sit.", .neutral, .tired) }
        return nil
    }

    static func cannotFind(_ what: String) -> String {
        "I can't find a \(what) anywhere."
    }

    static func queueTooLong(_ rideName: String) -> String {
        "The line for \(rideName) is way too long."
    }

    static func abandonedQueue(_ rideName: String) -> String {
        "I gave up waiting for \(rideName)."
    }

    static func joinedQueue(_ rideName: String, wait: Double) -> (String, ThoughtMood) {
        if wait < 30 { return ("\(rideName) has barely any line!", .positive) }
        if wait < 90 { return ("I'll wait for \(rideName).", .neutral) }
        return ("Hope \(rideName) is worth this wait.", .neutral)
    }

    static func afterRide(_ rideName: String, satisfaction: Double) -> (String, ThoughtMood) {
        if satisfaction > 12 { return ("\(rideName) was amazing!", .positive) }
        if satisfaction > 4 { return ("\(rideName) was pretty fun.", .positive) }
        if satisfaction > 0 { return ("\(rideName) was alright.", .neutral) }
        return ("\(rideName) wasn't really for me.", .negative)
    }

    static func priceReaction(item: String, price: Double, willingness: Double) -> (String, ThoughtMood) {
        let formatted = CurrencyFormatter.short(price)
        if willingness < 0.15 {
            return ("\(formatted) for \(item)? You have to be kidding.", .negative)
        }
        if willingness < 0.4 {
            return ("\(formatted) for \(item)? That's expensive.", .negative)
        }
        if willingness > 0.85 {
            return ("\(formatted) for \(item) is a great deal.", .positive)
        }
        return ("\(formatted) for \(item) seems fair.", .neutral)
    }

    static func admission(price: Double, willingness: Double) -> (String, ThoughtMood) {
        let formatted = CurrencyFormatter.short(price)
        if willingness < 0.35 {
            return ("\(formatted) just to get in? This had better be good.", .negative)
        }
        if willingness > 0.8 {
            return ("Only \(formatted) to get in — worth it.", .positive)
        }
        return ("\(formatted) to get in seems reasonable.", .neutral)
    }

    static func gameWon(prize: String) -> (String, ThoughtMood) {
        ("I won a \(prize)!", .positive)
    }

    static func gameLost(game: String) -> (String, ThoughtMood) {
        ("So close at \(game). One more go.", .neutral)
    }

    static func outOfMoney() -> (String, ThoughtMood) {
        ("I'm out of money.", .negative)
    }

    static func leaving(reason: DepartureReason) -> (String, ThoughtMood) {
        switch reason {
        case .satisfied: return ("What a great day. Time to head home.", .positive)
        case .unhappy: return ("I'm not enjoying this. I'm going home.", .negative)
        case .tired: return ("I'm exhausted and there's nowhere to sit.", .negative)
        case .brokeAndBored: return ("Nothing left to spend. I'll head out.", .neutral)
        case .noBathroom: return ("No restrooms anywhere. I'm leaving.", .negative)
        case .queuesTooLong: return ("Every line is enormous. I'm done.", .negative)
        case .tooDirty: return ("This place is filthy. I'm not staying.", .negative)
        }
    }

    static func enjoyment(happiness: Double) -> (String, ThoughtMood)? {
        if happiness > 88 { return ("I'm having an amazing day!", .positive) }
        if happiness < 25 { return ("This park is a letdown.", .negative) }
        return nil
    }
}
