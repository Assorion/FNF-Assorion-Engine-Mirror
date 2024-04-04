package gameplay;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import flixel.input.keyboard.FlxKey;
import flixel.group.FlxGroup.FlxTypedGroup;
import lime.utils.Assets;
import gameplay.HealthIcon;
import misc.Highscore;
import ui.FreeplayState;
import ui.ChartingState;
import misc.Song.SongData;
import misc.Song.SectionData;

using StringTools;

#if !debug @:noDebug #end
class PlayState extends MusicBeatState
{
	public static inline var beatHalfingTime:Int = 190;
	public static inline var inputRange:Float = 1.25; // 1 and a quarter steps of input range.	
	public static var sDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

	public static var songName:String = '';
	public static var SONG:SongData;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var curDifficulty:Int = 1;
	public static var totalScore:Int = 0;

	public var strumLineY:Int;
	public var vocals:FlxSound;
	public var followPos:FlxObject;
	public var unspawnNotes:Array<Note> = [];

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var notes:FlxTypedGroup<Note>;

	// health now goes from 0 - 100, instead of 0 - 2
	public var health   :Int = 50;
	public var combo    :Int = 0;
	public var hitCount :Int = 0;
	public var missCount:Int = 0;
	public var fcValue  :Int = 0;

	public var healthBarBG:StaticSprite;
	public var healthBar:HealthBar;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;

	public var paused:Bool = false;
	public var songScore:Int = 0;
	public var scoreTxt:FlxText;

	private var characterPositions:Array<Int> = [
		// dad
		100, 100,
		//bf
		770, 450,
		// gf
		400, 130
	];
	private var playerPos:Int = 1;
	private var allCharacters:Array<Character> = [];

	private static var stepTime:Float;
	public static var seenCutscene:Bool = false;

	public static function setData(songs:Array<String>, difficulty:Int = 1, week:Int = -1) {
		storyPlaylist = songs;
		curDifficulty = difficulty;
		storyWeek     = week;
		totalScore    = 0;

		SONG = misc.Song.loadFromJson(storyPlaylist[0], curDifficulty);
	}

