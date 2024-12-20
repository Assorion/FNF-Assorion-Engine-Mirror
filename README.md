# Friday Night Funkin' Assorion Engine!

<img src="https://codeberg.org/Assorion/FNF-Assorion-Engine/raw/branch/main/art/assorion-engine.png"/>

-------------------------------------------------------------
 <div align="center">
 <a href="#"><img src="https://img.shields.io/gitea/stars/Assorion/FNF-Assorion-Engine?gitea_url=https%3A%2F%2Fcodeberg.org&style=for-the-badge&logoSize=4&color=06b59c"/></a>
 <img src="https://img.shields.io/gitea/last-commit/Assorion/FNF-Assorion-Engine?gitea_url=https%3A%2F%2Fcodeberg.org&style=for-the-badge&color=06b59c"/</a> 
 <img src="https://img.shields.io/gitea/v/release/Assorion/FNF-Assorion-Engine?gitea_url=https%3A%2F%2Fcodeberg.org&style=for-the-badge&color=06b59c"/></a>
 </div>
 <div align="center">
 <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/releases"><img src="https://img.shields.io/badge/Windows_Build-Released-blue?style=for-the-badge&color=e1b100"/></a>
 <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/releases"><img src="https://img.shields.io/badge/Linux_Build-Released-blue?style=for-the-badge&color=e1b100"/></a>
 <a href="https://github.com/Assorion/FNF-Assorion-Engine/actions/workflows/HTML5.yml"><img src="https://img.shields.io/badge/Web_Build-Testing-blue?style=for-the-badge&color=e1b100"/></a>  
 </div>

-------------------------------------------------------------
<div align="center">
 
**Table of Contents**
</div>
<div align="center">
 
