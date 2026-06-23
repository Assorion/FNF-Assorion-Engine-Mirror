## Version 1.0.0 (Beta)

Established the first release of this engine.

Initially it was called "MKG" (a meaningless acronym), which was quickly re-branded to Assorion in the next release.

## Version 1.1.0 (Major)

This was Assorion's first real release. It has a lot of major changes/improvements over it's first version so there's a lot to document here.

1. **Tuned up repository (credits to Barzil)**
- Improved the README.md
- Added GitHub issue template for bug reports
2. **Enabled stack tracing on debug builds**
- This greatly helps in finding the cause of crashes
- Not enabled in release builds however, due to performance concerns
3. **Added 'embedded' assets folder**
- Before, only the fonts folder was embedded
- You may optionally add anything you want to the embedded folder
4. **Trimmed the whitespace of many assets**
- Many animated assets have tons of transparent pixels that are never visible
- Trimming this greatly helps in reducing memory footprint + improving performance
5. **Replaced Donate button with GitHub button**
- If you feel like supporting the original Funkin' team, you're still encouraged to donate
6. **Renamed the 'songs&data' folder to just 'songs-data'**
- It was originally merged since I had believed that song assets should live next to their charts
- It was renamed because the '&' could potentially be problematic
7. **Added caching options**
- Default Persist allows sprites that were loaded off disk to permanently stay in memory, thus never having to be loaded again
- Launch Sprites not only enables Default Persist, but will load all sprites in the assets folder on launch, leading to seamless game-play
8. **Added dialogue and preset dialogue text files**
- Dialogue is very common in most mods, and was added to Assorion for the sake of ease
- The preset files are used to help demonstrate how to optionally write your own dialogue
9. **Added default icons, as well as settings icons**
10. **Added delayed event system to MusicBeatState**
- These events allow you to postpone a function call by a set amount of seconds
- Turns out Flixel has this functionality built in, but isn't used by the engine
11. **Refactored/Revised lots of base code**
- This includes re-writing large sections of code (a common thing for Assorion)
- This helps fix lots of bugs
- And helps make the code simpler and easier to read
- Filtered out a lot of the immature cursing of the original code
- Fixed up the GameOverSubstate
12. **Better support for different note types**
- Adding mine notes is simply a property (instead of having to be implemented by the modder)
- This also allows assigning callbacks to missing or hitting notes
13. **Improvements to Freeplay**
- Now each song has an icon preview as specified in a custom text file
- Allow previewing each song by pressing the space bar, and listening to the instrumental by backing out (yes that was never a bug)
14. **Improvements to OptionsState**
- Each option is now given a description
- There are now icons for the different categories
15. **Other minor enhancements**
- This list does not detail everything, but only the things that are worth listing

## Version 1.1.1 (Minor)

This is a minor update that fixes a handful of problems

1. **Exclude FireAlpaca's project files from the compiled build**
- Most art assets were made/edited with FireAlpaca, and the project files were put in the assets folder in source
- Now these assets are no longer copied into the assets of the release build
2. **Minor fix-ups to the README**
3. **Trimmed note assets so that black lines no longer show up on the strums**
- This was caused by Adobe animate being a very cool and awesome and great program (**/s**) and packing the assets too close
4. **Updated repository link in the Main Menu**
5. **Fixed Chart Editor permanently ignoring any inputs**
- This happened if the section UI was recreated while interacting with a type-in box

## Version 1.1.2 (Minor)

Even more minor bug fixing update

1. **Fixed being unable to delete notes in 1/3 snap level**
- This was caused because the Y level of the cursor wouldn't match the Y level of the note due to floating point weirdness
- The fix was to simply round the Y coordinate
2. **Added Assorion.txt**
- This takes the place of the 'do NOT readme.txt' file
3. **Improved navigation**
- Some transitions may now be skipped
- Unfortunately not all transitions may be skipped in this version

## Version 1.2.0 (Major)

This is Assorion's next major release! And brings a brand new song with it!

