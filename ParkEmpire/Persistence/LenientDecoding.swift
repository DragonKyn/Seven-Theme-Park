import Foundation

/// Helpers for forward-compatible save loading.
///
/// The save format is versioned, but most version bumps only *add* fields. In
/// that case an older save is still perfectly readable as long as the new
/// fields fall back to a sensible default instead of throwing. Types that have
/// gained fields decode through these helpers rather than relying on the
/// compiler-synthesised initialiser, which requires every key to be present.
extension KeyedDecodingContainer {

    /// The stored value, or `fallback` when the key is missing or unreadable.
    func value<T: Decodable>(_ key: Key, or fallback: T) -> T {
        ((try? decodeIfPresent(T.self, forKey: key)) ?? nil) ?? fallback
    }

    /// The stored value for a property that is itself optional.
    func optionalValue<T: Decodable>(_ key: Key) -> T? {
        (try? decodeIfPresent(T.self, forKey: key)) ?? nil
    }
}
