<div align="center">

  # Whisky 🥃 
  *Wine but a bit stronger*
  
  ![](https://img.shields.io/github/actions/workflow/status/IsaacMarovitz/Whisky/SwiftLint.yml?style=for-the-badge)
  [![](https://img.shields.io/discord/1115955071549702235?style=for-the-badge)](https://discord.gg/CsqAfs9CnM)
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

Yes, you do.

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

- Open an x86 terminal session with `arch -x86_64 zsh`
- Install brew `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` (If you run into issues, let me know)
- Install freetype `/usr/local/bin/brew install freetype`
- Restart Whisky and remake the bottle
