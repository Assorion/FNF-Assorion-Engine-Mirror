package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.ui.FlxBar;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.input.keyboard.FlxKey;
import openfl.utils.Assets;

import backend.Song;
import backend.HighScore;
import ui.CharacterIcon;
import gameplay.*;

using StringTools;

typedef RatingData = {
	var score:Int;
	var threshold:Float;
	var asset:String;
}

#if !debug @:noDebug #end
class PlayState extends EventState {
	public static inline final KEY_COUNT:Int = 4;
	public static inline final INPUT_RANGE:Float = 1.25; // Input range is measured in steps (16th notes)
	public final  SING_DIRECTIONS:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	public final BIND_ARRAY:Array<Array<Int>> = [Binds.note_left, Binds.note_down, Binds.note_up, Binds.note_right];
	public final POSSIBLE_SCORES:Array<RatingData> = [
		{
			score: 350,  
			threshold: 0,
			asset: 'sick'
		},
		{
			score: 200,
			threshold: 0.43,
			asset: 'good'
		},
		{
			score: 100,
			threshold: 0.65,
			asset: 'bad'
		},
		{
			score: 25,
			threshold: 0.9,
			asset: 'superbad'
		}
	];

	public static var songData:SongData;
	public static var storyWeek:Int = -1; // If story week is less than 0, we're in free play.
	public static var storyPlaylist:Array<String> = [];
	public static var curDifficulty:Int = 1;
	public static var totalScore:Int = 0;
	public static var lastSeenCutscene:Int;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var playerStrums:Array<StrumNote> = [];
	public var chartNotes:Array<Note> = [];
	public var currentNotes:FlxTypedGroup<Note>;

	public var health:Int    = 50; // Ranges from 0 to 100.
	public var combo:Int     = 0;
	public var hitCount:Int  = 0;
	public var missCount:Int = 0;
	public var fcValue:Int   = 0;
	public var songScore:Int = 0;

	public var healthBarBG:StaticSprite;
	public var healthBar:FlxBar;
	public var scoreTxt:FormattedText;
	public var iconP1:CharacterIcon;
	public var iconP2:CharacterIcon;
	public var comboDisplay:ComboDisplay;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;

	public var vocals:FlxSound;
	public var playerIndex:Int = 1;
	public var allCharacters:Array<Character> = [];
	public var stage:StageLogic;

	private var followPos:FlxObject;
	private var stepTime:Float = 0;

	override public function create() {
		// Song setup
		songData.name = songData.name.toLowerCase();
		Song.musicSet(songData.bpm);

		vocals = new FlxSound();
		if (songData.needsVoices)
			vocals.loadEmbedded(Paths.playableSong(songData.name, true));

		FlxG.sound.list.add(vocals);
		FlxG.sound.playMusic(Paths.playableSong(songData.name), 1, false);
		FlxG.sound.music.onComplete = endSong;
		FlxG.sound.music.stop();

		// Cameras and background
		camGame = new FlxCamera();
		camHUD	= new FlxCamera();
		camHUD.bgColor.alpha = 0;

		followPos = new FlxObject(0, 0, 1, 1);
		followPos.setPosition(FlxG.width / 2, FlxG.height / 2);

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.camera.follow(followPos, LOCKON, 0.067);

		super.create();
		
		playerIndex = songData.activePlayer;
		stage = new StageLogic(songData.stage, this);

		// Strumline and note generation
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		currentNotes = new FlxTypedGroup<Note>();
		add(strumLineNotes);
		add(currentNotes);

		generateChart();
		for(i in 0...songData.playLength)
			generateStrumArrows(i);

		// UI setup
		var baseY:Int = Settings.downscroll ? 80 : 650;

		healthBarBG = new StaticSprite(0, baseY).loadGraphic(Paths.lImage('gameplay/healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();

		var healthColours:Array<Int> = [0xFFFF0000, 0xFF66FF33];
		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), null);
		healthBar.active = false;
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(healthColours[0], healthColours[1]);

		scoreTxt = new FormattedText(0, baseY + 40, 0, '', null, 16, 0xFFFFFFFF, CENTER, OUTLINE);
		scoreTxt.scrollFactor.set();
		scoreTxt.screenCenter(X);

		iconP1 = new CharacterIcon(songData.characters[1].name, true, true);
		iconP2 = new CharacterIcon(songData.characters[0].name, false, true);
		iconP1.y = baseY - (iconP1.height / 2);
		iconP2.y = baseY - (iconP2.height / 2);

		comboDisplay = new ComboDisplay(POSSIBLE_SCORES, 0, 100);
		add(comboDisplay);

		// Add to cameras
		strumLineNotes.cameras = [camHUD];
		currentNotes.cameras   = [camHUD];
		if (Settings.show_hud){
			add(healthBarBG);
			add(healthBar);
			add(scoreTxt);
			add(iconP1);
			add(iconP2);

			healthBar.cameras =
			healthBarBG.cameras =
			iconP1.cameras =
			iconP2.cameras = 
			scoreTxt.cameras = [camHUD];
		}

		stepTime = -22 - (((songData.startDelay * 1000) - Settings.audio_offset) * Song.division);
		updateHealth(0);

		Song.beatHooks.push(beatHit);
		Song.stepHooks.push(stepHit);

		if (storyWeek >= 0 && lastSeenCutscene != storyPlaylist.length){	
			var dialoguePath:String = 'assets/data/songs/${songData.name}/dialogue.json';			
			lastSeenCutscene = storyPlaylist.length;

			if (Assets.exists(dialoguePath)) {
				persistentUpdate = false;
				postEvent(0.1, function(){ pauseAndOpenState(new DialogueSubstate(this, camHUD, Assets.getText(dialoguePath))); });
				return;
			}
		}

		postEvent(songData.startDelay + 0.1, startCountdown);
	}