	override public function create() {
		// # Camera Setup
		camGame = new FlxCamera();
		camHUD  = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		followPos = new FlxObject(0, 0, 1, 1);
		followPos.setPosition(FlxG.width / 2, FlxG.height / 2);

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxCamera.defaultCameras = [camGame];
		FlxG.camera.follow(followPos, LOCKON, 0.067);

		// # Song Setup
		songName = SONG.song.toLowerCase();
		Song.musicSet(SONG.bpm);

		vocals = new FlxSound();
		if (SONG.needsVoices)
			vocals.loadEmbedded(Paths.playableSong(songName, true));

		FlxG.sound.list.add(vocals);
		FlxG.sound.playMusic(Paths.playableSong(songName), 1, false);
		FlxG.sound.music.onComplete = endSong;
		FlxG.sound.music.stop();

		// # BG & UI setup
		handleStage();

		strumLineY = Settings.pr.downscroll ? FlxG.height - 150 : 50;
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		playerStrums   = new FlxTypedGroup<StrumNote>();
		notes          = new FlxTypedGroup<Note>();
		add(strumLineNotes);
		add(notes);

		generateChart();
		for(i in 0...SONG.playLength)
			generateStrumArrows(i, SONG.activePlayer == i);

		///////////////////////////////////////////////
		ratingSpr = new StaticSprite(0,0).loadGraphic(Paths.lImage('gameplay/sick'));
		ratingSpr.graphic.persist = true;
		ratingSpr.updateHitbox();
		ratingSpr.centerOrigin();
		ratingSpr.screenCenter();
		ratingSpr.scale.set(0.7, 0.7);
		ratingSpr.alpha = 0;
		add(ratingSpr);

		for(i in 0...3){
			var sRef = comboSprs[i] = new StaticSprite(0,0);
			sRef.frames = Paths.lSparrow('gameplay/comboNumbers');
			for(i in 0...10) 
				sRef.animation.addByPrefix('$i', '${i}num', 1, false);
			sRef.animation.play('0');
			sRef.updateHitbox();
			sRef.centerOrigin();
			sRef.screenCenter();
			sRef.y += 120;
			sRef.x += (i - 1) * 60;
			sRef.scale.set(0.6, 0.6);
			sRef.alpha = 0;
			add(sRef);
		}
		///////////////////////////////////////////////

		var baseY:Int = Settings.pr.downscroll ? 80 : 650;

		healthBarBG = new StaticSprite(0, baseY).loadGraphic(Paths.lImage('gameplay/healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();

		var healthColours:Array<Int> = [0xFFFF0000, 0xFF66FF33];
		healthBar = new HealthBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8));
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(healthColours[0], healthColours[1]);

		scoreTxt = new FlxText(0, baseY + 40, 0, "", 20);
		scoreTxt.setFormat("assets/fonts/vcr.ttf", 16, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		scoreTxt.scrollFactor.set();
		scoreTxt.screenCenter(X);

		iconP1 = new HealthIcon(SONG.characters[1], true);
		iconP2 = new HealthIcon(SONG.characters[0], false);
		iconP1.y = baseY - (iconP1.height / 2);
		iconP2.y = baseY - (iconP2.height / 2);

		// # Add to cameras
		strumLineNotes.cameras = [camHUD];
		notes.cameras          = [camHUD];
		if(Settings.pr.show_hud){
			add(healthBarBG);
			add(healthBar);
			add(scoreTxt);
			add(iconP1);
			add(iconP2);

			healthBar.cameras      = [camHUD];
			healthBarBG.cameras    = [camHUD];
			iconP1.cameras         = [camHUD];
			iconP2.cameras         = [camHUD];
			scoreTxt.cameras       = [camHUD];
		}

		stepTime = -16 - (Settings.pr.audio_offset * Song.Division);
		updateHealth(0);

		super.create();

		var stateHolder:Array<DialogueSubstate> = [];
		var seenCut:Bool = DialogueSubstate.crDialogue(camHUD, startCountdown, '$songName/dialogue.txt', this, stateHolder);

		postEvent(SONG.beginTime + 0.1, startCountdown);

		if(seenCut) return;
		events.splice(events.length - 1, 1);

		postEvent(0.8, function(){
			pauseAndOpenState(stateHolder[0]);
		});
	}

	public inline function addCharacters() {
		for(i in 0...SONG.characters.length)
			allCharacters.push(new Character(characterPositions[i * 2], characterPositions[(i * 2) + 1], SONG.characters[i], i == 1));
		
		for(i in 0...SONG.characters.length)
			add(allCharacters[SONG.renderBackwards ? i : (SONG.characters.length - 1) - i]);

		playerPos = SONG.activePlayer;
	}

	// put things like gf and bf positions here.
	public inline function handleStage() {
		switch(SONG.stage){
			case 'stage', '':
				FlxG.camera.zoom = 0.9;

				var bg:StaticSprite = new StaticSprite(-600, -200).loadGraphic(Paths.lImage('stages/stageback'));
					bg.setGraphicSize(Std.int(bg.width * 2));
					bg.updateHitbox();
					bg.scrollFactor.set(0.9, 0.9);
				add(bg);
				var stageFront:StaticSprite = new StaticSprite(-650, 600).loadGraphic(Paths.lImage('stages/stagefront'));
					stageFront.setGraphicSize(Std.int(stageFront.width * 2.2));
					stageFront.updateHitbox();
					stageFront.scrollFactor.set(0.9, 0.9);
				add(stageFront);
				var curtainLeft:StaticSprite = new StaticSprite(-500, -165).loadGraphic(Paths.lImage('stages/curtainLeft'));
					curtainLeft.setGraphicSize(Std.int(curtainLeft.width * 1.8));
					curtainLeft.updateHitbox();
					curtainLeft.scrollFactor.set(1.3, 1.3);
				add(curtainLeft);
				var curtainRight:StaticSprite = new StaticSprite(1406, -165).loadGraphic(Paths.lImage('stages/curtainRight'));
					curtainRight.setGraphicSize(Std.int(curtainRight.width * 1.8));
					curtainRight.updateHitbox();
					curtainRight.scrollFactor.set(1.3, 1.3);
				add(curtainRight);

				addCharacters();
		}
	}

	private inline function generateChart():Void {
		for(section in SONG.notes)
			for(fNote in section.sectionNotes){
				var time:Float = fNote[0];
				var noteData :Int = Std.int(fNote[1]);
				var susLength:Int = Std.int(fNote[2]);
				var player   :Int = CoolUtil.intBoundTo(Std.int(fNote[3]), 0, SONG.playLength - 1);
				var ntype    :Int = Std.int(fNote[4]);

				var newNote = new Note(time, noteData, ntype, false, false);
				newNote.scrollFactor.set();
				newNote.player = player;
				unspawnNotes.push(newNote);

				if(susLength > 1)
					for(i in 0...susLength+1){
						var susNote = new Note(time + i + 0.5, noteData, ntype, true, i == susLength);
						susNote.scrollFactor.set();
						susNote.player = player;
						unspawnNotes.push(susNote);
					}
			}
		unspawnNotes.sort((A,B) -> Std.int(A.strumTime - B.strumTime));
	}

	private function generateStrumArrows(player:Int, playable:Bool):Void
	for (i in 0...Note.keyCount)
	{
		var babyArrow:StrumNote = new StrumNote(0, strumLineY - 10, i, player);
		babyArrow.alpha = 0;

		strumLineNotes.add(babyArrow);
		if(playable) playerStrums.add(babyArrow);
	}

	function startCountdown():Void {
		for(i in 0...strumLineNotes.length)
			FlxTween.tween(strumLineNotes.members[i], {alpha: 1, y: strumLineNotes.members[i].y + 10}, 0.5, {startDelay: ((i % Note.keyCount) + 1) * 0.2});

		var introSprites:Array<StaticSprite> = [];
		var introSounds:Array<FlxSound>   = [];
		var introAssets :Array<String>    = [
			'ready', 'set', 'go', '',
			'intro3', 'intro2', 'intro1', 'introGo'
		]; 
		for(i in 0...4){
			var snd:FlxSound = new FlxSound().loadEmbedded(Paths.lSound('gameplay/' + introAssets[i + 4]));
				snd.volume = 0.6;
			introSounds[i] = snd;

			if(i > 3) continue;

			var spr:StaticSprite = new StaticSprite().loadGraphic(Paths.lImage('gameplay/${ introAssets[i] }'));
				spr.scrollFactor.set();
				spr.screenCenter();
				spr.alpha = 0;
				spr.active = false;
			add(spr);

			introSprites[i+1] = spr;
		}

		var swagCounter:Int = 0;
		var countTickFunc:Void->Void = function(){
			if(swagCounter >= 4){
				FlxG.sound.music.play();
				FlxG.sound.music.volume = 1;
				FlxG.sound.music.time = vocals.time = 0;
				Song.Position = -Settings.pr.audio_offset;

				vocals.play();
				return;
			}
			for(pc in allCharacters)
				pc.dance();

			stepTime = (swagCounter - 4) * 4;
			stepTime -= Settings.pr.audio_offset * Song.Division;

			introSounds[swagCounter].play();
			if(introSprites[swagCounter] != null)
				introSpriteTween(introSprites[swagCounter], 3, Song.StepCrochet, true);

			swagCounter++;
		}
		for(i in 0...5)
			postEvent(((Song.Crochet * (i + 1)) - Settings.pr.audio_offset) * 0.001, countTickFunc);
	}

	override function closeSubState() if(seenCutscene) { // To stop transistions from messing up cutscenes
		super.closeSubState();

		if(!paused) 
			return;

		paused = false;

		for(i in 0...events.length)
			events[i].endTime += MusicBeatState.curTime() - lastOpenTime;
		lastOpenTime = 0;

		if(FlxG.sound.music.time == 0) 
			return;

		FlxG.sound.music.time = vocals.time = Song.Position + Settings.pr.audio_offset;
		FlxG.sound.music.play();
		vocals.play();
	}

	var noteCount:Int = 0;
	override public function update(elapsed:Float) if(!paused) {
		var scaleVal = CoolUtil.boundTo(iconP1.scale.x - (elapsed * 2), 1, 1.2);
		iconP1.scale.set(scaleVal, scaleVal);
		iconP2.scale.set(scaleVal, scaleVal);

		if(seenCutscene)
			stepTime += (elapsed * 1000) * Song.Division;

		if (unspawnNotes[noteCount] != null && unspawnNotes[noteCount].strumTime - stepTime < 32)
			notes.add(unspawnNotes[noteCount++]);

		notes.forEachAlive(scrollNotes);

		super.update(elapsed);
	}

	override function beatHit() {
		super.beatHit();

		iconP1.scale.set(1.2,1.2);
		iconP2.scale.set(1.2,1.2);
		
		#if (flixel < "5.4.0")
		FlxG.camera.followLerp = (1 - Math.pow(0.5, FlxG.elapsed * 6)) * Main.framerateDivision;
		#end

		var sec:SectionData = SONG.notes[curBeat >> 2]; // "curBeat >> 2" is the same as "Math.floor(curBeat / 4)", but faster
		if(curBeat == ((curBeat >> 2) << 2) && FlxG.sound.music.playing){
			// prevent the Int from being null, if it is it will just be 0.
			var tFace:Int = sec != null ? cast(sec.cameraFacing, Int) : 0;

			var char = allCharacters[CoolUtil.intBoundTo(tFace, 0, SONG.playLength - 1)];
			followPos.x = char.getMidpoint().x + char.camOffset[0];
			followPos.y = char.getMidpoint().y + char.camOffset[1];
		}

		if(curBeat % (Math.floor(SONG.bpm / beatHalfingTime) + 1) == 0)
			for(pc in allCharacters)
				pc.dance();
	}
	override function stepHit() {
		super.stepHit();

		if(FlxG.sound.music.playing)
			stepTime = ((Song.Position * 3 * Song.Division) + stepTime) * 0.25;
	}

	// THIS IS WHAT UPDATES YOUR SCORE AND HEALTH AND STUFF!

	private static inline var iconSpacing:Int = 52;
	public function updateHealth(change:Int) {
		var fcText:String = ['?', 'SFC', 'GFC', 'FC', '(Bad) FC', 'SDCB', 'Clear'][fcValue];
		var accuracyCount:Float = CoolUtil.boundTo(Math.floor((songScore * 100) / ((hitCount + missCount) * 3.5)) * 0.01, 0, 100);

		scoreTxt.text = 'Notes Hit: $hitCount | Notes Missed: $missCount | Accuracy: $accuracyCount% - $fcText | Score: $songScore';
		scoreTxt.screenCenter(X);

		health = CoolUtil.intBoundTo(health + change, 0, 100);
		healthBar.percent = health;

		var calc = (0 - ((health - 50) * 0.01)) * healthBar.width;
		iconP1.x = 565 + (calc + iconSpacing); 
		iconP2.x = 565 + (calc - iconSpacing);
		iconP1.changeState(health < 20);
		iconP2.changeState(health > 80);

		if(health > 0) 
			return; 

		remove(allCharacters[playerPos]);
		pauseAndOpenState(new GameOverSubstate(allCharacters[playerPos], camHUD, this));
	}

	function hitNote(note:Note):Void {
		destroyNote(note, 0);

		if(!note.curType.mustHit){
			missNote(note.noteData);
			return;
		}

		playerStrums.members[note.noteData].playAnim(2);
		allCharacters[playerPos].playAnim('sing' + sDir[note.noteData]);
		vocals.volume = 1;

		if(!note.isSustainNote){
			hitCount++;
			popUpScore(note.strumTime);
		}
		
		updateHealth(5);
	}

	function missNote(direction:Int = 1):Void {
		if (combo > 20)
			for(i in 0...allCharacters.length)
				allCharacters[i].playAnim('sad');

		combo = 0;
		songScore -= 50;
		missCount++;
		vocals.volume = 0.5; // Halving the Vocals, instead of completely muting them.

		FlxG.sound.play(Paths.lSound('gameplay/missnote' + (Math.round(Math.random() * 2) + 1)), 0.2);

		allCharacters[playerPos].playAnim('sing' + sDir[direction] + 'miss');
		fcValue = missCount >= 10 ? 6 : 5;

		updateHealth(-10);
	}

	// For anything that would require keyboard input, please put it here, not update.

	public var hittableNotes:Array<Note> = [null, null, null, null];
	public var keysPressed:Array<Bool>   = [false, false, false, false];
	public var keysArray:Array<Array<Int>> = [Binds.NOTE_LEFT, Binds.NOTE_DOWN, Binds.NOTE_UP, Binds.NOTE_RIGHT];
	override function keyHit(ev:KeyboardEvent) if(!paused) {
		var k = ev.keyCode.deepCheck([Binds.UI_ACCEPT, Binds.UI_BACK, [FlxKey.SEVEN], [FlxKey.F12] ]);

		switch(k){
			case 0, 1:
				if(seenCutscene)	
					pauseAndOpenState(new PauseSubState(camHUD, this));
				return;
			case 2:
				MusicBeatState.changeState(new ChartingState());
				seenCutscene = false;
				return;
			case 3:
				misc.Screenshot.takeScreenshot();
				return;
		}

		// Assorions "Fast" input system
		var nkey = ev.keyCode.deepCheck(keysArray);
		if(nkey == -1 || keysPressed[nkey] || Settings.pr.botplay) return;

		keysPressed[nkey] = true;
		var strumRef = playerStrums.members[nkey];
		var noteRef  = hittableNotes[nkey];
		
		if(noteRef != null){
			hitNote(noteRef);
			strumRef.pressTime = Song.StepCrochet * 0.00075;
		} else if(strumRef.pressTime <= 0){
			strumRef.playAnim(1);
			if(!Settings.pr.ghost_tapping)
				missNote(nkey);
		}
	}
	override public function keyRel(ev:KeyboardEvent) {
		var nkey = ev.keyCode.deepCheck(keysArray);
		if (nkey == -1) 
			return;

		keysPressed[nkey] = false;
		playerStrums.members[nkey].playAnim();
	}

	private inline function scrollNotes(daNote:Note) {
		var nDiff:Float = stepTime - daNote.strumTime;
		daNote.y = (Settings.pr.downscroll ? 45 : -45) * nDiff * SONG.speed;
		daNote.y += strumLineY + daNote.offsetY;

		daNote.visible = Settings.pr.downscroll ? (daNote.y >= -daNote.height * daNote.scale.y) : (daNote.y <= FlxG.height);
		if(!daNote.visible) return;
		
		var strumRef = strumLineNotes.members[daNote.noteData + (Note.keyCount * daNote.player)];
		if((daNote.player != playerPos || Settings.pr.botplay) && daNote.curType.mustHit && stepTime >= daNote.strumTime){
			allCharacters[daNote.player].playAnim('sing' + sDir[daNote.noteData]);
			strumRef.playAnim(2);
			strumRef.pressTime = Song.StepCrochet * 0.001;

			notes.remove(daNote, true);
			daNote.destroy();
			
			vocals.volume = 1;

			return;
		}

		daNote.x = strumRef.x + daNote.offsetX;
		daNote.angle = strumRef.angle;

		if(daNote.player != playerPos || Settings.pr.botplay) 
			return;

		if(nDiff > inputRange){
			if(daNote.curType.mustHit)
				missNote(daNote.noteData);
			
			destroyNote(daNote, 1);
			return;
		}

		// Input stuff
		if (!daNote.isSustainNote && hittableNotes[daNote.noteData] == null && Math.abs(nDiff) <= inputRange * daNote.curType.rangeMul){
			hittableNotes[daNote.noteData] = daNote;
			return;
		}

		if(!daNote.isSustainNote || Math.abs(nDiff) >= 0.8 || !keysPressed[daNote.noteData]) 
			return;

		hitNote(daNote);
	}

	public static var possibleScores:Array<RatingData> = [
		{
			score: 350,
			threshold: 0,
			name: 'sick',
			value: 1
		},
		{
			score: 200,
			threshold: 0.45,
			name: 'good',
			value: 2
		},
		{
			score: 100,
			threshold: 0.65,
			name: 'bad',
			value: 3
		},
		{
			score: 25,
			threshold: 1,
			name: 'superbad',
			value: 4
		}
	];
	private var ratingSpr:StaticSprite;
	private var prevString:String = 'sick';
	private var comboSprs:Array<StaticSprite> = [];
	private var scoreTweens:Array<FlxTween> = [];
	private inline function popUpScore(strumtime:Float):Void {
		var noteDiff:Float = Math.abs(strumtime - (stepTime - (Settings.pr.input_offset * Song.Division)));
		combo++;

		var pscore:RatingData = null;
		for(i in 0...possibleScores.length)
			if(noteDiff >= possibleScores[i].threshold){
				pscore   = possibleScores[i];
			} else break;

		songScore += pscore.score;

		if(pscore.value > fcValue) 
			fcValue = pscore.value;

		if(pscore.score < 50 || combo > 999)
			combo = 0;

		//////////////////////////
		if(scoreTweens[0] != null)
			for(i in 0...4) scoreTweens[i].cancel();

		if(prevString != pscore.name){
			ratingSpr.loadGraphic(Paths.lImage('gameplay/' + pscore.name));
			ratingSpr.graphic.persist = true;
			prevString = pscore.name;
		}
		ratingSpr.centerOrigin();
		ratingSpr.screenCenter();

		var comsplit:Array<String> = Std.string(combo).split('');

		for(i in 0...3){
			var char = '0';
			if(3 - comsplit.length <= i) char = comsplit[i + (comsplit.length - 3)];

			var sRef = comboSprs[i];
			sRef.animation.play(char);
			sRef.screenCenter(Y);
			sRef.y += 120;
			scoreTweens[i+1] = introSpriteTween(sRef, 3, Song.StepCrochet * 0.5, false);
		}
		scoreTweens[0] = introSpriteTween(ratingSpr, 3,  Song.StepCrochet * 0.5, false);
	}

	function endSong():Void {
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		paused = true;

		Highscore.saveScore(SONG.song, songScore, curDifficulty);

		if (storyWeek == -1){
			CoolUtil.exitPlaystate();
			return;
		}
		
		totalScore += songScore;
		storyPlaylist.splice(0,1);

		if (storyPlaylist.length <= 0){
			Highscore.saveScore('week-$storyWeek', totalScore, curDifficulty);
			CoolUtil.exitPlaystate();
			return;
		}

		seenCutscene = false;
		SONG = misc.Song.loadFromJson(storyPlaylist[0], curDifficulty);
		FlxG.sound.music.stop();
		FlxG.resetState();
	}

	var lastOpenTime:Float;
	function pauseAndOpenState(state:MusicBeatSubstate) {
		paused = true;
		lastOpenTime = MusicBeatState.curTime();
		FlxG.sound.music.pause();
		vocals.pause();

		openSubState(state);
	}

	inline function destroyNote(note:Note, act:Int) {
		note.typeAction(act);
		notes.remove(note, true);
		note.destroy();

		if (hittableNotes[note.noteData] == note)
			hittableNotes[note.noteData] = null;
	}

	private inline function introSpriteTween(spr:StaticSprite, steps:Int, delay:Float = 0, destroy:Bool):FlxTween {
		spr.alpha = 1;
		return FlxTween.tween(spr, {y: spr.y + 10, alpha: 0}, (steps * Song.StepCrochet) / 1000, { ease: FlxEase.cubeInOut, startDelay: delay * 0.001,
			onComplete: function(twn:FlxTween)
			{
				if(destroy)
					spr.destroy();
			}
		});
	}

	override function onFocusLost() {
		super.onFocusLost();

		if(!paused && seenCutscene)
			pauseAndOpenState(new PauseSubState(camHUD, this));
	}
}

typedef RatingData = {
	var score:Int;
	var threshold:Float;
	var name:String;
	var value:Int;
}