1. **Mild adjustments to assets**
- Centered character icons
- Trimmed note assets a little
- Small wording changes to Assorion.txt, and README.md
- More many inside jokes added to the introText
- Added optional delay to dialogue text
2. **New composition for demo song**
- Composed by yours truly
- Also includes a re-chart
3. **Many bug fixes**
- Fixed 'stepHit' not being called if the step was 0
- Adjusted 'songPosition' to follow audio offset
- Fixed Flixel's camera lerp being broken on different framerates
- Fixed dialogue substate not enabling antialiasing on portraits
4. **Allow backing out on death screen**
- Before: Hitting your back bind would do absolutely nothing LOL
5. **Mild note changes**
- Trimming assets (as mentioned prior)
- Remove unneeded animations if hold or hold-end note
- Move 'NoteType' struct to the top of the file (have no idea why I put it at the bottom originally)
- Add optional range multiplier option to note types
6. **Updates to the pause menu**
- The pause menu is now no longer rendered on top of the game, instead it uses a screenshot of PlayState. In practice this wasn't really worth it, and greatly increased the complexity of the code
- Added information such as song, difficulty, bot-play status, etc to the bottom of the screen
7. **Major changes to PlayState**
- Refactored lots of code
- Remove dependence on FlxTimer
- Load countdown sounds before countdown countdown starts
- Force 'noteData' in a 0-3 range
- ""Fixed"" song being longer than sections in chart causing crashes. The fix was incredibly stupid at the time, but at least it works!
- Properly fixed input system bugs relating to note destruction
- Experimental integrated screenshot functionality was added
- etc
8. **Allow caching TXT and JSON files**
- Although not too useful with default persist, it allows the game to cache them on launch, thus not needed to ever read them from disk
9. **Added 'menuTemplate' class for common menus in the game**
- This allows many menus like StoryMenu, Freeplay, Options and Controls to share the same underlying menu code
- Before: A lot of boilerplate was required to build each one of these menus
- This also allows modders to easily control the spacing/styling of all the menus at once
10. **Mild enhancements to some menus**
- Controls menu will no longer hover over blank space
- More transitions may be skipped

## Version 1.2.1 (Minor)

Minor update to address a few bugs and issues. The only major change is adding a brand new offset wizard to help with calibration.

1. **Mild refactoring**
- Renamed a few variables in PlayState to be a bit more intuitive
- Removed the 'storyMode' variable (as week -1 is considered FreePlay)
- Removed useless code in the death screen
- Prepare sections of code for web browser support
2. **Reduced note jittering**
- For the notes to scroll smoothly: The game drives a variable called 'songTime' every frame based on delta time, then gets re-synced every step
- To reduce jittering, the note gets 1/2 synced between the current 'songTime' and actual time from the song
3. **Added offset wizard**
- This can be entered by hitting the accept key over the audio offset option
- This helps in calibrating your offset, as you don't have to guess/brute force your offset
4. **Fixed story menu crashing after playing a week**
- The song list was stored in a static variable, which was then passed by reference to PlayState
- PlayState shifts (removes the first element) the list for story mode to keep track of the songs in the campaign. But these shifts cause the static variable to lose all of the values it holds
- The easier solution is to make the variable non-static, but the fix in this version was to create a temporary copy of the array to pass to PlayState

## Version 1.2.2 (Minor)