	private function generateChart() {
		for(chartSection in songData.notes)
			for(chartNote in section.sectionNotes){
				var time:Float = chartNote.strumTime + (chartNote.section * 16);

				var newNote = new Note(time, chartNote.column, chartNote.type, false, false);
				newNote.scrollFactor.set();
				newNote.player = player;
				chartNotes.push(newNote);

				if (chartNote.length > 1)
					for(i in 0...susLength+1){
						var susNote = new Note(time + i + 0.5, chartNote.column, chartNote.type, true, i == chartNote.length);
						susNote.scrollFactor.set();
						susNote.player = player;
						chartNotes.push(susNote);
					}
			}

		chartNotes.sort((A,B) -> Std.int(A.strumTime - B.strumTime));
	}

	private function generateStrumArrows(player:Int)
		for(i in 0...KEY_COUNT) {
			var babyArrow:StrumNote = new StrumNote(0, Settings.downscroll ? 560 : 40, SING_DIRECTIONS, i, player, songData.activePlayer == player);

			strumLineNotes.add(babyArrow);
			if (babyArrow.isPlayer) 
				playerStrums[i] = babyArrow;
		}
	
	public function startCountdown() { 
		for(i in 0...strumLineNotes.length)
			FlxTween.tween(strumLineNotes.members[i], {alpha: 1, y: strumLineNotes.members[i].y + 10}, 0.5, {startDelay: ((i % KEY_COUNT) + 1) * 0.2});

		var introSprites:Array<StaticSprite> = [];
		var introSounds:Array<FlxSound> = [];
		var introAssets :Array<Array<String>> = [
			['', 'ready', 'set', 'go'],
			['intro3', 'intro2', 'intro1', 'introGo']
		];
 
		for(i in 0...4){
			var snd:FlxSound = new FlxSound().loadEmbedded(Paths.lSound('gameplay/' + introAssets[1][i]));
			snd.volume = 0.6;
			introSounds[i] = snd;

			var spr:StaticSprite = new StaticSprite().loadGraphic(Paths.lImage('gameplay/${introAssets[0][i]}'));
			if (introAssets[0][i] == '')
				spr.alpha = 0;

			introSprites[i] = spr;
			spr.cameras = [camHUD];
			spr.screenCenter();
		}

		var introBeatCounter:Int = 0;
		for(i in 0...5)
			postEvent(((Song.crochet * (i + 1)) + Settings.audio_offset) * 0.001, function(){
				if (introBeatCounter >= 4){
					FlxG.sound.music.play();
					FlxG.sound.music.volume = 1;
					Song.millisecond = -Settings.audio_offset;
	
					vocals.play();
					vocals.time = FlxG.sound.music.time = 0;
					return;
				}

				Song.currentBeat = introBeatCounter - 4;
				stepTime = Song.currentBeat * 4;
				stepTime -= Settings.audio_offset * Song.division;

				for(char in allCharacters)
					char.dance();
	
				var spr = introSprites[introBeatCounter];
				add(spr);
				FlxTween.tween(spr, {y: spr.y + 10, alpha: 0}, Song.stepCrochet * 0.003, {
					ease: FlxEase.cubeInOut, 
					startDelay: Song.stepCrochet * 0.001,
					onComplete: function(t:FlxTween){
						remove(spr);
					}
				});

				introSounds[introBeatCounter].play();
				++introBeatCounter;
			});
	}

