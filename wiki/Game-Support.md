Many games will work out of the box, but some are more tricky. Things that frequently cause issues with Wine are 3rd party launchers, anti-cheats, and online services. Some of these games have workarounds, and some do not.

## Palworld
- Install in Steam as normal
- Right-click > Properties...
- Add `-dx12` as launch option
- Start Palworld from Steam as normal
- When prompted about incompatible drivers, click `No`

> [!NOTE] 
> Some small graphical issues remain, such as black eye shaders, however the game is fully playable.

## Cities: Skylines 2
- Install in Steam as normal
- Go back to Whisky, and press File > Kill All Bottles
- On your bottle click `Winetricks...`
- Install the following tricks in the following order\
  `dotnet48 win10`

> [!NOTE]
> This will require user interaction and will likely take a rather long time to complete

- Follow the instructions to patch your game here: https://github.com/manolz1/cities2-gptk-fix
- Start Cities: Skylines 2 from Steam as normal

> [!WARNING]
> - Tabbing out will cause the game to become unresponsive and require it to be restarted. Do **not** change window focus while playing.
> - Subsequent launches may fail to open the Paradox Launcher. This can be resolved temporarily by deleting the `Paradox Interactive` folder in `Program Files`. Reinstalling the launcher may also be required.

## Counter-Strike 2
- Install in Steam as normal
- Right-click > Properties...
- Add `-nojoy` as launch option

> [!IMPORTANT]
> This will disable controller input, but improves the FPS from 10 -> 100

- Start CS2 from Steam as normal

## Elden Ring
- Install in Steam as normal
- In Whisky, find `elden_ring.exe` in the Program list and press `Show in Finder`
- Rename `start_protected_game.exe` to something else, and rename `elden_ring.exe` to `start_protected_game.exe`

> [!IMPORTANT]
> This will disable online play features

- Start Elden Ring from Steam as normal

## Diablo IV - Steam Version
- Go to Config
  - Change Windows Version to 19042 (Make sure to press enter to submit the change)
  - Change Enhanced Sync mode to `ESync`
- Install in Steam as normal
- Install Diablo IV as normal
- Delete `dstorage.dll` at `Program Files(x86)/steam/steamapps/common/Diablo IV`
- Start Diablo IV as normal

## Diablo IV - Battle.net Version
- Go to Config
  - Change Windows Version to 19042 (Make sure to press enter to submit the change)
  - Change Enhanced Sync mode to `ESync`
- Install Battle.net
- On the Battle.net login screen, press the cog icon in the top right. Click on `Advanced`, and disable `Use hardware acceleration when available`
- Go back to Whisky. Click on `File` > `Kill All Bottles`
- Restart Battle.net
- Login and install Diablo IV as normal

## Star Wars Jedi: Fallen Order
- Install in Steam as normal
- In Whisky, find `SwGame-Win64-Shipping.exe` in the Program list and run it

## Horizon Zero Dawn
- Install Horizon Zero Dawn as normal
- On your bottle click `Config` then `Open Registry Editor`
- Navigate to `HKEY_LOCAL_MACHINE > Hardware > Description > System > CentralProcessor > 0`
- Double-click to edit the `~MHz` key
- Change the base to `Decimal` and type the value `1100`
- Press `OK`, then close the Registry Editor
- Start Horizon Zero Dawn as normal

## Skyrim SE
- Install in Steam as normal
- In Whisky, find `SkyrimSELauncher.exe` in the Program list and press `Show in Finder`
- Rename `SkyrimSELauncher.exe` to something else, and rename `SkyrimSE.exe` to `SkyrimSELauncher.exe`
- On your bottle click `Winetricks...`
- Install the following tricks in the following order\
  `dotnet48 vcrun2019 dxvk1103 d3dx11_43 d3dcompiler_43 d3dcompiler_47 faudio`

> [!NOTE]
> This will require user interaction and will likely take a rather long time to complete

- Start Skyrim from Steam as normal

## Elite Dangerous
- Install Steam
- Install Elite Dangerous
- Follow setup instructions here: https://github.com/rfvgyhn/min-ed-launcher#steam
- Modify `gamesettings.json` in `users/crossover/AppData/Local/min-ed-launcher` and add the following line\
  `"gameStartDelay": 5,`
- Run Elite Dangerous as normal

## Anime Game: Transportation Edition
- Install anime game as normal
- `Rm9sbG93IHRoZSBpbnN0cnVjdGlvbnMgYXQ6IGh0dHBzOi8vY29kZWJlcmcub3JnL21rcnN5bTEvamFkZWl0ZQ==`

## Anime Game
> [!NOTE]
> It is recommended to use specific launchers to make the patching process easier.

- Install anime game as normal
- `Rm9sbG93IHRoZSBpbnN0cnVjdGlvbnMgYXQ6IGh0dHBzOi8vbm90YWJ1Zy5vcmcvS3JvY2svZGF3bg==`