package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import com.wickedstudios.wonderlot.app.GraphicsMode
import com.wickedstudios.wonderlot.app.GraphicsBudget
import com.wickedstudios.wonderlot.app.DeviceProfile
import com.wickedstudios.wonderlot.BuildConfig
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.border
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.wickedstudios.wonderlot.AppInfo
import com.wickedstudios.wonderlot.TrialContent
import com.wickedstudios.wonderlot.app.AppRouter
import com.wickedstudios.wonderlot.app.AppServices
import com.wickedstudios.wonderlot.gfx.SpriteFactory

/** Why the game exists, and what it will never do to the people playing it. */
@Composable
fun AboutSheet(onDismiss: () -> Unit) {
    val version = remember { BuildConfig.VERSION_NAME + " (" + BuildConfig.VERSION_CODE + ")" }
    BottomSheet("About", onDismiss, tall = true) {
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Label(AppInfo.gameName, size = 34.sp, weight = FontWeight.ExtraBold, color = Theme.money)
            Label(AppInfo.taglines.first(), size = 14.sp, weight = FontWeight.SemiBold, color = Theme.textSecondary)
            Label("Version $version", size = 11.sp, weight = FontWeight.Medium, color = Theme.textSecondary)
        }

        AboutHeading("Why I made this")
        AboutParagraph(
            "Some of my favourite hours as a kid were spent staring at a patch of empty grass on a screen, trying to figure out " +
                "where the first ride should go. Laying a path, watching the first guests wander in, holding my breath the first " +
                "time a coaster I built actually made it round the track. Those games taught me patience, a little bit of maths, " +
                "and how much fun it is to make something out of nothing.",
        )
        AboutParagraph(
            "${AppInfo.gameName} is my love letter to those theme park and ride simulators. Somewhere along the way, a lot of " +
                "games in this genre stopped feeling like toys you could get lost in and started feeling like shops you were " +
                "standing inside. I wanted to build the game I remember: one where the only thing standing between you and your " +
                "dream park is your own imagination.",
        )

        AboutHeading("The things I wanted back")
        Memory("square.dashed", "An empty lot and a blank slate", "Starting with nothing but a gate and a bit of path, and making it yours.")
        Memory("person.3.fill", "Guests with opinions", "Little people who get hungry, get lost, love a ride and let you know when the queue is too long.")
        Memory("point.topleft.down.curvedto.point.bottomright.up", "Building your own coaster", "Laying track one piece at a time and watching the train run the thing you designed.")
        Memory("chart.line.uptrend.xyaxis", "A park that has to pay its way", "The quiet satisfaction of balancing the books and watching the numbers turn green.")
        Memory("hourglass.bottomhalf.filled", "Losing an afternoon", "Just one more ride. Just one more path. Just one more day.")

        AboutHeading("My promise to you")
        Promise("hand.raised.fill", Theme.accent, "No forced ads. Ever.",
            "Nothing will pop up and interrupt your park. If you ever see an ad in ${AppInfo.gameName}, it is because you chose to watch one in exchange for an in-game boost, and you never have to.")
        Promise("dollarsign.circle.fill", Theme.money, "No in-game currency.",
            "No gems, no tokens, no bundles of coins. I do not believe in them. The money in your park is money you earned by running it well.")
        Promise("lock.fill", Theme.textSecondary, "Your answer to the privacy question is yours.",
            "Say no to personalised adverts and nothing about the game changes. Every ride, map, trial and medal stays exactly as open as it was.")
        Promise("lock.open.fill", Theme.accentWarm, "Everything is playable without spending a cent.",
            "Every ride, every map, every trial and every medal can be reached just by playing. Nothing is locked behind a purchase.")

        Column(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Color.White.copy(alpha = 0.08f))
                .border(1.dp, Theme.money.copy(alpha = 0.35f), RoundedCornerShape(14.dp)).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            AboutParagraph(
                "Thank you for playing. Whether you are building your hundredth park or placing your very first path, I hope " +
                    "${AppInfo.gameName} gives you a little of the wonder those old games gave me.",
            )
            Label("Now go build something great.", size = 16.sp, weight = FontWeight.ExtraBold)
        }
    }
}