	public function beatHit() {
		#if (flixel < "5.4.0")
		FlxG.camera.followLerp = (1 - Math.pow(0.5, FlxG.elapsed * 6)) * (60 / Settings.framerate);
		#end

		var sec:SectionData = songData.notes[Song.currentBeat >> 2]; // Same result as 'Math.floor(Song.currentBeat / 4)'
		if (Song.currentBeat & 3 == 0 && FlxG.sound.music.playing){   // Same result as 'Song.currentBeat % 4 == 0'
			var currentlyFacing:Int = (sec != null ? cast(sec.cameraFacing, Int) : 0);
			var char = allCharacters[CoolUtil.intBoundTo(currentlyFacing, 0, songData.playLength - 1)];

			followPos.x = char.getMidpoint().x + char.camOffset[0];
			followPos.y = char.getMidpoint().y + char.camOffset[1];
		}
	}

	public function stepHit() 
	if (Song.currentStep & 1 == 0 && FlxG.sound.music.playing)
		stepTime = (Song.millisecond * Song.division * 0.25) + (stepTime * 0.75);


	override public function update(elapsed:Float) {
		Song.update(FlxG.sound.music.time);
		stepTime += elapsed * 1000 * Song.division;

		while(chartNotes[0] != null && chartNotes[0].strumTime - stepTime < 24)
			currentNotes.add(chartNotes.shift());	

		currentNotes.forEachAlive(scrollNotes);

		super.update(elapsed);
	}

	private function scrollNotes(daNote:Note) {
		var strumRef = strumLineNotes.members[daNote.column + (KEY_COUNT * daNote.player)];
		var nDiff:Float = stepTime - daNote.strumTime;
		daNote.y = (Settings.downscroll ? 45 : -45) * nDiff * songData.speed;
		daNote.y += strumRef.y  + daNote.offsetY;
		daNote.visible = daNote.y >= -daNote.height && daNote.y <= FlxG.height;

		if (!daNote.visible) 
			return;

		daNote.x = strumRef.x + daNote.offsetX;
		daNote.angle = strumRef.angle;
		
		// NPC Note Logic
		if (daNote.player != playerIndex || Settings.botplay){
			if (stepTime < daNote.strumTime || !daNote.curType.mustHit)
				return;

			allCharacters[daNote.player].playAnim('sing' + SING_DIRECTIONS[daNote.column]);
			strumRef.playAnim('glow');
			strumRef.pressTime = 1.05;
			vocals.volume = 1;

			currentNotes.remove(daNote, true);
			daNote.destroy();
			return;
		}

		// Player Note Logic
		if (nDiff > INPUT_RANGE){
			if (daNote.curType.mustHit)
				missNote(daNote.column);

			destroyNote(daNote, 1);
			return;
		}

		// Input range checks
		if (daNote.isSustainNote && Math.abs(nDiff) < 0.8 && keysPressed[daNote.column])
			hitNote(daNote);
		else if (hittableNotes[daNote.column] == null && Math.abs(nDiff) <= INPUT_RANGE)
			hittableNotes[daNote.column] = daNote;
	}

	public var hittableNotes:Array<Note> = [null, null, null, null];
	public var keysPressed:Array<Bool>   = [false, false, false, false];
	override function keyHit(ev:KeyboardEvent) 
	if (persistentUpdate) {
		// Assorions input system
		var strumIndex = ev.keyCode.deepCheck(BIND_ARRAY);
		if (strumIndex != -1 && !keysPressed[strumIndex] && !Settings.botplay){
			keysPressed[strumIndex] = true;
			
			if (hittableNotes[strumIndex] != null) {
				hitNote(hittableNotes[strumIndex]);
			} else if (playerStrums[strumIndex].pressTime <= 0) {
				if (!Settings.ghost_tapping)
					missNote(strumIndex);

				playerStrums[strumIndex].playAnim('press');
			} 

			return;
		}

		ev.keyCode.bindFunctions([
			[Binds.ui_accept, function(){ pauseAndOpenState(new PauseSubstate(camHUD, this)); }],
			[Binds.ui_back,   function(){ pauseAndOpenState(new PauseSubstate(camHUD, this)); }],
			[[FlxKey.SEVEN],  function(){ EventState.changeState(new ChartingState()); }]
		]);
	}

