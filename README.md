# Friday Night Funkin' Assorion Engine!

<img src="https://codeberg.org/Assorion/FNF-Assorion-Engine/raw/branch/main/art/assorion/logoWithText.png"/>

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
 
┃ [**`• What is Assorion?`**](#what-is-assorion-engine) ┃ [**`• Important Notes`**](#important-notes) ┃ [**`• Compiling`**](#compiling) ┃ <a href="https://assorion.github.io/wiki/">**`• Wiki (WIP)`**</a> ┃ <a href="https://discord.gg/nbhWWxKxTe">**`• Discord`**</a> ┃

</div>

-------------------------------------------------------------

# ⚝ | What is Assorion Engine?

Assorion Engine is a simple and minimal Friday Night Funkin' engine with a focus having the tiniest and easiest to mod source code possible in a HaxeFlixel-based engine.
Every source file has had work done to it, so the code will look completely different to the base game source code.

The main goal is to create a dynamic and malleable codebase, where making big changes will not cause (m)any unintended side effects.
As such, Assorion Engine doesn't have many features that are standard for other engines; Things such as Discord RPC, cutscenes, or mods folder capabilities. Since said features are often not used in every mod released, it makes more sense to only implement what a specific mod requires.

## ⚡ | Why choose Assorion Engine?

**1. Clearer variable names:**  
Assorion Engine has more verbose variable and function names, making it easier to understand what the code is doing.
The engine also uses "camel case" for every variable, function, and even the assets, making it more consistent.

**2. Much smaller code:**  
There is not as much code to sift through with Assorion Engine, as there's only 4 folders within the source directory
and each source file tends to be quite small. E.G: PlayState being under 600 lines of code.

**3. Easier to compile:**  
Assorion Engine is very lenient when it comes to compiling. There are only 5 dependiences (6 if HXCPP is counted) which
the engine needs to compile. The game will also compile with Haxe 4.0.0 up to Haxe 4.3.6, and Flixel 5.0.0 up to latest.

**4. Less hacky:**  
There is an emphasis on avoiding weird compiler tricks or modifying the underlying Flixel, Lime, or OpenFL source files.
Assorion Engine is simple and straight forward, without having to modify the source code for it's dependencies.

**5. More portable:**  
With less dependencies comes less problems when porting. Assorion has been compiled for Windows and Linux (32bit and 64bit),
MacOS High Sierra, <a href="https://codeberg.org/Assorion/FNF-Assorion-XP-Compatible">Windows 2000</a>, and even NetBSD.

# 🗒️ | Important Notes

- Assorion Engine is based off <a href="https://github.com/FunkinCrew/Funkin/releases/tag/v0.2.6">`0.2.6`</a> version of the base game, though has been radically altered
- Assorion's chart editor has been completely overhauled
- Assorion allows skipping most transitions by hitting enter twice
- Botplay does not count scoring or health. This is intentional to stop cheating
- Chart speed will change depending on BPM; This is a known early bug that will never be fixed
- Ratings (E:G Sick or Bad), losing and gaining health, and menu positions are inaccurate to the base game
- Porting other mods is very hard. Charts, characters, and weeks are handled much differently
- The players in a song are handled dynamically, and are not hardcoded to Opponent, BF, GF.
  
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

Take a look at <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/src/branch/main/.github/Screenshots.md">screenshots here</a>. 

If you want to try out the engine you can acquire releases <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/releases">here</a>.

# 🛠 | Compiling

#### **For Windows:**
- Install <a href="https://haxe.org/">`Haxe`</a>
- Run `haxelib setup` in CMD. Using the defaults is fine
- Install [libraries](#libraries) below
- Run `haxelib run lime setup` in CMD
- Clone (or download) the source code
- Install Visual Studio (tested on 2017) with the Windows SDK, MSVC, and Clang Compiler
- Open CMD within the project root folder
- Run `lime test windows` in CMD

#### **For Linux:**
- Install Haxe using your package manager
- Run `haxelib setup` in your terminal
- Install [libraries](#libraries) below
- Run `haxelib run lime setup`
- Clone (or download) the source code
- Make sure both `gcc` and `g++` commands work. If not, install GCC using your package manager
- Open your preferred terminal within the project root folder
- Run `lime test linux` in your terminal

#### **Libraries:**  
Run `haxelib install <library name>` replacing `<library name>` with these libraries below:
- `hxcpp`
- `lime`
- `openfl`
- `flixel`
- `flixel-addons`
- `flixel-ui`

#### **If you're confused:**  
The <a href="https://github.com/FunkinCrew/Funkin/tree/v0.2.7.1#build-instructions">original game's compiling instructions</a> should be attiquete. There are also a few helpful resources on YouTube and other places if needed.

# ⚠️ | License
**<a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/src/branch/main/LICENSE">GPL-3.0 Public License</a>, Version 3, 29 June 2007**

Under the terms of the <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/src/branch/main/LICENSE">GPL-3.0 Public License</a>, Assorion Engine will be free and open source and anyone using this project thereafter acknowledges being bound under the <a href="https://codeberg.org/Assorion/FNF-Assorion-Engine/src/branch/main/LICENSE">GPL-3.0 Public License's</a> conditions, and making their variant of the project open source.

Project authored and maintained by <a href="https://codeberg.org/Legendary-Candice-Joe">***Legendary Candice Joe***</a>.
