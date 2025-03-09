# Updates.


## V - 1.0.0

Making the MKG (MakeMeGenius) engine a reality.
Btw it used to be called MKG, it's Assorion now.

## V - 1.1.0

1. Asset improvements.
2. Fixed input bugs.
3. **Hopefully** Made code simpler.
4. Labeled chart editor buttons and drop downs.
5. Added "About" section in the chart editor.
6. Added options for caching to make the game really fast.
7. Added embedded assets and settings icons.
8. Made sure and improved all settings and works.
9. Set up a test song and week to demo the engine.
10. Added dialogue code.
11. Fixed a lot of tiny bugs (post events timer being corrected, 
        freeplay song not unpausing on vocals, highscore problems, etc).
12. Donate button replaced with Github button.
13. Made note types easier to implement!

## V - 1.1.1

Minor update with a few fixes.

1. **Actually** Fixed the README fully this time (I promise) (Thx to Byzol).
2. Fixed NOTE_assets again.
3. Fixed bug with the chart editor that locked your input forever
        (Thus losing your work).
4. Exclude Firealpaca's art files (.mdp) in the build folder.

## V - 1.1.2

Chart editor fix (again).

1. Actually **Actually** fixed the chart editor this time (hopefully).
2. Fixed bug where you can't delete notes in 1/3 zoom level.
3. Added navigation stuff.

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
