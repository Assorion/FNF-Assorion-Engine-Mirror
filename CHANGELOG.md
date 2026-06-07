## Version 1.0.0 (Beta)

Established the first release of this engine.

Initially it was called "MKG" (a meaningless acronym), which was quickly re-branded to Assorion in the next release.

## Version 1.1.0 (Main)

This was Assorion's first real release. It has a lot of major changes/improvements over it's first version so there's a lot to document here.

1. Tuned up repository (credits to Barzil)
- Improved the README.md
- Added GitHub issue template for bug reports
2. Enabled stack tracing on debug builds
- This greatly helps in finding the cause of crashes
- Not enabled in release builds however, due to performance concerns
3. Added 'embedded' assets folder
- Before, only the fonts folder was embedded
- You may optionally add anything you want to the embedded folder
4. Trimmed the whitespace of many assets
- Many animated assets have tons of transparent pixels that are never visible
- Trimming this greatly helps in reducing memory footprint + improving performance
5. Replaced Donate button with GitHub button
- If you feel like supporting the original Funkin' team, you're still encouraged to donate
6. Renamed the 'songs&data' folder to just 'songs-data'
- It was originally merged since I had believed that song assets should live next to their charts
- It was renamed because the '&' could potentially be problematic
7. Added caching options
- Default Persist allows sprites that were loaded off disk to permanently stay in memory, thus never having to be loaded again
- Launch Sprites not only enables Default Persist, but will load all sprites in the assets folder on launch, leading to seamless game-play
8. Added dialogue and preset dialogue text files
- Dialogue is very common in most mods, and was added to Assorion for the sake of ease
- The preset files are used to help demonstrate how to optionally write your own dialogue
9. Added default icons, as well as settings icons
10. Added delayed event system to MusicBeatState
- These events allow you to postpone a function call by a set amount of seconds
- Turns out Flixel has this functionality built in, but isn't used by the engine
11. Refactored/Revised lots of base code
- This includes re-writing large sections of code (a common thing for Assorion)
- This helps fix lots of bugs
- And helps make the code simpler and easier to read
- Filtered out a lot of the immature cursing of the original code
- Fixed up the GameOverSubstate
12. Better support for different note types
- Adding mine notes is simply a property (instead of having to be implemented by the modder)
- This also allows assigning callbacks to missing or hitting notes
13. Improvements to Freeplay
- Now each song has an icon preview as specified in a custom text file
- Allow previewing each song by pressing the space bar, and listening to the instrumental by backing out (yes that was never a bug)
14. Improvements to OptionsState
- Each option is now given a description
- There are now icons for the different categories
15. Other minor enhancements
- This list does not detail everything, but only the things that are worth listing

## V - 1.1.1

This is a minor update that fixes a handful of problems

1. Exclude FireAlpaca's project files from the compiled build
- Most art assets were made/edited with FireAlpaca, and the project files were put in the assets folder in source
- Now these assets are no longer copied into the assets of the release build
2. Minor fix-ups to the README
3. Trimmed note assets so that black lines no longer show up on the strums
- This was caused by Adobe animate being a very cool and awesome and great program (**/s**) and packing the assets too close
4. Updated repository link in the Main Menu
5. Fixed Chart Editor permanently ignoring any inputs
- This happened if the section UI was recreated while interacting with a type-in box

## V - 1.1.2

Even more minor bug fixing update

1. Fixed being unable to delete notes in 1/3 snap level
- This was caused because the Y level of the cursor wouldn't match the Y level of the note due to floating point weirdness
- The fix was to simply round the Y coordinate
2. Added Assorion.txt 
- This takes the place of the 'do NOT readme.txt' file
3. Improved navigation
- Some transitions may now be skipped
- Unfortunately not all transitions may be skipped in this version

## V - 1.2.0

1. **Hopefully** Once and for all, fixed input problems.
2. Added input offset option.
3. All menus are standardized under MenuTemplate.hx.
4. Bug fixes (obv).
5. More navigation improvements.
6. Added text file / chart caching.
7. Added pause menu info.
8. All menu current selection variables no longer static.
9. Rebinding controls menu improvements (colour and skip over blank space).
10. Background menu scrolling effect.
11. Pausemenu lag hopefully gone.
12. Gameplay icons properly centered.
13. Chart editor fixes.
14. You can take screenshots during gameplay.
15. Code clean-up in many places.

## V - 1.2.1

1. Rounded syncing time, rather than setting.
2. Fixed save data. Now not stored in local file.
3. Fixed StoryMenu bug.
4. Little refactoring.
5. Removed usless code in GameOverState.
6. Added offset wizard.

## V - 1.2.2

1. Added StaticSprite, a sprite with no update. Mild performance increase I guess.
2. Fixed chart editor bug where the section would get stuck at the end.
3. Split stage curtains into 2 sprites, 
        and lowered the res on the back sprite, big peformance increase.
4. ChartingState UI highlighting effect.
5. Input and framerate fixes for web build.
6. Windows and Linux release now compiled with GCC, 
        and compiler optimizations. (Read Release please!)
7. Allow pausing on countdown without breaking.
8. Fixed arrow fade in (whoopsie it's been wrong all this time).

## V - 1.3.0

1. Defaulted camera BG alpha to 0. Might be faster.
2. Overhauled cachingstate. Added a progress bar for it
3. Changed a bit of web build stuff.
4. Allow for XML caching. Super cool!
5. Added CHANGELOG.md parser (HistoryState.hx). Now you can view history in game.
6. (Not very important) slightly un-hardcoded settings icons. Whoopsie!
7. Fixed minor bugs (pause during dialogue, framerate issue on cachingstate)
8. Overhauled chartingstate. New 3D ui!
9. Now can skip all transitions!
10. Fixed older crashing issue with cache_misc (option dissolved)
11. Added Flixel camera optimizations (not too much faster lol)
12. New transitions
13. Legacy Windows XP compatibility branch (W.I.P)
14. Fixed "Line-Feed" problem in txt files, should fix Freeplay icons bug.
15. Refactored the README.md file. Fixed typos, and minor grammatical errors.
16. Fixed typo where I said "types" instead of "typos" in changelog.
17. Added code consistency principles.
18. Fixed -10 FPS issue.
19. Added option to disable transitions all-together.
20. Removed Conductor.hx, now merged into MusicBeatState. 

Outdated dont read this
