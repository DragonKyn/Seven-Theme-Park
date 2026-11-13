package com.wickedstudios.wonderlot

/**
 * The holiday event's rides and decorations. Kept apart from the everyday catalogue so the whole event can be read,
 * balanced and switched off in one place. A few are locked behind a trial reward; see [HolidayRewards].
 */
object HolidayContent {

    private val rides: List<AttractionDefinition> = listOf(
        // Christmas
        AttractionDefinition(
            id = "ride.xmas.reindeercarousel",
            displayName = "Reindeer Carousel",
            summary = "Every horse has antlers, and every antler has a bell. A gentle one the whole family can share.",
            purchasePrice = 3_000.0, capacity = 14, rideDuration = 48.0, loadDuration = 12.0,
            excitement = 24.0, nausea = 5.0, maintenanceRate = 0.010, operatingCostPerCycle = 4.0,
            footprint = GridSize(3, 3), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.reindeerCarousel, ParkColour.red, ParkColour.cream, ParkColour.green),
            group = RideGroup.holiday, seasonal = true,
        ),
        AttractionDefinition(
            id = "ride.xmas.sleighride",
            displayName = "Sleigh Ride",
            summary = "Round the hill in Santa's sleigh. Faster than it looks, and the bells never stop.",
            purchasePrice = 6_800.0, capacity = 12, rideDuration = 70.0, loadDuration = 16.0,
            excitement = 55.0, nausea = 28.0, maintenanceRate = 0.022, operatingCostPerCycle = 9.0,
            footprint = GridSize(5, 4), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.sleighRide, ParkColour.red, ParkColour.green, ParkColour.amber),
            group = RideGroup.holiday, seasonal = true,
        ),
        AttractionDefinition(
            id = "ride.xmas.candycoaster",
            displayName = "Candy Cane Coaster",
            summary = "A coaster on candy-striped track with a lift hill that smells of peppermint. Earned in the Twelve Days.",
            purchasePrice = 16_500.0, capacity = 16, rideDuration = 95.0, loadDuration = 20.0,
            excitement = 84.0, nausea = 40.0, maintenanceRate = 0.036, operatingCostPerCycle = 19.0,
            footprint = GridSize(6, 4), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.candyCoaster, ParkColour.red, ParkColour.white, ParkColour.green),
            group = RideGroup.holiday, seasonal = true,
        ),
        AttractionDefinition(
            id = "ride.xmas.snowglobe",
            displayName = "Snow Globe Spinner",
            summary = "Spin inside a glass dome while it snows on you. Pretty, and rougher on the stomach than it looks.",
            purchasePrice = 3_800.0, capacity = 12, rideDuration = 42.0, loadDuration = 12.0,
            excitement = 34.0, nausea = 50.0, maintenanceRate = 0.013, operatingCostPerCycle = 5.0,
            footprint = GridSize(3, 3), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.snowGlobe, ParkColour.cyan, ParkColour.white, ParkColour.red),
            group = RideGroup.holiday, seasonal = true,
        ),
        AttractionDefinition(
            id = "ride.xmas.polarexpress",
            displayName = "North Pole Express",
            summary = "A little train round a tree the size of a house. Takes a crowd, and the crowd sings.",
            purchasePrice = 5_200.0, capacity = 24, rideDuration = 85.0, loadDuration = 18.0,
            excitement = 38.0, nausea = 8.0, maintenanceRate = 0.014, operatingCostPerCycle = 8.0,
            footprint = GridSize(4, 4), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.polarExpress, ParkColour.red, ParkColour.green, ParkColour.amber),
            group = RideGroup.holiday, seasonal = true,
        ),
        AttractionDefinition(
            id = "ride.xmas.gingerbread",
            displayName = "Gingerbread Manor",
            summary = "A slow ride through a house made of cake, with icing on the roof and a witch in the kitchen.",
            purchasePrice = 7_800.0, capacity = 20, rideDuration = 90.0, loadDuration = 18.0,
            excitement = 46.0, nausea = 6.0, maintenanceRate = 0.015, operatingCostPerCycle = 9.0,
            footprint = GridSize(4, 4), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.gingerbreadManor, ParkColour.brown, ParkColour.white, ParkColour.red),
            group = RideGroup.holiday, seasonal = true,
        ),
        AttractionDefinition(
            id = "ride.xmas.startopper",
            displayName = "Star Topper Drop",
            summary = "Up the tree, a pause beside the star, then all the way down. Earned in the Twelve Days.",
            purchasePrice = 9_200.0, capacity = 12, rideDuration = 50.0, loadDuration = 16.0,
            excitement = 80.0, nausea = 52.0, maintenanceRate = 0.033, operatingCostPerCycle = 13.0,
            footprint = GridSize(3, 3), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.starTopper, ParkColour.green, ParkColour.amber, ParkColour.red),
            group = RideGroup.holiday, seasonal = true,
        ),

        // New Year's
        AttractionDefinition(
            id = "ride.newyear.countdownwheel",
            displayName = "Countdown Wheel",
            summary = "A big wheel with a clock at its heart. Every lap counts down to midnight.",
            purchasePrice = 7_000.0, capacity = 24, rideDuration = 100.0, loadDuration = 18.0,
            excitement = 30.0, nausea = 4.0, maintenanceRate = 0.012, operatingCostPerCycle = 10.0,
            footprint = GridSize(4, 4), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.countdownWheel, ParkColour.indigo, ParkColour.amber, ParkColour.white),
            group = RideGroup.holiday, seasonal = true,
        ),
        AttractionDefinition(
            id = "ride.newyear.confettiswing",
            displayName = "Confetti Swing",
            summary = "Chairs fly out on chains and a cannon fires paper at every turn.",
            purchasePrice = 4_800.0, capacity = 16, rideDuration = 55.0, loadDuration = 14.0,
            excitement = 48.0, nausea = 36.0, maintenanceRate = 0.018, operatingCostPerCycle = 7.0,
            footprint = GridSize(3, 3), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.confettiSwing, ParkColour.violet, ParkColour.amber, ParkColour.pink),
            group = RideGroup.holiday, seasonal = true,
        ),
        AttractionDefinition(
            id = "ride.newyear.balldrop",
            displayName = "Ball Drop Tower",
            summary = "Rise to the top with a glittering ball, wait for the count, and drop at midnight.",
            purchasePrice = 8_800.0, capacity = 12, rideDuration = 50.0, loadDuration = 16.0,
            excitement = 76.0, nausea = 48.0, maintenanceRate = 0.031, operatingCostPerCycle = 12.0,
            footprint = GridSize(3, 3), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.ballDrop, ParkColour.indigo, ParkColour.white, ParkColour.amber),
            group = RideGroup.holiday, seasonal = true,
        ),
        AttractionDefinition(
            id = "ride.newyear.starburst",
            displayName = "Starburst Coaster",
            summary = "The finale: a coaster that ends every lap in a burst of sparks. Earned in the Twelve Days.",
            purchasePrice = 17_500.0, capacity = 18, rideDuration = 100.0, loadDuration = 20.0,
            excitement = 86.0, nausea = 44.0, maintenanceRate = 0.037, operatingCostPerCycle = 20.0,
            footprint = GridSize(6, 4), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.starburstCoaster, ParkColour.indigo, ParkColour.amber, ParkColour.pink),
            group = RideGroup.holiday, seasonal = true,
        ),
    )

    val attractions: List<AttractionDefinition> by lazy { rides + skatingRink }

    /** The ice rink: a skating ride on the holiday shelf, with its skaters going round it. */
    val skatingRink = AttractionDefinition(
        id = "ride.xmas.skatingrink",
        displayName = "Skating Rink",
        summary = "A sheet of ice with a rail round it and a crowd going the same way. Gentle, cheap to run, and everybody wants a go.",
        purchasePrice = 4_200.0, capacity = 18, rideDuration = 75.0, loadDuration = 14.0,
        excitement = 36.0, nausea = 4.0, maintenanceRate = 0.008, operatingCostPerCycle = 5.0,
        footprint = GridSize(5, 4), unlockLevel = 1,
        appearance = BuildingAppearance(BuildingMotif.skatingRink, ParkColour.cyan, ParkColour.white, ParkColour.red),
        group = RideGroup.holiday, seasonal = true,
    )

    /** The seasonal food venues. All take the usual shop upgrades. */
    val facilities: List<FacilityDefinition> = listOf(
        FacilityDefinition(
            id = "shop.xmas.snowcone",
            displayName = "Snow Cone Cart",
            summary = "Shaved ice in a paper cone with a choice of syrups. Earned in the Twelve Days. Cold, cheap and very popular with children.",
            kind = FacilityKind.drink,
            purchasePrice = 700.0,
            defaultPrice = 3.5,
            unitCost = 0.7,
            referencePrice = 4.0,
            serviceDuration = 4.0,
            simultaneousCapacity = 1,
            queueCapacity = 8,
            relief = NeedRelief(hunger = 4.0, thirst = 42.0, bathroom = -10.0, happiness = 10.0),
            footprint = GridSize(1, 1),
            unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.snowConeCart, ParkColour.cyan, ParkColour.white, ParkColour.pink),
            seasonal = true,
        ),
        FacilityDefinition(
            id = "shop.xmas.hotcocoa",
            displayName = "Hot Chocolate Stand",
            summary = "A steaming cup with marshmallows on top. Cheap, quick, and guests come back for a second.",
            kind = FacilityKind.drink,
            purchasePrice = 1_100.0,
            defaultPrice = 3.5,
            unitCost = 1.0,
            referencePrice = 4.5,
            serviceDuration = 5.0,
            simultaneousCapacity = 1,
            queueCapacity = 10,
            relief = NeedRelief(hunger = 6.0, thirst = 60.0, bathroom = -16.0, happiness = 9.0),
            footprint = GridSize(2, 2),
            unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.hotCocoaStand, ParkColour.brown, ParkColour.cream, ParkColour.red),
            seasonal = true,
        ),
        FacilityDefinition(
            id = "shop.xmas.candy",
            displayName = "Candy Stand",
            summary = "Candy canes, gumdrops and humbugs by the bag. A sweet tooth is a good customer.",
            kind = FacilityKind.food,
            purchasePrice = 1_000.0,
            defaultPrice = 3.0,
            unitCost = 0.9,
            referencePrice = 3.5,
            serviceDuration = 4.0,
            simultaneousCapacity = 1,
            queueCapacity = 10,
            relief = NeedRelief(hunger = 16.0, thirst = -6.0, bathroom = -4.0, happiness = 12.0),
            footprint = GridSize(2, 2),
            unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.candyStand, ParkColour.red, ParkColour.white, ParkColour.green),
            seasonal = true,
        ),
    )

    val scenery: List<SceneryDefinition> = listOf(
        SceneryDefinition(
            id = "scenery.xmas.canefence", displayName = "Candy Cane Fence",
            summary = "Crossed candy canes with a striped rail between them. A cheap way to edge a walkway or fence off a lawn.",
            purchasePrice = 60.0, beauty = 14.0, beautyRadius = 1, footprint = GridSize(1, 1), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.candyCaneFence, ParkColour.red, ParkColour.white, ParkColour.green),
            seasonal = true,
        ),
        SceneryDefinition(
            id = "scenery.xmas.lightstrand", displayName = "Holiday Lights",
            summary = "A twinkling strand of coloured bulbs between two stakes. Put them wherever the park needs cheering up.",
            purchasePrice = 70.0, beauty = 18.0, beautyRadius = 2, footprint = GridSize(1, 1), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.holidayLights, ParkColour.green, ParkColour.amber, ParkColour.red),
            seasonal = true,
        ),
        SceneryDefinition(
            id = "scenery.xmas.snowfamily", displayName = "Snow Family",
            summary = "A tall snowman, a short one and a very small one, in matching scarves. Earned in the Twelve Days.",
            purchasePrice = 240.0, beauty = 30.0, beautyRadius = 3, footprint = GridSize(2, 1), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.snowFamily, ParkColour.white, ParkColour.red, ParkColour.orange),
            seasonal = true,
        ),
        SceneryDefinition(
            id = "scenery.xmas.tree", displayName = "Christmas Tree",
            summary = "A fir hung with baubles and topped with a star. Nothing says December like it.",
            purchasePrice = 120.0, beauty = 24.0, beautyRadius = 2, footprint = GridSize(1, 1), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.xmasTree, ParkColour.green, ParkColour.red, ParkColour.amber),
            seasonal = true,
        ),
        SceneryDefinition(
            id = "scenery.xmas.snowman", displayName = "Snowman",
            summary = "A carrot nose, a scarf and a very patient expression.",
            purchasePrice = 90.0, beauty = 20.0, beautyRadius = 2, footprint = GridSize(1, 1), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.snowman, ParkColour.white, ParkColour.red, ParkColour.orange),
            seasonal = true,
        ),
        SceneryDefinition(
            id = "scenery.xmas.wreath", displayName = "Wreath Arch",
            summary = "A garland arch over the walkway, with a red bow at the top.",
            purchasePrice = 260.0, beauty = 26.0, beautyRadius = 3, footprint = GridSize(1, 1), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.wreathArch, ParkColour.green, ParkColour.red, ParkColour.amber),
            spansWalkway = true, seasonal = true,
        ),
        SceneryDefinition(
            id = "scenery.xmas.gifts", displayName = "Gift Stack",
            summary = "A tower of wrapped presents. Earned in the Twelve Days.",
            purchasePrice = 140.0, beauty = 24.0, beautyRadius = 2, footprint = GridSize(1, 1), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.giftStack, ParkColour.red, ParkColour.green, ParkColour.amber),
            seasonal = true,
        ),
        SceneryDefinition(
            id = "scenery.xmas.lights", displayName = "String-Light Pole",
            summary = "A tall pole with warm lights looped down it. Earned in the Twelve Days.",
            purchasePrice = 180.0, beauty = 26.0, beautyRadius = 3, footprint = GridSize(1, 1), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.lightPole, ParkColour.brown, ParkColour.amber, ParkColour.red),
            seasonal = true,
        ),
        SceneryDefinition(
            id = "scenery.xmas.candycane", displayName = "Candy Cane Post",
            summary = "A giant striped cane to mark a corner. Earned in the Twelve Days.",
            purchasePrice = 110.0, beauty = 22.0, beautyRadius = 2, footprint = GridSize(1, 1), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.candyCanePost, ParkColour.red, ParkColour.white, ParkColour.green),
            seasonal = true,
        ),
        SceneryDefinition(
            id = "scenery.newyear.fireworks", displayName = "Fireworks Stand",
            summary = "A rack of rockets that never quite goes off. Earned in the Twelve Days.",
            purchasePrice = 240.0, beauty = 30.0, beautyRadius = 3, footprint = GridSize(2, 1), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.fireworkStand, ParkColour.indigo, ParkColour.amber, ParkColour.pink),
            seasonal = true,
        ),
        SceneryDefinition(
            id = "scenery.newyear.clock", displayName = "Countdown Clock",
            summary = "A tall clock counting down to midnight. Earned in the Twelve Days.",
            purchasePrice = 320.0, beauty = 34.0, beautyRadius = 3, footprint = GridSize(1, 1), unlockLevel = 1,
            appearance = BuildingAppearance(BuildingMotif.countdownClock, ParkColour.indigo, ParkColour.amber, ParkColour.white),
            seasonal = true,
        ),
    )

    /** Whether the player may build this right now: the event is on, and any reward it needs is held. */
    fun canBuild(definition: BuildableDefinition, season: Boolean, holiday: HolidayStore?): Boolean {
        if (!definition.seasonal) return true
        if (!season) return false
        return holiday?.canUse(definition.id) ?: (HolidayRewards.requiredFor(definition.id) == null)
    }

    /** Whether an act can be hired right now. */
    fun canHire(act: EntertainerAct, season: Boolean, holiday: HolidayStore?): Boolean {
        if (!act.isSeasonal) return true
        if (!season) return false
        val key = act.unlockKey ?: return true
        return holiday?.canUse(key) ?: false
    }
}
