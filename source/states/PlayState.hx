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
	var name:String;
}

#if !debug @:noDebug #end
class PlayState extends EventState {
	public static inline var inputRange:Float = 1.25; // The input range is measured in steps. By default it is 1 and a quarter steps of input range. 
	public var singDirections:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	public var possibleScores:Array<RatingData> = [
		{
			score: 350,  
			threshold: 0,
			name: 'sick'
		},
		{
			score: 200,		  // Points to give
			threshold: 0.43,  // Threshold of a step where you get the score, E:G less than half a step.
			name: 'good'	  // Asset to load
		},
		{
			score: 100,
			threshold: 0.65,
			name: 'bad'
		},
		{
			score: 25,
			threshold: 0.9,
			name: 'superbad'
		}
	];

	public static var songData:SongData;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var curDifficulty:Int = 1;
	public static var totalScore:Int = 0;
	public static var lastSeenCutscene:Int;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var playerStrums:Array<StrumNote> = [];
	public var chartNotes:Array<Note> = [];
	public var currentNotes:FlxTypedGroup<Note>;

	public var health	:Int = 50; // Ranges from 0 to 100.
	public var combo	:Int = 0;
	public var hitCount :Int = 0;
	public var missCount:Int = 0;
	public var fcValue	:Int = 0;
	public var songScore:Int = 0;
	public var paused:Bool = false;

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
		super.create();
		
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

		scoreTxt = new FormattedText(0, baseY + 40, 0, PauseSubstate.botplayText, null, 16, 0xFFFFFFFF, CENTER, OUTLINE);
		scoreTxt.scrollFactor.set();
		scoreTxt.screenCenter(X);

		iconP1 = new CharacterIcon(songData.characters[1].name, true, true);
		iconP2 = new CharacterIcon(songData.characters[0].name, false, true);
		iconP1.y = baseY - (iconP1.height / 2);
		iconP2.y = baseY - (iconP2.height / 2);

		comboDisplay = new ComboDisplay(possibleScores, 0, 100);
		add(comboDisplay);

		// Add to cameras
		strumLineNotes.cameras = [camHUD];
		currentNotes.cameras   = [camHUD];
		if(Settings.show_hud){
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

		// If storyWeek is equal to -1 then it means that it's Freeplay. So if it's higher that means we're in story mode.
		if(storyWeek >= 0 && lastSeenCutscene != storyPlaylist.length){	
			var dialoguePath:String = 'assets/data/songs/${songData.name}/dialogue.json';			
			lastSeenCutscene = storyPlaylist.length;

			if(Assets.exists(dialoguePath)) {
				// The delay is purely for the transitions. If your transitions are longer or shorter then change the event delay.	
				postEvent(0.5, function(){ pauseAndOpenState(new DialogueSubstate(this, camHUD, Assets.getText(dialoguePath))); });
				return;
			}
		}

		postEvent(songData.startDelay + 0.1, startCountdown);
	}

	private function generateChart() {
		for(section in songData.notes)
			for(fNote in section.sectionNotes){
				var time:Float = fNote[0];
				var noteData :Int = Std.int(fNote[1]);
				var susLength:Int = Std.int(fNote[2]);
				var player	 :Int = CoolUtil.intBoundTo(Std.int(fNote[3]), 0, songData.playLength - 1);
				var ntype	 :Int = Std.int(fNote[4]);

				var newNote = new Note(time, noteData, ntype, false, false);
				newNote.scrollFactor.set();
				newNote.player = player;
				chartNotes.push(newNote);

				if(susLength > 1)
					for(i in 0...susLength+1){
						var susNote = new Note(time + i + 0.5, noteData, ntype, true, i == susLength);
						susNote.scrollFactor.set();
						susNote.player = player;
						chartNotes.push(susNote);
					}
			}

		chartNotes.sort((A,B) -> Std.int(A.strumTime - B.strumTime));
	}

	private function generateStrumArrows(player:Int)
		for (i in 0...Note.keyCount) {
			var babyArrow:StrumNote = new StrumNote(0, Settings.downscroll ? 560 : 40, singDirections, i, player, songData.activePlayer == player);

			strumLineNotes.add(babyArrow);
			if(babyArrow.isPlayer) 
				playerStrums[i] = babyArrow;
		}
	
