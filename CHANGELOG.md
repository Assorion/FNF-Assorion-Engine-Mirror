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