package com.wickedstudios.wonderlot.app

import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.wickedstudios.wonderlot.BoostCenter
import com.wickedstudios.wonderlot.CustomMap
import com.wickedstudios.wonderlot.CustomMapStore
import com.wickedstudios.wonderlot.GameController
import com.wickedstudios.wonderlot.GameMode
import com.wickedstudios.wonderlot.KeyValueStore
import com.wickedstudios.wonderlot.MapBlueprint
import com.wickedstudios.wonderlot.MapCatalogue
import com.wickedstudios.wonderlot.PerkStore
import com.wickedstudios.wonderlot.SaveGameService
import com.wickedstudios.wonderlot.SaveLocation
import com.wickedstudios.wonderlot.SaveSlotSummary
import com.wickedstudios.wonderlot.TrialDefinition
import com.wickedstudios.wonderlot.TrialProgressStore
import com.wickedstudios.wonderlot.TutorialDirector
import com.wickedstudios.wonderlot.TutorialStore
import com.wickedstudios.wonderlot.newGameState
import java.util.UUID

/** SharedPreferences, behind the interface the game core uses for anything that outlives a single park. */
class PrefsStore(private val prefs: SharedPreferences) : KeyValueStore {
    override fun getString(key: String): String? = prefs.getString(key, null)
    override fun putString(key: String, value: String) = prefs.edit().putString(key, value).apply()
    override fun remove(key: String) = prefs.edit().remove(key).apply()
}

class WonderLotApp : Application() {
    lateinit var services: AppServices
        private set

    override fun onCreate() {
        super.onCreate()
        services = AppServices(this)
        GraphicsBudget.init(this, services.store)
    }
}

/** Everything the game needs from the platform, built once. */
class AppServices(context: Context) {
    val store: KeyValueStore = PrefsStore(context.getSharedPreferences("wonderlot", Context.MODE_PRIVATE))
    val saveService = SaveGameService(context.filesDir)
    val mapStore = CustomMapStore(context.filesDir)
    val boosts = BoostCenter(store)
    val ads = com.wickedstudios.wonderlot.ads.RewardedAdCenter(context.applicationContext)
    val perkStore = PerkStore(store)
    val trialProgress = TrialProgressStore(store)
    val tutorial = TutorialDirector(TutorialStore(store))

    val controllerServices = GameController.Services(saveService, boosts, perkStore, trialProgress, tutorial)

    fun demoController(): GameController = GameController.demo(controllerServices)
}

/** Owns which screen is on show and the lifetime of the running park. */
class AppRouter(private val services: AppServices) {

    sealed class Screen {
        data object Menu : Screen()
        class Game(val controller: GameController) : Screen()
    }

    var screen: Screen by mutableStateOf(Screen.Menu)
        private set
    val slotSummaries = mutableStateOf<Map<Int, SaveSlotSummary>>(emptyMap())
    val customMaps = mutableStateListOf<CustomMap>()
    val completedTrials = mutableStateOf<Map<String, Int>>(emptyMap())
    val trialRuns = mutableStateOf<Map<String, SaveSlotSummary>>(emptyMap())
    var errorMessage by mutableStateOf<String?>(null)

    /** The map editor, when open. It lives at the root so it covers the whole screen, system bars included. */
    class EditorRequest(val map: com.wickedstudios.wonderlot.CustomMap?, val onSaved: (com.wickedstudios.wonderlot.CustomMap) -> Unit)
    var editor by mutableStateOf<EditorRequest?>(null)

    /** Set when a finished trial sends the player back to the ladder, so the menu opens straight onto it. */
    var opensLadderOnMenu by mutableStateOf(false)

    init {
        refreshSlots()
        customMaps.addAll(services.mapStore.load())
        refreshTrials()
    }

    // region Trials

    fun refreshTrials() {
        completedTrials.value = services.trialProgress.completed
        trialRuns.value = services.saveService.trialSummaries()
    }

    fun isTrialUnlocked(trial: TrialDefinition): Boolean = services.trialProgress.isUnlocked(trial)

    /** Starts a trial from day one, replacing any run already on the go. */
    fun startTrial(trial: TrialDefinition) {
        val controller = newController(
            name = trial.title, mode = GameMode.trial, layout = trial.map.layout,
            cash = trial.startingCash, trialID = trial.id, location = SaveLocation.Trial(trial.id),
        )
        trial.maxAdmission?.let {
            controller.setAdmissionPrice(minOf(it, com.wickedstudios.wonderlot.Balance.defaultAdmissionPrice))
        }
        controller.save()
        refreshTrials()
        screen = Screen.Game(controller)
    }

    /** Picks a trial up where the player left it. */
    fun resumeTrial(trial: TrialDefinition) {
        try {
            val state = services.saveService.load(SaveLocation.Trial(trial.id))
            screen = Screen.Game(GameController(state, SaveLocation.Trial(trial.id), services.controllerServices))
        } catch (e: Exception) {
            errorMessage = e.message
        }
    }

    // endregion

    // region Maps

    /** Every map a park can be started on: the ones that ship, then the player's own, newest first. */
    val availableMaps: List<MapBlueprint> get() = MapCatalogue.all + customMaps.map { it.blueprint }

    fun customMap(blueprintID: String): CustomMap? = customMaps.firstOrNull { it.blueprint.id == blueprintID }

    fun saveCustomMap(map: CustomMap) {
        val updated = customMaps.filter { it.id != map.id }.toMutableList()
        updated.add(0, map)
        persistMaps(updated)
    }

    fun deleteCustomMap(id: UUID) = persistMaps(customMaps.filter { it.id != id })

    private fun persistMaps(maps: List<CustomMap>) {
        try {
            services.mapStore.save(maps)
            customMaps.clear()
            customMaps.addAll(maps)
        } catch (e: Exception) {
            errorMessage = "The map could not be saved: ${e.message}"
        }
    }

    // endregion

    fun refreshSlots() {
        slotSummaries.value = services.saveService.allSummaries()
    }

    val mostRecentSlot: Int? get() = services.saveService.mostRecentSlot

    private fun newController(
        name: String, mode: GameMode, layout: com.wickedstudios.wonderlot.MapLayout?, cash: Double,
        trialID: String?, location: SaveLocation,
    ): GameController {
        val state = newGameState(name, mode, layout, cash, trialID)
        return GameController(state, location, services.controllerServices)
    }

    fun startNewGame(name: String, mode: GameMode, map: MapBlueprint, slot: Int) {
        val trimmed = name.trim()
        val parkName = trimmed.ifEmpty { "New Park" }
        val controller = newController(parkName, mode, map.layout, com.wickedstudios.wonderlot.Balance.startingCash, null, SaveLocation.Slot(slot))
        controller.save()
        refreshSlots()
        screen = Screen.Game(controller)
    }

    fun loadGame(slot: Int) {
        try {
            val state = services.saveService.load(SaveLocation.Slot(slot))
            screen = Screen.Game(GameController(state, SaveLocation.Slot(slot), services.controllerServices))
        } catch (e: Exception) {
            errorMessage = e.message
        }
    }

    fun deleteSave(slot: Int) {
        services.saveService.delete(SaveLocation.Slot(slot))
        refreshSlots()
    }

    /** Saves and returns to the menu. */
    fun exitToMenu() {
        (screen as? Screen.Game)?.controller?.save()
        refreshSlots()
        refreshTrials()
        screen = Screen.Menu
    }

    fun saveActiveGame() {
        (screen as? Screen.Game)?.controller?.saveOnBackground()
    }
}