@Composable
private fun AboutHeading(text: String) {
    Label(text.uppercase(), size = 11.sp, weight = FontWeight.ExtraBold, color = Theme.money, modifier = Modifier.padding(top = 8.dp))
}

@Composable
private fun AboutParagraph(text: String) {
    Label(text, size = 15.sp, weight = FontWeight.Medium, color = Color.White.copy(alpha = 0.9f))
}

@Composable
private fun Memory(symbol: String, title: String, detail: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        SymbolIcon(symbol, Theme.accent, 18.dp, Modifier.padding(top = 2.dp))
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Label(title, size = 14.sp, weight = FontWeight.Bold)
            Label(detail, size = 13.sp, weight = FontWeight.Medium, color = Theme.textSecondary)
        }
    }
}

@Composable
private fun Promise(symbol: String, tint: Color, title: String, detail: String) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Color.White.copy(alpha = 0.07f)).padding(12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.size(38.dp).clip(CircleShape).background(tint.copy(alpha = 0.18f)), contentAlignment = Alignment.Center) {
            SymbolIcon(symbol, tint, 20.dp)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Label(title, size = 15.sp, weight = FontWeight.ExtraBold)
            Label(detail, size = 13.sp, weight = FontWeight.Medium, color = Color.White.copy(alpha = 0.8f))
        }
    }
}

/** How hard the park is asked to work this phone. It describes the phone, not a park, and is saved with neither. */
@Composable
fun GraphicsSheet(services: AppServices, onDismiss: () -> Unit) {
    var mode by remember { mutableStateOf(GraphicsBudget.mode) }
    val reduced = GraphicsBudget.isReduced

    BottomSheet("Graphics", onDismiss, tall = true) {
        SectionCard("Detail") {
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                for (option in GraphicsMode.entries) {
                    Chip(option.title, mode == option, { mode = option; GraphicsBudget.mode = option }, Modifier.weight(1f))
                }
            }
            Label(
                when (mode) {
                    GraphicsMode.automatic ->
                        if (DeviceProfile.isLegacyHardware) "This phone is a lighter one, so the park is drawn the lighter way."
                        else "This phone can take the full park, so nothing is turned down."
                    GraphicsMode.full -> "The full park, whatever the phone. On an older one this may not hold a steady frame rate."
                    GraphicsMode.compatibility -> "The lighter park, whatever the phone. Steadier, and kinder to the battery."
                },
                size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary,
            )
        }

        SectionCard("What compatibility changes") {
            Change("speedometer", "Half the frame rate", "Thirty frames a second, which an older phone holds steadily where it cannot hold sixty.")
            Change("person.2.fill", "Fewer figures drawn", "Only so many guests are drawn at once.")
            Change("bubble.left.fill", "Fewer thought bubbles", "Three at a time instead of ten.")
            Change("photo.on.rectangle", "Smaller artwork", "Rides, guests and tiles are drawn at a lower resolution, which is a fraction of the memory.")
            Change("play.rectangle", "A still title screen", "No live park running behind the main menu.")
        }

        SectionCard("What it does not change") {
            Label(
                "Nothing about the park itself. Every guest still walks, queues, spends and complains; rides wear and break at the same rate; " +
                    "the management screen shows the same numbers; and a Park Trial is exactly as hard either way. This setting only decides how much of it is drawn.",
                size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary,
            )
        }

        SectionCard("This phone") {
            StatRow("Hardware", DeviceProfile.summary)
            StatRow("Drawing", if (reduced) "Compatibility" else "Full detail")
        }

        Label(
            "The frame rate and the figures change straight away. The artwork resolution is set when the game starts, so switching here shows fully the next time you open ${AppInfo.gameName}.",
            size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary,
        )
    }
}

@Composable
private fun Change(symbol: String, title: String, detail: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        SymbolIcon(symbol, Theme.textSecondary, 16.dp, Modifier.padding(top = 2.dp))
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Label(title, size = 14.sp, weight = FontWeight.SemiBold)
            Label(detail, size = 12.sp, weight = FontWeight.Normal, color = Theme.textSecondary)
        }
    }
}