	override public function keyRel(ev:KeyboardEvent) {
		var strumIndex = ev.keyCode.deepCheck(BIND_ARRAY);

		if (strumIndex != -1){
			keysPressed[strumIndex] = false;
			playerStrums[strumIndex].playAnim('static');
		}
	}

	private var iconSpacing:Int = 52;
	public function updateHealth(change:Int) {
		var fcText:String = ['?', 'SFC', 'GFC', 'FC', '(Bad) FC', 'SDCB', 'Clear'][fcValue];
		var accuracy:Float = CoolUtil.boundTo(Math.floor((songScore * 100) / ((hitCount + missCount) * 3.5)) * 0.01, 0, 100);
		scoreTxt.text = !Settings.botplay ? 'Notes Hit: $hitCount | Notes Missed: $missCount | Accuracy: $accuracy% - $fcText | Score: $songScore' : 'BOTPLAY';
		scoreTxt.screenCenter(X);
		
		health = CoolUtil.intBoundTo(health + change, 0, 100);
		healthBar.percent = health;
		
		var iconsMiddle = ((0 - ((health - 50) * 0.01)) * healthBar.width) + 565;
		iconP1.x = iconsMiddle + iconSpacing; 
		iconP2.x = iconsMiddle - iconSpacing;
		iconP1.animation.play(health < 20 ? 'losing' : 'neutral');
		iconP2.animation.play(health > 80 ? 'losing' : 'neutral');

		if (health <= 0)
			pauseAndOpenState(new GameOverSubstate(allCharacters[playerIndex], camHUD, this));
	}

	public function hitNote(note:Note) {
		destroyNote(note, 0);

		if (!note.curType.mustHit) {
			missNote(note.column);
			return;
		}

		playerStrums[note.column].playAnim('glow');
		playerStrums[note.column].pressTime = 0.66;
		allCharacters[playerIndex].playAnim('sing' + SING_DIRECTIONS[note.column]);
		vocals.volume = 1;

		if (note.isSustainNote){
			updateHealth(2);
			return;
		}

		var curScore:RatingData = POSSIBLE_SCORES[0];
		var curValue:Int = 1;

		for(i in 1...POSSIBLE_SCORES.length)
			if (Math.abs(note.strumTime - stepTime) >= POSSIBLE_SCORES[i].threshold){
				curValue = i + 1;
				curScore = POSSIBLE_SCORES[i];
			} else {
				break;
			}

		++hitCount;
		songScore += curScore.score;
		combo	   = curScore.score > 50 && combo < 1000 ? combo + 1 : 0;
		fcValue    = curValue > fcValue ? curValue : fcValue;

		comboDisplay.displayScore(curScore, combo);
		updateHealth(5);
	}

	public function missNote(direction:Int = 1) {
		vocals.volume = 0.5;
		combo = 0;
		songScore -= 50;
		missCount++;
		fcValue = missCount >= 10 ? 6 : 5;

		FlxG.sound.play(Paths.lSound('gameplay/missNote' + CoolUtil.randomRange(1, 3)), 0.2);
		allCharacters[playerIndex].playAnim('sing' + SING_DIRECTIONS[direction] + 'miss');

		updateHealth(-10);
	}

	private function destroyNote(note:Note, act:Int) {
		note.typeAction(act);
		currentNotes.remove(note, true);
		note.destroy();

		if (hittableNotes[note.column] == note)
			hittableNotes[note.column] = null;
	}

	public function endSong():Void {
		FlxG.sound.music.stop();
		vocals.stop();

		HighScore.saveScore(songData.name, songScore, curDifficulty);

		if (storyWeek == -1){ 
			exitPlayState();
			return;
		}
		
		totalScore += songScore;
		storyPlaylist.shift();

		if (storyPlaylist.length <= 0){ // If the story week is out of songs
			HighScore.saveScore('week-$storyWeek', totalScore, curDifficulty);
			exitPlayState();
			return;
		}

		songData = Song.loadFromJson(storyPlaylist[0], curDifficulty);
		EventState.changeState(new PlayState());
	}

	public function exitPlayState()
		EventState.changeState(PlayState.storyWeek >= 0 ? new StoryMenuState() : new FreeplayState());

	private function pauseAndOpenState(state:EventSubstate) {
		persistentUpdate = false;
		keysPressed = [];
		FlxG.sound.music.pause();
		vocals.pause();

		_requestedSubState = state;
		resetSubState();
	}

	override function onFocusLost() {
		if (persistentUpdate)
			pauseAndOpenState(new PauseSubstate(camHUD, this));

		super.onFocusLost();
	}

	override function onFocus() {}
}
