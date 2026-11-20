# Half-Life for iPhone / iPad

GitHub Actions builds an iOS app from the open-source
[Xash3D FWGS](https://github.com/FWGS/xash3d-fwgs) engine and
[hlsdk-portable](https://github.com/FWGS/hlsdk-portable) (Half-Life game code),
with an on-screen **analog joystick** layout as the default controls.

This repo contains **no Valve game files**. You add your own Steam copy on your PC.

## Build

Actions tab → **Build Half-Life IPA** → *Run workflow* (it also runs on every push to `main`).
After about 10–20 minutes, download the `HalfLife-engine-ipa` artifact and unzip it to get
`HalfLife-engine.ipa`.

## Add your Half-Life files (on your PC)

```powershell
.\scripts\add-game-files.ps1 -Ipa "$HOME\Downloads\HalfLife-engine.ipa"
```

This writes `HalfLife.ipa` next to it with your Steam `valve` folder built in
(default Steam path; pass `-HalfLife <folder>` if yours is elsewhere).

## Install

The IPA is unsigned. Sideload it with Sideloadly, AltStore/SideStore (free Apple ID,
re-sign every 7 days) or TrollStore where supported.

On launch the engine shows a small "Launch Options" box. Tap **Start**.

## Controls

| Where | Control |
|---|---|
| Bottom left | Analog joystick: move (push further to run) |
| Right half of screen | Swipe to aim (works while holding Fire) |
| Bottom right | Fire, Alt-fire, Jump, Crouch, Reload, Use |
| Left, above stick | Previous / next weapon |
| Top middle | Weapon number keys |
| Top bar | Menu, layout editor (gear), Flashlight, Quick save, Quick load |

Tap the gear to move or resize any button. The layout lives in
[`touch/hl1_joystick.cfg`](touch/hl1_joystick.cfg). Bluetooth controllers (Xbox, PlayStation, MFi)
are also supported by the engine.

Saves and settings go to the app's folder in the Files app (On My iPhone → Half-Life).
