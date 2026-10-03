# Daylock

Daylock is an iPhone app that keeps a set of photos you choose and moves to the next one every day at midnight.

iOS does not let an app change the lock screen wallpaper on its own. Daylock does the part an app is allowed to do, and then asks you to turn on Photo Shuffle once. After that, the lock screen rotates through your photos every day without opening the app.

## What you can do

- Choose photos from your gallery.
- Put them in order. The first photo is the start of the cycle.
- See today's photo on a lock screen preview, with tomorrow's photo underneath.
- Keep a Photos album named **Daylock** filled with copies of those photos. Your originals stay where they are.
- Add a home screen widget that shows today's photo in color.
- Add a lock screen widget that shows which photo number is scheduled. Lock screen widgets cannot draw a full-color photo, so this one is a counter, not the wallpaper.

## Put the photos on the lock screen

1. Open the project in Xcode and run Daylock on your iPhone.
2. Choose the photos.
3. Open the **Lock Screen** tab and tap **Update Album**. Allow photo access.
4. On the iPhone, open **Settings → Wallpaper → Add New Wallpaper → Photo Shuffle**.
5. Choose the **Daylock** album, set the frequency to **Daily**, and set it as the lock screen.

Photo Shuffle picks from that album on its own. It changes every day, but it does not follow the order in the Library tab. The Today tab and the home screen widget do follow that order.

To force today's exact photo, use the Shortcuts app: a Time of Day automation with **Get Today's Daylock Photo**, then **Set Wallpaper** for the lock screen. iOS may ask you to confirm.

## Open the project

You need Xcode 15 or later and an iPhone running iOS 17 or later. The Wallpaper settings screen is limited in the Simulator, so check Photo Shuffle on a device. The app, album, and widget can be tried in the Simulator.

1. Open `ios/Daylock/Daylock.xcodeproj`.
2. Select the **Daylock** target, then **Signing & Capabilities**, and choose your Team.
3. Do the same for the **DaylockWidget** target.
4. Run Daylock.

The app group `group.com.luminous42.daylock` is already in both entitlements files and in `Shared/AppGroup.swift`. If your team cannot use that identifier, change it in all three places, then clean the build. The home screen widget only sees photos when that group is shared by both targets.

## Try the daily change without waiting

In a Debug build, open **Library → Order** and tap **Pretend it's tomorrow**. That moves the schedule forward one day.