	public function startCountdown() { 
		for(i in 0...strumLineNotes.length)
			FlxTween.tween(strumLineNotes.members[i], {alpha: 1, y: strumLineNotes.members[i].y + 10}, 0.5, {startDelay: ((i % Note.keyCount) + 1) * 0.2});

		var introSprites:Array<StaticSprite> = [];
		var introSounds:Array<FlxSound>   = [];
		var introAssets :Array<String>	  = [
			'ready', 'set', 'go', '',
			'intro3', 'intro2', 'intro1', 'introGo'
		];
 
		for(i in 0...4){
			var snd:FlxSound = new FlxSound().loadEmbedded(Paths.lSound('gameplay/' + introAssets[i + (introAssets.length >> 1)]));
			snd.volume = 0.6;
			introSounds[i] = snd;

			if(introAssets[i] == '') 
				continue;

			var spr:StaticSprite = new StaticSprite().loadGraphic(Paths.lImage('gameplay/${introAssets[i]}'));
			spr.cameras = [camHUD];
			spr.screenCenter();
			spr.alpha = 0;
			add(spr);

			introSprites[i+1] = spr;
		}

		var introBeatCounter:Int = 0;
		for(i in 0...5)
			postEvent(((Song.crochet * (i + 1)) + Settings.audio_offset) * 0.001, function(){
				if(introBeatCounter >= 4){
					FlxG.sound.music.play();
					FlxG.sound.music.volume = 1;
					Song.millisecond = -Settings.audio_offset;
	
					vocals.play();
					vocals.time = FlxG.sound.music.time = 0;
					return;
				}

				Song.currentBeat = introBeatCounter - 4;
				stepTime = (introBeatCounter - 4) * 4;
				stepTime -= Settings.audio_offset * Song.division;

				for(pc in allCharacters)
					pc.dance();
	
				introSounds[introBeatCounter].play();
				var introSpr = introSprites[introBeatCounter++];
				if(introSpr == null)
					return;

				introSpr.alpha = 1;
				FlxTween.tween(introSpr, {y: introSpr.y + 10, alpha: 0}, Song.stepCrochet * 0.003, { 
					ease: FlxEase.cubeInOut,
					startDelay: Song.stepCrochet * 0.001,
					onComplete: function(twn:FlxTween) {
						remove(introSpr);
					}
				});
			});
	}

	public function beatHit() {
		#if (flixel < "5.4.0")
		FlxG.camera.followLerp = (1 - Math.pow(0.5, FlxG.elapsed * 6)) * (60 / Settings.framerate);
		#end

		var sec:SectionData = songData.notes[Song.currentBeat >> 2]; // Same result as 'Math.floor(Song.currentBeat / 4)'
		if(Song.currentBeat & 3 == 0 && FlxG.sound.music.playing){   // Same result as 'Song.currentBeat % 4 == 0'
			var currentlyFacing:Int = (sec != null ? cast(sec.cameraFacing, Int) : 0);
			var char = allCharacters[CoolUtil.intBoundTo(currentlyFacing, 0, songData.playLength - 1)];

			followPos.x = char.getMidpoint().x + char.camOffset[0];
			followPos.y = char.getMidpoint().y + char.camOffset[1];
		}
	}

	public function stepHit() 
	if(Song.currentStep & 1 == 0 && FlxG.sound.music.playing)
		stepTime = (Song.millisecond * Song.division * 0.25) + (stepTime * 0.75);


	override public function update(elapsed:Float) 
	if(!paused) {
		Song.update(FlxG.sound.music.time);
		stepTime += elapsed * 1000 * Song.division;

		while(chartNotes[0] != null && chartNotes[0].strumTime - stepTime < 32)
			currentNotes.add(chartNotes.shift());	

		currentNotes.forEachAlive(scrollNotes);

		super.update(elapsed);
	}

	private function scrollNotes(daNote:Note) {
		var strumRef = strumLineNotes.members[daNote.noteData + (Note.keyCount * daNote.player)];
		var nDiff:Float = stepTime - daNote.strumTime;
		daNote.y = (Settings.downscroll ? 45 : -45) * nDiff * songData.speed;
		daNote.y += strumRef.y  + daNote.offsetY;

		daNote.visible = daNote.y >= -daNote.height * daNote.scale.y && daNote.y <= FlxG.height;
		if(!daNote.visible) 
			return;

		daNote.x = strumRef.x + daNote.offsetX;
		daNote.angle = strumRef.angle;
		
		// NPC Note Logic
		if(daNote.player != playerIndex || Settings.botplay){
			if(stepTime < daNote.strumTime || !daNote.curType.mustHit)
				return;

			allCharacters[daNote.player].playAnim('sing' + singDirections[daNote.noteData]);
			strumRef.playAnim('glow');
			strumRef.pressTime = 1.05;
			vocals.volume = 1;

			currentNotes.remove(daNote, true);
			daNote.destroy();
			return;
		}

		// Player Note Logic
		if(nDiff > inputRange){
			if(daNote.curType.mustHit)
				missNote(daNote.noteData);

			destroyNote(daNote, 1);
			return;
		}

		// Input range checks
		if(daNote.isSustainNote && Math.abs(nDiff) < 0.8 && keysPressed[daNote.noteData])
			hitNote(daNote);
		else if (hittableNotes[daNote.noteData] == null && Math.abs(nDiff) <= inputRange * daNote.curType.rangeMul)
			hittableNotes[daNote.noteData] = daNote;
	}

