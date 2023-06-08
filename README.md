<div align="center">

  # Whisky 🥃 
  *Wine but a bit stronger*
  
  ![](https://img.shields.io/github/actions/workflow/status/IsaacMarovitz/Whisky/SwiftLint.yml?style=for-the-badge)
  [![](https://img.shields.io/discord/1115955071549702235?style=for-the-badge)](https://discord.gg/WAgj8arM)
</div>

<img width="650" alt="Screenshot 2023-03-31 at 17 14 00" src="https://user-images.githubusercontent.com/42140194/229232488-dbad85f4-cecb-45e1-a182-f737fe9d2b1f.png">

Familiar UI that integrates seamlessly with macOS

<div align="right">
  <img width="650" alt="Screenshot 2023-03-31 at 17 14 22" src="https://user-images.githubusercontent.com/42140194/229232557-07f78a79-f695-45f6-be45-15a5b2f3c053.png">

  One-click bottle creation and management
</div>

<img width="650" alt="debug" src="https://user-images.githubusercontent.com/42140194/229176642-57b80801-d29b-4123-b1c2-f3b31408ffc6.png">

Debug and profile with ease

---

Whisky provides a clean and easy to use graphical wrapper for Wine built in native SwiftUI. You can make and manage bottles, install and run Windows apps and games, and unlock the full potential of your Mac with no technical knowledge required. Whisky is built on top of CrossOver 22.1.1, and Apple's own `Game Porting Toolkit`.

Special thanks to [Gcenx](https://github.com/Gcenx), without your amazing work Whisky wouldn't be possible.

---

# FAQ

### Do I need macOS Sonoma?

Yes, you do for now till 13.3 support is done.

### Do I need to pay for the macOS beta?

No, you do not, just log into the Apple developer website, and the download should appear in settings.

### The direct download link for the toolkit doesn't work

Make sure you're logged in to the Apple Developer website. If it still won't work use an [indirect link](https://developer.apple.com/download/all/?q=porting).

### Do I need to follow the steps in the toolkit's README?

No, you don't, in fact you shouldn't follow them.

### macOS says Whisky is damaged and can't be opened

Run `xattr -d com.apple.quarantine path-to-whisky`

### Whisky isn't displaying anything

There is an issue where the libraries for font rendering are not properly bundled yet. You will need to install freetype.


## Setup your development and Homebrew environment
- Ensure the Command Line Tools for Xcode 15 beta are installed. Visit https://developer.apple.com/downloads to download these tools.
- Enter an x86_64 shell to continue the following steps in a Rosetta environment. All subsequent commands should be run within this shell.
arch -x86_64 zsh

- Install the x86_64 version of Homebrew if you don't already have it.
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

- Install freetype `/usr/local/bin/brew install freetype`
- 
- The Game Porting Toolkit runs under Rosetta 2. Ensure that Rosetta 2 is installed.
`softwareupdate --install-rosetta`

- Make sure the brew command is on your path:
which brew
If this command does not print `/usr/local/bin/brew`, you must either modify your PATH to put `/usr/local/bin` first, or fully specify the path to brew in the subsequent commands.
- Tap the Apple Homebrew tap, which can be found at https://github.com/apple:

brew tap apple/apple http://github.com/apple/homebrew-apple
- Install the game-porting-toolkit formula. This formula downloads and compiles several large software projects. How long this takes will depend on the speed of your computer.
`brew -v install apple/apple/game-porting-toolkit`
- If during installation you see an error such as “Error: game-porting-toolkit: unknown or unsupported macOS version: :dunno”, your version of Homebrew doesn’t have macOS Sonoma support. Update to the latest version of Homebrew and try again.
`brew update brew -v install apple/apple/game-porting-toolkit`

## run this when done
 - `ditto /Volumes/Game\ Porting\ Toolkit-1.0/lib/ brew --prefix game-porting-toolkit /lib/`

## Running steam 
 - If you are trying to run steam add this to arguments `-noreactlogin` 
