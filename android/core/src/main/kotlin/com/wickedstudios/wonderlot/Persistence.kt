@file:UseSerializers(UUIDSerializer::class)

package com.wickedstudios.wonderlot

import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import java.io.File
import java.util.UUID

/** The small key/value store things that outlive a single park are kept in (SharedPreferences on Android). */
interface KeyValueStore {
    fun getString(key: String): String?
    fun putString(key: String, value: String)
    fun remove(key: String)
}

/** An in-memory store, for tests. */
class MemoryStore : KeyValueStore {
    private val values = HashMap<String, String>()
    override fun getString(key: String): String? = values[key]
    override fun putString(key: String, value: String) { values[key] = value }
    override fun remove(key: String) { values.remove(key) }
}

val SaveJson = Json {
    ignoreUnknownKeys = true
    encodeDefaults = true
    coerceInputValues = true
}

private val intMap = MapSerializer(String.serializer(), Int.serializer())

private fun KeyValueStore.readIntMap(key: String): Map<String, Int> =
    getString(key)?.let { runCatching { SaveJson.decodeFromString(intMap, it) }.getOrNull() } ?: emptyMap()

private fun KeyValueStore.writeIntMap(key: String, value: Map<String, Int>) {
    putString(key, SaveJson.encodeToString(intMap, value))
}

/** What the player has spent their trial points on. */
class PerkStore(private val store: KeyValueStore) {
    private val key = "perks.ranks"

    /** Perk id to how many points are in it. */
    val ranks: Map<String, Int> get() = store.readIntMap(key)

    fun rank(perk: PerkDefinition): Int = minOf(perk.maxRank, ranks[perk.id] ?: 0)

    /** Points spent in one branch, which is what gates the later perks in it. */
    fun spent(branch: PerkBranch): Int = PerkContent.inBranch(branch).sumOf { rank(it) }

    val spent: Int get() = PerkContent.all.sumOf { rank(it) }

    /** One point per trial beaten. */
    fun earned(completedTrials: Int): Int = completedTrials

    fun available(completedTrials: Int): Int = maxOf(0, earned(completedTrials) - spent)

    /** Whether a perk is open to be bought into. */
    fun canSpend(perk: PerkDefinition, completedTrials: Int): Boolean {
        if (available(completedTrials) <= 0) return false
        if (rank(perk) >= perk.maxRank) return false
        return spent(perk.branch) >= perk.requires
    }

    fun spend(perk: PerkDefinition, completedTrials: Int): Boolean {
        if (!canSpend(perk, completedTrials)) return false
        val updated = ranks.toMutableMap()
        updated[perk.id] = rank(perk) + 1
        store.writeIntMap(key, updated)
        return true
    }

    /** Refused only when doing so would leave another perk in the branch standing on fewer points than it needs. */
    fun canRefund(perk: PerkDefinition): Boolean {
        if (rank(perk) <= 0) return false
        val remaining = spent(perk.branch) - 1
        for (other in PerkContent.inBranch(perk.branch)) {
            if (rank(other) <= 0) continue
            val needs = if (other.id == perk.id && rank(other) == 1) 0 else other.requires
            if (remaining < needs) return false
        }
        return true
    }

    fun refund(perk: PerkDefinition): Boolean {
        if (!canRefund(perk)) return false
        val updated = ranks.toMutableMap()
        val next = rank(perk) - 1
        if (next == 0) updated.remove(perk.id) else updated[perk.id] = next
        store.writeIntMap(key, updated)
        return true
    }

    /** Hands every point back. Free and unlimited on purpose. */
    fun reset() {
        store.remove(key)
    }

    /** The bonuses the simulation actually reads. */
    val bonuses: ParkPerks
        get() {
            fun value(id: String): Double {
                val perk = PerkContent.definition(id) ?: return 0.0
                return perk.perRank * rank(perk)
            }
            return ParkPerks(
                extraArrivals = value("perk.arrivals"),
                guestHappiness = value("perk.mood"),
                guestSpending = value("perk.spending"),
                buildDiscount = value("perk.building"),
                wageDiscount = value("perk.wages"),
                stockDiscount = value("perk.stock"),
                wearReduction = value("perk.wear"),
                breakdownReduction = value("perk.safety"),
                ratingBonus = value("perk.reputation"),
            )
        }
}

/** Which trials the player has beaten, across every park they have played. */
class TrialProgressStore(private val store: KeyValueStore) {
    private val key = "trials.completed"

    /** Trial id to the earliest day it has been won on. */
    val completed: Map<String, Int> get() = store.readIntMap(key)

    fun isCompleted(trial: TrialDefinition): Boolean = completed[trial.id] != null

    fun bestDay(trial: TrialDefinition): Int? = completed[trial.id]

    /** The first rung is always open; each one after opens when the one before it has been beaten. */
    fun isUnlocked(trial: TrialDefinition): Boolean {
        if (trial.number <= 1) return true
        val previous = TrialContent.all.firstOrNull { it.number == trial.number - 1 } ?: return true
        return isCompleted(previous)
    }

    /** Records a win. Returns true when it is the first time. */
    fun recordWin(trial: TrialDefinition, day: Int): Boolean {
        val updated = completed.toMutableMap()
        val isFirst = updated[trial.id] == null
        updated[trial.id] = minOf(day, updated[trial.id] ?: day)
        store.writeIntMap(key, updated)
        return isFirst
    }

    val medalCount: Int get() = completed.size
}

