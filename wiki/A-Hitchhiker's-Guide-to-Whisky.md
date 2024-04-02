## Welcome to Whisky

We're glad you're here. Here's how to get up and running in a breeze.

1. Download Whisky
    - Download the latest release [here](https://github.com/IsaacMarovitz/Whisky/releases)
2. Move Whisky to your Applications folder
3. Open Whisky
4. Follow on-screen instructions

**Everything is now installed!**

## Making your first bottle

Bottles are the bread and butter of Wine. Bottles are like little Windows filesystems, and they appear on your computer as a normal folder. In a bottle, you'll find programs, registry files, and everything else you need to install and configure your Windows 'machine'. Each bottle is self-contained and will only have the programs you installed in that bottle.

1. Press the plus button in the top right-hand corner
2. Give your bottle a name, and select the Windows version you want
3. Hit `Create` and wait a few seconds. When your bottle is ready, it'll appear in the list on the left-hand side

## Installing your first program

Programs are installed much like you would on a regular Windows machine.

1. Download the program you want to run. It should be the *Windows* version (`.exe` or `.msi`); 64-bit programs are preferable
2. Click on the bottle you want to install your program into
3. Press the `Run...` button in the bottom right
4. Navigate to where you downloaded your `.exe` or `.msi` file in Finder
5. Select the file and press `Open`

Whisky will then open and run the program. It may take a few seconds for the window to appear, so be patient.

## Configuring your bottle

In the `Config` menu of your bottle, you can adjust a number of parameters, including the Windows version and build the number of your bottle, enable and disable the Metal HUD, configure ESync, and open Wine's many configuration tools like the Control Panel, Registry Editor, and Wine Configuration dialogues.

## When should I make a new bottle?

The usual convention is to limit a bottle to one game, as dependencies and such can get messy with more installed in one place. If a game requires more extensive configuration to get working, it's usually a good idea to keep it contained. Overal, trust your judgment and separate where it feels right.

---

## Resolving common issues

Several things can lead to a program not working. The most common reasons are listed below.

|Problem|Solution|
|-------|---------|
|My game crashes due to "invalid instruction".|Your game is likely using [AVX](https://en.wikipedia.org/wiki/Advanced_Vector_Extensions) instructions. These are more common in console ports. AVX instructions are x86 specific, and Rosetta doesn't translate them. Unless you can find a way to disable or bypass them (check online), then your game won't work.|
|I want to play a competitive multiplayer game, but it won't load.|Competitive multiplayer games, especially battle royales and other FPS games (like PUBG, Fortnite, Apex Legends, Valorant), often have some form of driver-level anti-cheat. These won't work under Wine.|
|My DirectX 9 game has graphical issues, or doesn't work at all.|DirectX 9 games are handled through Wine's own `wined3d`. Whisky focuses on modern titles using DX11 or 12, and you may run into issues with DX9 games. CrossOver is a better choice in this scenario, as it runs on Wine 8 instead of Wine 7, and has a more up-to-date version of `wined3d`. If you're not sure what Graphics API your game is using, you can check on the [PCGamingWiki](https://www.pcgamingwiki.com/wiki/Home).|
|My game crashes out of the box, or complains about missing dependencies.|Make sure to check Wine's [AppDB](https://appdb.winehq.org/) and [ProtonDB](https://www.protondb.com/), which can often provide information on the necessary workarounds or Winetricks you need to use to get your game running. If you can't find anything or you are unable to make it work, make an issue.|

## What's where?

|Item|Location|
|----|--------|
|GPTK|`~/Library/Application Support/com.isaacmarovitz.Whisky/Libraries`|
|Bottles|`~/Library/Containers/com.isaacmarovitz.Whisky/Bottles`|
|Logs|`~/Library/Logs/com.isaacmarovitz.Whisky`|
|WhiskyCMD|`/usr/local/bin/whisky`|

---
## Whisky or CrossOver?

There are a lot of questions about which is better, here's an easy chart:

|Feature|Whisky|CrossOver|
|-------|------|---------|
|Entirely Open-Source|✅|❌|
|Free Updates Forever|✅|❌|
|MSync|✅|✅|
|ESync|✅|✅|
|DirectX 12 Support|✅|✅|
|Automated Installation|❌|✅|
|Denuvo Support|❌|✅|
|EA App Support|❌|✅|
|Battle.net Support|❌|✅|
|Ubisoft Connect Support|❌|✅|
|OOTB GStreamer Support|❌|✅|
|Wine 9 Support|❌|✅|
|Proper Technical Support|❌|✅|
|Future Updates to Wine|❌|✅|

TLDR; CrossOver supports more apps than Whisky, and provides a more seamless user experience when Wine doesn't want to work out of the box. Which ever is best will depend on your needs and use case. 