1. **Fixed input and framerate options for web build**
- Flixel normally ignores certain keys on the web build, however these blocked keys can be cleared so that they may be used again
- For web builds, the framerate has to be set to 60 (though it's actually based on refresh rate)
- The framerate option is now hidden on web builds
2. **Stage asset improvements**
- The sprites were correctly trimmed to remove transparent pixels
- The curtains were split into two separate sprites
- This had a giant performance increase (and reduces memory too!)
3. **Add 'StaticSprite' class**
- This special sprite class has it's updates turned off as most sprites don't need it
4. **Chart editor improvements**
- Added a highlight effect to the custom chart UI
- Added select all button
- Fixed section jumping getting stuck due to floating-point rounding error
5. **Allow pausing during countdown in PlayState**
6. **Corrected strum arrow positioning due to a mistake**

## Version 1.3.0 (Major) (Beta)

Assorion 1.3.0 was the next major version of the engine. With it came a turning point for the engine. The over-arching goal was supposed to be code simplicity, and ease of modding. However that initial idea started to fade with this version (and the ones that followed for a while).

A lot of the changes that were introduced in this version eventually got removed due to adding unnecessary complexity for virtually no result. Certain changes were made for the sake of "speed", when they really didn't do anything.

Regardless; For the CHANGELOG, they will be documented anyway.

1. **Tune-ups to the repository**
- Issue/Feature Request templates were moved from markdown to Yaml
- A setup guide for MinGW-w64 was added
- Most of the README was redone
- 32-bit builds were added to the workflows
- Experimental MacOS builds were also added to the workflows (though we had no way of testing them at the time)
- Removed some unnecessary assets
2. **Fixes to certain assets**
- Ensured correct line endings for custom TXT files
- Removed Fresh as a song, and rename Test to Demo
3. **Removed 'nobody character'**
- Initially this was here in case you wanted GF to be invisible
- However the character system was reworked in a way that would make this obsolete
4. **Added HistoryState.hx**
- This is a state which let you view the CHANGELOG file in game
- Unfortunately it got removed in a later version, especially since the CHANGELOG was neglected for a long while
5. **Code clean-up in a lot of places**
- Adjusted the way delayed events work. They now compare against system time, rather than counting in-game time
- Attempted to enforce slightly more consistent styling (I say attempted as I didn't catch everything)
- Moved music timing code out of conductor and merged it with Song.hx or MusicBeatState
- Forced static sprites to follow antialiasing setting by default (as the minimum Flixel version was under 5.0.0)
- Renamed NewControls to Binds
- Updated pause menu to follow MenuTemplate's spacing rules
6. **Fixed window icon on Linux**
- It's silly that Lime doesn't have an in-built way of doing this
- Massive thanks to Psych though, as I wouldn't have figured it out on my own
7. **Added NewTransition.hx**
- Now the transition can be fully custom!
- This also allowed practically every state to optionally skip the transitions between them, which greatly improved navigation and testing
8. **(Conditional) UNFIX camera lerp across framerates**
- Flixel's camera lerp used to be broken on variable framerates, the fix was to constantly update the camera lerp with the framerate to set it to the correct value (which was added in Assorion 1.2.0)
- Then Flixel 5.4.0 released, which fixed this issue, but made the internal fix in Assorion break the camera again
- Compiler conditionals were added to ensure correct behaviour an all Flixel versions
9. **Experimental in-game screenshot functionality**
- It was highly experimental as the resulting screenshot tended to be inaccurate
- Because screenshots wouldn't be affected by shaders, it could only be limited to PlayState
- Other menus would show up as the wrong colour (as Flixel's "color" value is technically a shader)
- Transparent sprites would be completely opaque in the screenshot
10. **Infamous -10 FPS issue finally resolved!!!!!!!!**
- Because it was possible to edit the game's settings in default settings file, you could force an unreasonably stupid default
- If you set the FPS to -10 the game would completely crash and wouldn't be able to get into settings to fix it
- A framerate clamp was added to ensure it could only go between a specific range
11. **Allowed controls state to skip the blank spaces**
- It was very stupid that it wasn't always like this
12. **Added optional loading state**
- Kade engine previously did something similar, except that it was forced (unless you modded it out)
- If the option for it was enabled, the game would attempt to cache every asset before starting, thus making load times almost instant
13. **Updated text sequence in TitleState.hx**
- It changes in pretty much every major release now
- The random text was changed from "RANDOM" to a '%'
14. **Lots of changes to the chart editor**
- Greatly improved UI visuals (looks 3D now!)
- Used event functions for mouse move/down/up (instead of shoving it in the update function)
- Added status pop-up text
- Added help tab to explain controls
15. **Other minor changes**
- The camera alpha was defaulted to 0 (despite the fact that it was already 0)
- More assets could be cached, such as XML files, text files, Json files, etc
- An option to skip every transition was added
- Minor improvements/considerations for web build were added

## Version 1.3.1 (Minor)

1. **Fix Windows workflow**
- The Windows workflow used MinGW-w64 for compilation on 1.3.0
- Annoyingly HXCPP broke with MinGW gcc >=14 because it forcefully undefined '\_\_STRICT_ANSI\_\_'
2. **Updated screenshots in repository**
3. **(FINALLY!) Moved character data out of crappy custom TXT file**
- In 1.3.0 and prior, character data (such as name, their animations, offsets, etc) was placed in a custom TXT file using an arbitrary format
- Character data was now finally loaded from a much more standard Json file
- This allows the data to be easily changed, extended, removed, and made parsing far more reliable (and easier too!)
4. **Fixed BotPlay toggle in pause menu**
- The health text was previously not updated when toggling bot play
5. **Reduced potential lag spike when receiving a different rating**
- Before the chart is loaded, the game will quickly load and cache every rating asset that may be used
- Now if you receive a rating that isn't "SICK", you won't get a massive lag spike
6. **Extremely minor code changes**
- Reorganized the logic of certain functions (e.g: making the input system get processed first on keyHit)
- Replacing certain splice functions with shift() or pop()
- Forcing a lower maximum framerate (as the game cannot reliably stick to 500 FPS)
- Small updates to the chart editor

## Version 1.4.0 (Major)

Assorion's 1.4.0 seemed rather exciting at the time. When released, I thought it was going to be the last version of Assorion as it functionally did everything I wanted.

This version had a few good ideas and made strides towards code simplicity/improvements again (with exceptions of course).

This was also the first version to be released on Codeberg instead of GitHub, a change that I wish I had handled better at the time.

1. **Repository changes**
- Updated screenshots
- Removed April Fools README
- Build using the latest dependencies on workflows
2. **Improved dialogue system**
- New dialogue box sprite
- Moved away from crappy TXT format to Json for dialogue
- Allow each slide to specify speed and portrait locations
- Also includes a rewrite of the dialogue state itself
3. **Asset improvements**
- Fixed typo in characterLoader.json
- Moved week-1 asset to week-demo to show that it can be set to anything
- New demo song and chart!
4. **New settings system**
- Originally the settings themselves were declared in a struct that was kept globally in the Settings class. This also required their default values to be stored in a separate Json file
- This new system stores the values directly in a class (simply called Settings), managed by the 'SettingsManager'
- This allows accessing values directly which is far more convenient (e.g: "Settings.downscroll" instead of "Settings.pr.downscroll")
- This also allowed setting the defaults directly in the class itself, without having them stored separately in a Json file
5. **Allow chart to specify character positions**
- Previously, it had to be hard-coded based on stage
- This is useful as adding a variable amount of characters no longer has to be hard-coded
6. **Code changes**
- Renamed the 'ui' folder to 'frontend'
- Renamed the 'misc' folder to 'backend'
- Renamed the UI binds to match their directions (instead of UI_L it was now UI_LEFT for example)
- Added FormattedText class for short-hand creation of text
- Bumped Flixel requirement up to 5.0.0 due to the 'defaultAntialiasing' variable getting used
- Moved the 'getKeyNameFromString' function into CoolUtil
- Changed playerStrums into a basic array instead of a group
7. **Music functionality changes**
- Normally beatHit and stepHit are part of the MusicBeatState, and only states that extended it could have access to those functions
- This was changed so that music was managed globally, and anything, anywhere could add hooks for beatHit or stepHit without interfacing through the state code
8. **New note system for PlayState**
- The notes for the song are now ordered backwards (first notes being last in the array) with the very first index being reserved for the current note
- The idea was that the array could get popped which is a relatively fast operation
- Though this greatly increased complexity and was reverted in 1.5.0

## Version 1.5.0 (Major)

At this point, 11 whole months went by between 1.4.0 and 1.5.0. This version sought to fix/reorganize everything I didn't like about 1.4.0! My passion for the project seriously dwindled by this point, but never archived the repository.

The changes for this version will be split into four different categories: Repository changes, Asset changes, Back-end code changes, and Front-end changes.

#### Repository changes:
1. **Removed resources related to MinGW**
- HXCPP broke on the recent versions of MinGW (as mentioned prior)
- In-order to properly distribute your builds, you HAD to use the "-Dno_shared_libs" option
- Realistically using MinGW was more trouble than it was worth
2. **Cleaned up the README once more**
- Removed the minimum requirements due to not being too necessary
- Reworded aspects relating to the engine's purpose
- Gave more verbose reasons for why Assorion may be preferable
3. **Organized repository assets**
- Instead of dumping random files into the art directory, there would be three folders:
- "assorion" for Assorion repository related assets
- "bin" for assets that would get copied into the release builds of the game
- "ui" for the source project files of UI assets

#### Asset changes:
1. **Enforced consistent naming across assets**
- Initially it was essentially random
- Many assets were forced into camel case to be consistent with code (e.g: NOTE_assets -> noteAssets)
2. **More comprehensive asset sorting**
- Images now contains different folders for different states, and uses the "ui" folder for shared UI assets
- "images/gameplay" is now what contains stages, characters, notes, dialogue assets, etc
- The songs-data folder was split once again.
- Data now contains all the game's Json data (including charts)
- Music now contains all the different music in the game, which includes the songs heard in PlayState
- Sounds is unchanged however
- Before 1.5.0, the location of certain assets was very arbitrary and often categorized
3. **Main Menu items are now split into individual sprites**
- Prior to 1.5.0, they were all stuffed into a single sprite and an XML file would declare the animations for each
4. **Fixed menu colouring**
- Have you ever noticed that prior to 1.5.0, the main menu looked a bit dim and washed out?
- Colouring was always done by taking one sprite and tinting it (to save on duplicate assets)
- However it used to be done using the de-saturated background, which always looked off
- This new menu sprite is more vibrant and accurate to the original main menu sprite
5. **Converted all uses of crappy custom TXT files into Json**
- This includes the freeplay song list and intro text list
- The stage list got dissolved
- This allows for easy modification of data, and encourages extending said data in anyway the modder pleases
6. **Split characterLoader.Json into separate Json files**
- characterLoader contained every character, their animations, offsets, etc
- Having a lot of characters using just one file became cumbersome
- Splitting characters into their own files had a few unexpected difficulties, such as detecting which characters were present and could be used
7. **Removed/trimmed unused assets**
- The game had an unused Restart button that was only used for the Gitteroo easter egg (but wasn't even present in Assorion anyway)
8. **Provided MP3 versions of every audio asset**
- When the game is compiled for desktops, it uses OGG files which offer a great quality to compression ratio
- Web browsers do not support OGG and thus must use MP3 files instead
- Browser support was initially an afterthought, and I didn't guarantee that every OGG asset had an MP3 equivalent
9. **Removed unnecessary history state icon**
- HistoryState was removed in it's entirety (but that counts as more of a Front-end change)
10. **New Codeberg button in-place of older GitHub button**
- Credit's to my friend Brazil for helping out with it!

#### Back-end code changes:
1. **Removed overridden file for Flixel**
- Generally it is an awful idea to override a dependency file in your own local source code
- Although it was kept in it's own class path so that it wouldn't conflict with the main source code, it still isn't a great way of handling something like this
2. **Renamed MusicBeatState to EventState**
- It was only called MusicBeatState because the state was designed to handle music timings and provide functions for it
- Though that wasn't true ever since it was moved into Song.hx (1.4.0)
- The rename reflects this change
- This also applies to MusicBeatSubstate -> EventSubstate
3. **Resorted folders in code**
- The new set of folders were called "backend", "ui", "gameplay", and "states"
- I didn't really like the idea of adding another folder to the source code but it was certainly worth it
- UI was a better name than just "frontend" especially since that could create ambiguity of where certain files belonged
- Gameplay was strictly for gameplay only objects (such as notes, stage logic, etc) and states was there to sort every state in the game
- This also involved moving certain files (like NewTransition or FormattedText) to where they should be
4. **Enforced SCREAMING_SNAKE_CASE for constants**
- This is more of a tradition in C (GOATed language of course), but I believe it should be clear when a value is suppose to be constant
- Especially true considering Array's can't really be constant in Haxe
- Other styling guidelines similar to C were also enforces (like the way switch statements look)
5. **Added 'bindFunctions' to controls
- Using an array of binds and the deepCheck() function with a switch statement looked extremely clunky
- bindFunctions allows a way of directly specifying what-binds should map to what-functions
6. **Moved the difficulty array into Song.hx**
- It really should've been this way from the start
7. **Reduced the complexity (sometimes in sacrifice of speed)**
- Paths had a lot of weird function madness to handle caching and non-caching functions
- PlayState had a weird backward note system (introduced in 1.4.0)
- PauseSubstate basically took a screenshot of playstate and displayed it in the background (so it wouldn't have to be rendered ontop)
- ChartingState relied on a custom UI layer instead of using Flixel UI
- There was a custom HealthBar class that was only there to ensure reflection wouldn't get used every single frame
- All of the above often lead to lots of complexity (and thus issues) which was not really warranted. These changes got reverted which may have a performance impact but greatly simplified the code
8. **Added StageLogic.hx to handle... stage logic**
- Stage specific functions would've had to be hard-coded directly into PlayState
- Take the spooky mansion from week two, the lightning effect would've had to been integrated directly into playstate
- StageLogic helps to separate the potential special logic into it's own class. Using beat/step hooks to add timing functionality
9. **Separated the rating display into ComboDisplay.hx**
- This doesn't really matter all that much, but it included enough of it's own code that I think it warrants going into it's own file instead
10. **Many functions and variables renamed for clarity**
- For example: every Note had a variable called 'noteData' which was the column that the note belonged to (ranging from 0 to 3). It was renamed to column in order to reflect that
- That's just one example however, as there would be far too many to list LOL
11. **Removed unnecessary inlines**
- Inlining a function basically causes it's functionally to get copied in place of it's call (so that the complexity to setup a function call isn't required)
- However it's best to leave things like that up to the compiler, and not spam random inline tags everywhere
12. **import.hx no longer imports literally everything**
- Before it would just import all of the backend, even though most states don't use them all
- Unfortunately the import for FlxSound had to be placed here due to Flixel changing it's directory ever since 5.3.0
13. **Sort between imports**
- The imports for every file used to just be stuffed where ever
- Now it's structured so that it goes in this order: dependencies (e.g: OpenFL -> Flixel -> etc) -> backend -> ui -> gameplay -> states
14. **Chart format was changed slightly**
- A note's strumTime (the value which dictates it's time in relation to a song) was based on a global position. So a value of 154 would be the 154th step in a song
- This was changed to be relative: It may only range from 0 to 15, with it's position being determined by the time of the section itself
- The idea was to prevent floating-point values breaking down when they get too large (but this didn't really help anyway)

#### Front-end changes:
1. **Reduced caching options**
- There were a lot of problems caused by the distinction of "default persist" and "launch sprites"
- They were merged into one: Where the game will enable all caching options as well as loading every asset on launch
2. **Chart editor switched over to Flixel UI**
- This was done to avoid having an integrated UI layer (which wasn't very good)
- And since Flixel UI was already marked as a dependency, it might-as-well get used
3. **Fixed freeplay score display going off screen**
- Surprisingly this was an issue I didn't catch up until 1.5.0
4. **Fixed story menu image fading**
5. **Removed HistoryState from settings**
- The MD parser was very basic and didn't work all too well
- The major issue was that the CHANGELOG was kept up-to-date
- The information in CHANGELOG wasn't very detailed either
6. **Chart editor now has an autosave feature!**
- It's a minor quality of life change, but with a big impact
- Though there is no auto restore, that has to be done manually
7. **Chart editor may now save in web builds**

## Version 1.5.1 (Minor) + (Hotfix)

1. **Fixed controls state crashing**
- Caused by an attempt to index into an array inside another array but with an item that didn't exist yet
2. **Corrected typo in OptionsState**
- "to enter hte offset wizard" -> "to enter the offset wizard"
3. **Fix pause state not showing up**
- Triggered when tabbing out as PlayState loads (due to the auto pause)
- Caused by Flixel weirdness (no other way to phrase it)
4. **Fix non-bolded Alphabet (Hotfix)**
- It was only broken because it had never been tested LOL
- But needed to be fixed for a project I was working on
5. **Properly fixed controls state (Hotfix)**
- The last fix was not very elegant
6. **Remove HTML5 summary from workflow**
- The summary was there because HTML5 builds weren't tested at the time. But that's no longer true

## Version 1.5.2 (Minor-ish)

This is Assorion's latest release as of the time writing this.

Originally there was only supposed to be a few minor UI changes, but the scope grew quite quickly. Once again, this will be split into two separate categories: Back-end changes, and front-end changes

#### Back-end Changes:

1. **(The biggest change) Remove Flixel UI (again)**
- The chart editor now uses a custom UI layer (again)
- This was done to further drop the dependency count
- SAIL (the custom UI layer) is far thinner than Flixel UI
- Hopefully this allows writing custom interfaces easier
- Check the bottom of this version's log for more info
2. **Rename "Path" functions**
- Before they were all prefixed with 'l' (hence "lImage()" for example)
- This was unnecessary and looked quite silly
- Though these functions weren't changed for a long time because too many states relied on them
3. **Rename CoolUtil to Utility**
4. **Rename MenuTemplate to ListMenu**
5. **Move functions out of Song.hx into Chart.hx**
- Song.hx originally had three separate goals: Music timing functionality, loading charts, and loading high-scores
- The latter two got moved into a separate file as these functions are distinct from each other
- This also dissolved HighScore.hx
6. **Set camera directly for HUD elements**
- For most sprites that needed to be placed on a different camera, the code would be something like: ".cameras = [camHUD]"
- Though no sprite ever needed to be rendered on two separate cameras, thus ".camera = camHUD" would've been perfectly fine
7. **Use in game counter for delayed events**
- Delayed events had relied on using system time-stamps ever since 1.3.0, but this caused a lot of issues. Especially with tabbing out, or with pausing
- Now they count down using the in-game elapsed time. It's less accurate, but is far easier to work with, and events are now more reliable
8. **Reduce functionality of ListMenu and columns**
- The ListMenu (formerly MenuTemplate) was initially built to handle multiple columns of text scrolling with each other, but this added a lot of complexity despite the fact that most states wouldn't ever need to use it
- Now, ListMenu only tracks one column, and the state itself can handle the other columns
9. **Drop dependency count to three**
- Flixel Addons was never used and Flixel UI was only needed for the chart editor
- The Project.xml lists only Flixel, but Flixel itself relies on Lime and OpenFL
- Not counting HXCPP as that is an optional dependency and not required for building (on certain targets)
10. **Lower minimum Flixel required**
- The minimum Flixel required was 5.0.0 due to the reliance on 'defaultAntialiasing'
- The entire rest of the game worked on 4.9.0 though, so the requirement of 'defaultAntialiasing' was lifted so the minimum version could be lowered
- The game could easily be ported to work on even older Flixel versions but would require compiler conditionals to do so (which I'd rather avoid)
11. **Lower minimum Haxe required to 4.0.0**
- The README did claim that this was already supported, but it wasn't actually tested at the time
- Null coalescing wasn't a thing yet (but the ternary operator was good enough). Thankfully it hardly ever used throughout the code base
- Arrays didn't have the 'contains' function. So "indexOf(element) >= 0" had to be used in place
- The idea of Haxe 3.4.7 was also tried, but it disallows setting enum defaults in function arguments. SAIL uses that constantly so it's far more trouble than it's worth
- Assorion was also tested with Haxe 5.0.0-Preview and can confirm that (at least of this version) builds fine with Haxe 5
12. **Minor code updates for consistency**
- In 'generateChart', the notes for PlayState get sorted, but this sorting function was the only time where the lamba function syntax got used, and was changed to look more like a traditional function
- Uses of bitwise AND in place of modulo is faster, but I figured it could cause a bit of confusion. Certain bitwise operations remain, but the ones used for even number checks are now modulo operations (x % 2)
- Updated Alphabet.hx to not use a setter for text. This was the only time a setter was used in the code base, so it had to go. The "setText" function can be called to update the text instead

#### Front-end changes:

1. **Changed the default transition from white to black**
- This was changed to feel a little closer to the original game's transition
2. **Menu spacings adjusted to match the original game**
- The menu spacings (for freeplay, or options, etc) used to be a lot closer to each other. For similar reasons to above, this was adjusted to match the default game's spacings
3. **Options state improvements**
- Toggleable options now no longer cause the entire list to be recreated
- This also makes it consistent with integer options
- Toggleable options also now say "off/on" instead of "no/yes" respectively
4. **Freeplay state now offers descriptions for each song**
- A bit of a fun change; Not really necessary though
5. **Health bar colours!**
- Yes. It took this long to get health bar colours
- It was only neglected for so long as it was already extremely easy to implement them
6. **New chart editor UI**
- All the functionality of the original one is still here, it'll just look different
- A new High-Contrast version of the UI is also included (and can be enabled in options)
- In the section tab, a checkbox was added to preview the notes before copying
- The camera stepper will also tell you which character it's facing 