┃ [**`• What is Assorion?`**](#what-is-assorion-engine) ┃ [**`• Important Notes`**](#important-notes-roadmap) ┃ [**`• Compiling`**](#compiling) ┃ [**`• Min Reqs`**](#minimum-requirements) ┃ <a href="https://assorion.github.io/wiki/">**`• Wiki (WIP)`**</a> ┃ <a href="https://discord.gg/nbhWWxKxTe">**`• Discord`**</a> ┃

</div>

-------------------------------------------------------------
 
# ⚝ | What is Assorion Engine?

Assorion Engine is a minimalist engine, focusing on modding primarily the source code, as opposed to external scripting languages. 
Most original <a href="https://ninja-muffin24.itch.io/funkin">Friday Night Funkin'</a> code has been replaced / revised with more efficient, optimized code & modular code.

Assorion Engine doesn't have mods folder capabilities planned nor will it be implemented. 
In addition, things such as cutscenes, events, discordRPC, etc, will have to be added yourself. 
Though, Assorion Engine does have several <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine#branches">branches</a> planned with more features soon.

Assorion is a very simple engine and thus, it may not receive many feature updates; Though it will continue to have bug fixes and optimizations. 
It is worth noting that this is a pure engine. Assorion does not contain the base game but instead contains a short demo. 

## ⚡ | Why choose Assorion Engine?

1. Assorion Engine is incredibly fast and stable
2. Assorion's Code is much better streamlined, and much easier to mod
3. Assorion has an emphasis on simplicity, over bloat
4. Assorion is actively maintained, adding many fixes

# 🗒️ | Important Notes/RoadMap

- Assorion Engine is based off <a href="https://github.com/FunkinCrew/Funkin/releases/tag/v0.2.6">`0.2.6`</a> version of the base game, though has been radically altered
- Assorion's chart editor has been completely overhauled
- Assorion allows skipping most transitions by hitting enter twice
- Botplay does not count scoring or health. This is intentional to stop cheating
- Chart speed changes depending on BPM; This is a known early bug that will never be fixed
- Ratings (E:G Sick or Bad), losing and gaining health, and menu positions are inaccurate to the base game
- Porting other mods is very hard. Charts, characters, and weeks are handled much differently
- The song can have as many characters as it needs, instead of the usual 3 (opponent, GF, BF)
- Songs folder has been merged with the Data folder for convenience
  
 **RoadMap**
* [X] Move away from Github
* [X] Re-work Dialogue
* [X] Fix minor annoyances/bugs
* [ ] Improve Wiki/Documentation
 
#### **Branches**

> <details>
> <summary>Branch ideas list</summary>
> <table>
> <tr>
> <td>
>
>   | `Assorion Branch's`                                | `Windows` | `Linux` | `HTML5 (WEB)`     |
>   |--------------------------------------------------|---------|-------|-----------------|
>   | <a href="#">Assorion-Main</a>                                    | ✓       | ✓     | ⍻              |
>   | <a href="#">Assorion-Base</a>                                    | ☓       | ☓     | ☓              |
>   | <a href="#">Assorion-3D</a>                                      | ☓       | ☓     | ☓              |
></td>
></tr>
></table>
></details>
Until the **primary Assorion Engine repository** is finalized, the following branches listed above will **not** be worked on.

## 🖼️ | Screenshots and Builds

Take a look at <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/src/branch/main/.github/Screenshots.md">`art/screenshots.md`</a>. 

If you want to try out the engine you can acquire releases <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/releases">here</a>.

# 🛠 | Compiling

#### **For Windows:**
- Install <a href="https://haxe.org/">`Haxe`</a>
- Run `haxelib setup` in CMD. Using the defaults is fine
- Install [libraries](#libraries) below
- Run `haxelib run lime setup` in CMD
- Download and extract the <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/releases">latest release's</a> source code
- Setup <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/src/branch/main/.github/MinGW-Setup.md">MinGW-w64</a> and make sure the PATH is set correctly
- Test to make sure both the `gcc` and `g++` commands work in CMD
- Run `lime test windows -D HXCPP_MINGW` in CMD. Make sure it's in the project root folder, not the source folder

#### **For Linux:**
- Install Haxe using your package manager
- Run `haxelib setup` in your terminal
- Install [libraries](#libraries) below
- Run `haxelib run lime setup`
- Download and extract the <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/releases">latest release's</a> source code
- Make sure both `gcc` and `g++` commands work. If not, install GCC using your package manager
- Run `lime test linux` in your terminal. Make sure it's in the project root folder, not the source folder

#### **Libraries:**  
Run `haxelib install <library name>` replacing `<library name>` with these libraries below:
- `hxcpp`
- `lime`
- `openfl`
- `flixel`
- `flixel-addons`
- `flixel-ui`

#### **If you're confused:**  
Follow a YouTube guide, or the <a href="https://github.com/FunkinCrew/Funkin/tree/v0.2.7.1#build-instructions">base game instructions</a> on compiling. It's recommended to use <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/src/branch/main/.github/MinGW-Setup.md">**`MinGW-w64`**</a> however the compiler may error out, if that happens then just use **`Visual Studio's Clang Compiler`**.  

## 💻 | Minimum Requirements

The engine *should* be able to run smoothly (max framerate) on at least an **`Intel Core2 Duo E6850`** with an **`AMD Radeon R5 240`**. 
The engine runs *perfectly* on an **`Intel i7-2600`**, and an **`Nvidia GT 1030`** at 1440p.

> [!tip]
> Any games performance will decrease with higher resolutions.  
> Un-fullscreen and resize the game if encountering performance issues.

These should be the lowest minimum requirements to run the engine:

- **Windows**: Windows 7 64-Bit or Higher
  
- **Linux**: Any 64-Bit Distro With GLibC 2.36 or Equivilant
  
- **Processor**: Intel Celeron (SSE to SSE4 with MMX) or Higher
  
- **Memory**: 512MB - 1GB of Ram. 256mb VRam or Higher
  
- **Storage**: ~70MB Available Space


# ⚠️ | License
**<a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/src/branch/main/LICENSE">GPL-3.0 Public License</a>, Version 3, 29 June 2007**

Under the terms of the <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/src/branch/main/LICENSE">GPL-3.0 Public License</a>, Assorion Engine will be free and open source and anyone using this project thereafter acknowledges being bound under the <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/src/branch/main/LICENSE">GPL-3.0 Public License's</a> conditions, and making their variant of the project open source.

Project authored and maintained by <a href="https://codeberg.org/Legendary-Candice-Joe">***Legendary Candice Joe***</a>.