	public var hittableNotes:Array<Note> = [null, null, null, null];
	public var keysPressed:Array<Bool>	 = [false, false, false, false];
	public var keysArray:Array<Array<Int>> = [Binds.NOTE_LEFT, Binds.NOTE_DOWN, Binds.NOTE_UP, Binds.NOTE_RIGHT];
	override function keyHit(ev:KeyboardEvent) 
	if(!paused) {
		// Assorions input system
		var nkey = ev.keyCode.deepCheck(keysArray);
		if(nkey != -1 && !keysPressed[nkey] && !Settings.botplay){
			var strumRef = playerStrums[nkey];
			keysPressed[nkey] = true;
			
			if(hittableNotes[nkey] != null) {
				hitNote(hittableNotes[nkey]);
			} else if(strumRef.pressTime <= 0){
				strumRef.playAnim('press');

				if(!Settings.ghost_tapping)
					missNote(nkey);
			}

			return;
		}

		ev.keyCode.bindFunctions([
			[Binds.UI_ACCEPT, function(){ pauseAndOpenState(new PauseSubstate(camHUD, this)); }],
			[Binds.UI_BACK,   function(){ pauseAndOpenState(new PauseSubstate(camHUD, this)); }],
			[[FlxKey.SEVEN],  function(){ EventState.changeState(new ChartingState()); }]
		]);
	}

	override public function keyRel(ev:KeyboardEvent) {
		var nkey = ev.keyCode.deepCheck(keysArray);

		if(nkey != -1 && !paused){
			keysPressed[nkey] = false;
			playerStrums[nkey].playAnim('static');
		}
	}

	private static inline var iconSpacing:Int = 52;
	public function updateHealth(change:Int) {
		if(!Settings.botplay) {
			var fcText:String = ['?', 'SFC', 'GFC', 'FC', '(Bad) FC', 'SDCB', 'Clear'][fcValue];
			var accuracyCount:Float = CoolUtil.boundTo(Math.floor((songScore * 100) / ((hitCount + missCount) * 3.5)) * 0.01, 0, 100);

			scoreTxt.text = 'Notes Hit: $hitCount | Notes Missed: $missCount | Accuracy: $accuracyCount% - $fcText | Score: $songScore';
		}
		scoreTxt.screenCenter(X);
		
		health = CoolUtil.intBoundTo(health + change, 0, 100);
		healthBar.percent = health;
		
		var iconsMiddle = ((0 - ((health - 50) * 0.01)) * healthBar.width) + 565;
		iconP1.x = iconsMiddle + iconSpacing; 
		iconP2.x = iconsMiddle - iconSpacing;
		iconP1.animation.play(health < 20 ? 'losing' : 'neutral');
		iconP2.animation.play(health > 80 ? 'losing' : 'neutral');

		if(health <= 0)
			pauseAndOpenState(new GameOverSubstate(allCharacters[playerIndex], camHUD, this));
	}

	public function hitNote(note:Note) {
		destroyNote(note, 0);

		if(!note.curType.mustHit) {
			missNote(note.noteData);
			return;
		}

		playerStrums[note.noteData].playAnim('glow');
		playerStrums[note.noteData].pressTime = 0.66;
		allCharacters[playerIndex].playAnim('sing' + singDirections[note.noteData]);
		vocals.volume = 1;

		if(note.isSustainNote){
			updateHealth(2);
			return;
		}

		var curScore:RatingData = possibleScores[0];
		var curValue:Int = 1;

		for(i in 1...possibleScores.length)
			if(Math.abs(note.strumTime - stepTime) >= possibleScores[i].threshold){
				curValue = i+1;
				curScore = possibleScores[i];
			} else
				break;

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

		FlxG.sound.play(Paths.lSound('gameplay/missNote' + (Math.round(Math.random() * 2) + 1)), 0.2);
		allCharacters[playerIndex].playAnim('sing' + singDirections[direction] + 'miss');

		updateHealth(-10);
	}

	private inline function destroyNote(note:Note, act:Int) {
		note.typeAction(act);
		currentNotes.remove(note, true);
		note.destroy();

		if(hittableNotes[note.noteData] == note)
			hittableNotes[note.noteData] = null;
	}

	public function endSong():Void {
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		paused = true;

		HighScore.saveScore(songData.name, songScore, curDifficulty);

		if (storyWeek == -1){ // If it's freeplay
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
		FlxG.sound.music.stop();
		EventState.changeState(new PlayState());
	}

	public function exitPlayState()
		EventState.changeState(PlayState.storyWeek >= 0 ? new StoryMenuState() : new FreeplayState());

	private function pauseAndOpenState(state:EventSubstate) {
		paused = true;
		FlxG.sound.music.pause();
		vocals.pause();

		openSubState(state);
	}

	override function onFocusLost() {
		super.onFocusLost();

		if(!paused && FlxG.sound.music.playing)
			pauseAndOpenState(new PauseSubstate(camHUD, this));
	}
}