/** A map the player drew. */
@Serializable
data class CustomMap(
    val id: UUID = UUID.randomUUID(),
    var name: String = "My Map",
    var layout: MapLayout = MapLayout(),
    var savedAt: Long = System.currentTimeMillis(),
) {
    /** How it appears alongside the maps that ship with the game. */
    val blueprint: MapBlueprint
        get() = MapBlueprint("custom.$id", name, "Your own map. ${(buildableShare * 100).toInt()}% of it can be built on.",
            estimatedDifficulty, layout, true)

    private val buildableShare: Double
        get() = layout.buildableCount.toDouble() / maxOf(1, layout.ground.size)

    /** A guess from how much land there is. */
    private val estimatedDifficulty: Int
        get() = when {
            buildableShare >= 0.75 -> 1
            buildableShare >= 0.55 -> 2
            buildableShare >= 0.40 -> 3
            buildableShare >= 0.25 -> 4
            else -> 5
        }
}

/** Keeps the player's maps in a file of their own, apart from the parks. */
class CustomMapStore(private val directory: File) {
    private val file get() = File(directory, "Maps/custom-maps.json")

    fun load(): List<CustomMap> {
        val text = runCatching { file.readText() }.getOrNull() ?: return emptyList()
        val maps = runCatching { SaveJson.decodeFromString(ListSerializer(CustomMap.serializer()), text) }.getOrNull()
            ?: return emptyList()
        return maps.sortedByDescending { it.savedAt }
    }

    fun save(maps: List<CustomMap>) {
        file.parentFile?.mkdirs()
        val tmp = File(file.path + ".tmp")
        tmp.writeText(SaveJson.encodeToString(ListSerializer(CustomMap.serializer()), maps))
        if (!tmp.renameTo(file)) {
            file.writeText(tmp.readText())
            tmp.delete()
        }
    }
}

/** Lightweight description of a save, written alongside the save itself so the menu can list slots cheaply. */
@Serializable
data class SaveSlotSummary(
    var slot: Int = 0,
    val parkName: String = "Park",
    val savedAt: Long = 0,
    val cash: Double = 0.0,
    val guestCount: Int = 0,
    val parkRating: Double = 0.0,
    val day: Int = 1,
    val mode: GameMode = GameMode.normal,
) {
    val id: Int get() = slot
}

/** Versioned envelope around [GameState]. */
@Serializable
class SaveGame(
    val version: Int = currentVersion,
    val savedAt: Long = System.currentTimeMillis(),
    val state: GameState,
) {
    val summary: SaveSlotSummary
        get() = SaveSlotSummary(0, state.parkName, savedAt, state.ledger.cash, state.guestCount,
            state.parkRating, state.clock.day, state.mode)

    companion object {
        /** 1: the first Android format. Saves are not shared with the iOS game. */
        const val currentVersion = 1
    }
}

class SaveError(message: String) : Exception(message)

/** Where a park lives on disk. */
sealed class SaveLocation {
    abstract val fileStem: String

    data class Slot(val number: Int) : SaveLocation() {
        override val fileStem: String get() = "slot-$number"
    }

    data class Trial(val id: String) : SaveLocation() {
        override val fileStem: String get() = "trial-$id"
    }
}

/**
 * Reads and writes parks as JSON. Each slot is two files: the park itself and a
 * small summary sidecar, so the main menu can list slots without decoding every guest.
 */
class SaveGameService(private val root: File) {

    companion object {
        const val slotCount = 3
    }

    private val directory get() = File(root, "Saves")
    private fun saveFile(location: SaveLocation) = File(directory, "${location.fileStem}.json")
    private fun summaryFile(location: SaveLocation) = File(directory, "${location.fileStem}.summary.json")

    private fun writeAtomically(file: File, text: String) {
        file.parentFile?.mkdirs()
        val tmp = File(file.path + ".tmp")
        tmp.writeText(text)
        if (!tmp.renameTo(file)) {
            file.writeText(text)
            tmp.delete()
        }
    }

    fun save(state: GameState, location: SaveLocation) {
        val save = SaveGame(state = state)
        writeAtomically(saveFile(location), SaveJson.encodeToString(SaveGame.serializer(), save))

        val summary = save.summary
        if (location is SaveLocation.Slot) summary.slot = location.number
        writeAtomically(summaryFile(location), SaveJson.encodeToString(SaveSlotSummary.serializer(), summary))
    }

    fun load(location: SaveLocation): GameState {
        val file = saveFile(location)
        if (!file.exists()) throw SaveError("That save slot is empty.")

        val save = SaveJson.decodeFromString(SaveGame.serializer(), file.readText())
        if (save.version > SaveGame.currentVersion) {
            throw SaveError("This park was saved by a newer version of the game (format ${save.version}).")
        }

        val state = save.state
        // Rebuilt rather than trusted, so retuning a decoration takes effect on old parks.
        state.refreshBeauty()
        return state
    }

    fun summary(location: SaveLocation): SaveSlotSummary? {
        val text = runCatching { summaryFile(location).readText() }.getOrNull() ?: return null
        return runCatching { SaveJson.decodeFromString(SaveSlotSummary.serializer(), text) }.getOrNull()
    }

    fun allSummaries(): Map<Int, SaveSlotSummary> {
        val result = HashMap<Int, SaveSlotSummary>()
        for (slot in 0 until slotCount) summary(SaveLocation.Slot(slot))?.let { result[slot] = it }
        return result
    }

    /** The run in progress for each trial that has one, by trial id. */
    fun trialSummaries(): Map<String, SaveSlotSummary> {
        val result = HashMap<String, SaveSlotSummary>()
        for (trial in TrialContent.all) summary(SaveLocation.Trial(trial.id))?.let { result[trial.id] = it }
        return result
    }

    fun hasSave(location: SaveLocation): Boolean = saveFile(location).exists()

    val mostRecentSlot: Int?
        get() = allSummaries().maxByOrNull { it.value.savedAt }?.key

    fun delete(location: SaveLocation) {
        saveFile(location).delete()
        summaryFile(location).delete()
    }
}
