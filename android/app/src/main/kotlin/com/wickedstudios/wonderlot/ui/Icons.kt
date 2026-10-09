package com.wickedstudios.wonderlot.ui

import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * The game's data names its symbols after the iOS symbol set. This maps each
 * to the nearest Material icon, so the catalogue stays one shared list.
 */
fun symbolIcon(name: String): ImageVector = when (name) {
    "hammer.fill" -> Icons.Filled.Build
    "wrench.and.screwdriver.fill" -> Icons.Filled.Build
    "chart.bar.fill" -> Icons.Filled.BarChart
    "chart.line.uptrend.xyaxis" -> Icons.Filled.TrendingUp
    "person.2.badge.gearshape.fill" -> Icons.Filled.ManageAccounts
    "person.2.fill", "person.3.fill", "person.3.sequence.fill" -> Icons.Filled.People
    "person.2.badge.plus" -> Icons.Filled.PersonAdd
    "person.badge.minus" -> Icons.Filled.PersonRemove
    "person.badge.clock.fill" -> Icons.Filled.ManageAccounts
    "person.fill", "figure.stand" -> Icons.Filled.Person
    "figure.walk", "figure.walk.arrival" -> Icons.Filled.DirectionsWalk
    "figure.seated.side" -> Icons.Filled.EventSeat
    "figure.2.and.child.holdinghands" -> Icons.Filled.FamilyRestroom
    "dollarsign.circle.fill", "banknote.fill", "banknote" -> Icons.Filled.MonetizationOn
    "square.and.arrow.down" -> Icons.Filled.Save
    "wallet.bifold", "wallet.bifold.fill", "creditcard.fill" -> Icons.Filled.CreditCard
    "line.3.horizontal" -> Icons.Filled.Menu
    "bell.fill", "bell.badge.fill" -> Icons.Filled.Notifications
    "bell.slash.fill" -> Icons.Filled.NotificationsOff
    "gearshape.fill", "gearshape.2.fill", "slider.horizontal.3" -> Icons.Filled.Settings
    "face.smiling", "face.smiling.inverse" -> Icons.Filled.SentimentSatisfied
    "face.dashed" -> Icons.Filled.SentimentDissatisfied
    "star.fill", "star.circle.fill", "star.bubble.fill" -> Icons.Filled.Star
    "ticket", "ticket.fill" -> Icons.Filled.ConfirmationNumber
    "clock", "clock.fill", "timer", "hourglass.bottomhalf.filled" -> Icons.Filled.Schedule
    "xmark", "xmark.circle.fill", "xmark.seal.fill" -> Icons.Filled.Close
    "plus" -> Icons.Filled.Add
    "speedometer" -> Icons.Filled.Speed
    "checkmark", "checkmark.circle.fill", "checkmark.seal.fill" -> Icons.Filled.CheckCircle
    "chevron.down" -> Icons.Filled.KeyboardArrowDown
    "chevron.up" -> Icons.Filled.KeyboardArrowUp
    "chevron.right" -> Icons.Filled.ChevronRight
    "arrow.left" -> Icons.Filled.ArrowBack
    "arrow.right" -> Icons.Filled.ArrowForward
    "arrow.up", "arrow.up.circle.fill" -> Icons.Filled.ArrowUpward
    "arrow.down" -> Icons.Filled.ArrowDownward
    "arrow.counterclockwise", "arrow.uturn.backward" -> Icons.Filled.Undo
    "arrow.triangle.turn.up.right.diamond.fill" -> Icons.Filled.TurnRight
    "rotate.right", "rotate.right.fill" -> Icons.Filled.RotateRight
    "location.fill" -> Icons.Filled.Place
    "lock.fill" -> Icons.Filled.Lock
    "lock.open.fill" -> Icons.Filled.LockOpen
    "pause.circle.fill" -> Icons.Filled.PauseCircle
    "play.circle.fill", "play.fill", "play.rectangle", "play.rectangle.fill" -> Icons.Filled.PlayArrow
    "trash", "trash.fill" -> Icons.Filled.Delete
    "tree.fill" -> Icons.Filled.Park
    "lightbulb", "lightbulb.fill" -> Icons.Filled.Lightbulb
    "flag.checkered" -> Icons.Filled.Flag
    "trophy.fill", "crown.fill", "rosette", "seal.fill" -> Icons.Filled.EmojiEvents
    "pawprint.fill" -> Icons.Filled.Pets
    "shield.fill", "shield.lefthalf.filled", "shield.slash.fill" -> Icons.Filled.Security
    "sailboat.fill" -> Icons.Filled.Sailing
    "mountain.2.fill" -> Icons.Filled.Landscape
    "water.waves", "drop.fill" -> Icons.Filled.WaterDrop
    "bus.doubledecker.fill" -> Icons.Filled.DirectionsBus
    "car.fill" -> Icons.Filled.DirectionsCar
    "tram.fill", "coaster.station" -> Icons.Filled.Train
    "fork.knife" -> Icons.Filled.Restaurant
    "cup.and.saucer.fill" -> Icons.Filled.LocalCafe
    "cart.fill" -> Icons.Filled.ShoppingCart
    "exclamationmark.triangle.fill" -> Icons.Filled.Warning
    "exclamationmark.octagon.fill", "exclamationmark.circle.fill" -> Icons.Filled.Error
    "info.circle.fill" -> Icons.Filled.Info
    "hare.fill" -> Icons.Filled.Speed
    "bolt.fill" -> Icons.Filled.Bolt
    "sparkles" -> Icons.Filled.AutoAwesome
    "heart.fill" -> Icons.Filled.Favorite
    "pencil", "pencil.and.outline" -> Icons.Filled.Edit
    "calendar" -> Icons.Filled.CalendarMonth
    "building.2.fill" -> Icons.Filled.Business
    "gift.fill" -> Icons.Filled.CardGiftcard
    "target" -> Icons.Filled.TrackChanges
    "theatermasks.fill" -> Icons.Filled.Theaters
    "graduationcap.fill" -> Icons.Filled.School
    "leaf.fill" -> Icons.Filled.Eco
    "infinity" -> Icons.Filled.AllInclusive
    "hand.wave.fill", "hand.raised.fill", "hand.tap.fill", "hand.draw", "hand.draw.fill",
    "hand.point.up.braille.fill", "hand.thumbsdown.fill" -> Icons.Filled.TouchApp
    "externaldrive.fill" -> Icons.Filled.Save
    "photo.on.rectangle" -> Icons.Filled.Photo
    "shippingbox.fill" -> Icons.Filled.Inventory2
    "shuffle" -> Icons.Filled.Shuffle
    "scissors" -> Icons.Filled.ContentCut
    "chair.lounge.fill" -> Icons.Filled.EventSeat
    "door.left.hand.open" -> Icons.Filled.MeetingRoom
    "beach.umbrella.fill" -> Icons.Filled.BeachAccess
    "light.beacon.max.fill" -> Icons.Filled.Lightbulb
    "square.grid.3x3", "square.grid.2x2.fill" -> Icons.Filled.GridView
    "square.dashed", "square.on.square" -> Icons.Filled.CropSquare
    "point.topleft.down.curvedto.point.bottomright.up" -> Icons.Filled.Timeline
    "iphone.gen3.radiowaves.left.and.right" -> Icons.Filled.PhoneAndroid
    "bubble.left.fill" -> Icons.Filled.ChatBubble
    "dollarsign.circle" -> Icons.Filled.MonetizationOn
    else -> Icons.Filled.Circle
}

/** An icon drawn from a game symbol name. */
@Composable
fun SymbolIcon(name: String, tint: Color = Theme.textPrimary, size: Dp = 16.dp, modifier: Modifier = Modifier) {
    Icon(symbolIcon(name), contentDescription = null, tint = tint, modifier = modifier.size(size))
}
