package gameplay;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

import backend.Song;
import ui.Alphabet;
import ui.MenuTemplate;
import ui.NewTransition;
import states.PlayState;

class PauseSubstate extends EventSubstate {
	private final OPTION_LIST:Array<String> = ['Resume Game', 'Restart Song', 'Toggle Botplay', 'Exit To Menu'];
	
	public var curSelected:Int = 0;
	public var pauseText:FormattedText;
	public var alphaTexts:Array<MenuObject> = [];

	var bottomBlack:StaticSprite;
	var blackSpr:StaticSprite;
	var pauseMusic:FlxSound;
	var playState:PlayState;
	var creationTimeStamp:Float;
	var activeTweens:Array<FlxTween> = [];

	public function new(camera:FlxCamera, ps:PlayState) {
		super();

		playState = ps;	
		creationTimeStamp = CoolUtil.getCurrentTime();

		pauseMusic = new FlxSound().loadEmbedded(Paths.lMusic('gameplay/breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play();
		FlxG.sound.list.add(pauseMusic);

		blackSpr = new StaticSprite(0,0).makeGraphic(camera.width, camera.height, FlxColor.BLACK);
		blackSpr.alpha = 0;
		add(blackSpr);

		for(i in 0...OPTION_LIST.length) {
			var option:Alphabet = new Alphabet(0, MenuTemplate.Y_SPACING * i, OPTION_LIST[i], true);
			option.alpha = 0;
			add(option);

			alphaTexts.push({
				obj: cast option,
				targetX: 0,
				targetY: 0,
				targetA: 1
			});
		}

		bottomBlack = new StaticSprite(0, camera.height - 30).makeGraphic(1280, 30, FlxColor.BLACK);
		pauseText = new FormattedText(5, camera.height - 25, 0, '', null, 20);
		bottomBlack.alpha = pauseText.alpha = 0;

		add(bottomBlack);
		add(pauseText);

		changeSelection(0);
		cameras = [camera];
		updatePauseText();

		/////////////////////

		activeTweens.push(FlxTween.tween( bottomBlack, {alpha:	0.6 }, 0.2 ));
		activeTweens.push(FlxTween.tween( pauseText  , {alpha:	1	}, 0.2 ));
		activeTweens.push(FlxTween.tween( pauseMusic , {volume: 0.5 },	4  ));
		activeTweens.push(FlxTween.tween( blackSpr	 , {alpha:	0.7 }, 0.45));
	}

	private function updatePauseText(){
		var coolString:String = 
		'SONG: ${PlayState.songData.name.toUpperCase()}' +
		' | WEEK: ${PlayState.storyWeek >= 0 ? Std.string(PlayState.storyWeek + 1) : "FREEPLAY"}' +
		' | BOTPLAY: ${Settings.botplay ? "YES" : "NO"}' +
		' | DIFFICULTY: ${Song.DIFFICULTIES[PlayState.curDifficulty].toUpperCase()}' +
		' | ';
		pauseText.text = '$coolString$coolString$coolString';
	}

	private var leaving:Bool = false;
	private function leave(){
		leaving = true;

		for(i in 0...activeTweens.length)
			if (activeTweens[i] != null)
				activeTweens[i].cancel();

		for(i in 0...alphaTexts.length)
			alphaTexts[i].targetA = 0;

		FlxTween.tween(pauseText,  { alpha:  0 }, 0.4);
		FlxTween.tween(bottomBlack,{ alpha:  0 }, 0.4);
		FlxTween.tween(pauseMusic, { volume: 0 }, 0.4);
		FlxTween.tween(blackSpr,   { alpha:  0 }, 0.4, {onComplete: function(t:FlxTween){ // Closing
			pauseMusic.stop();
			pauseMusic.destroy();
			playState.persistentUpdate = true;
			close();

			for(ev in playState.events)
				ev.endTime += CoolUtil.getCurrentTime() - creationTimeStamp;
			
			if (FlxG.sound.music.time <= 0)
				return;

			playState.vocals.play();
			FlxG.sound.music.play();
			FlxG.sound.music.time = playState.vocals.time = Song.millisecond + Settings.audio_offset;
		}});
	}

	private function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.lSound('ui/scrollMenu'), 0.4);
		curSelected = CoolUtil.intCircularModulo(curSelected + change, OPTION_LIST.length);

		for(i in 0...alphaTexts.length){
			var item = alphaTexts[i];
			item.targetA = i != curSelected ? 0.4 : 1;

			item.targetY = (i - curSelected) * MenuTemplate.Y_SPACING;
			item.targetX = (i - curSelected) * MenuTemplate.X_SPACING;
			item.targetY += MenuTemplate.Y_OFFSET;
			item.targetX += MenuTemplate.X_OFFSET;
		}
	}

	override public function keyHit(ev:KeyboardEvent)
	if (!leaving)
		ev.keyCode.bindFunctions([
			[Binds.ui_back, leave],
			[Binds.ui_up,   function(){ changeSelection(-1); }],
			[Binds.ui_down, function(){ changeSelection(1);  }],
			[Binds.ui_accept, function(){
				switch(curSelected){
				case 0:
					leave();
				case 1:
					NewTransition.skippedLast = true;
					FlxG.resetState();
				case 2:
					Settings.botplay = !Settings.botplay;
					playState.updateHealth(0);

					updatePauseText();
					pauseText.alpha = 0;
					alphaTexts[curSelected].obj.alpha = 0;
					activeTweens.push(FlxTween.tween(pauseText, {alpha: 1}, 0.3));
				case 3:
					playState.exitPlayState();
				}
			}]
		]);

	override function update(elapsed:Float){
		super.update(elapsed);

		var lerpVal = Math.pow(0.5, elapsed * 15);
		for(i in 0...alphaTexts.length){
			var alT = alphaTexts[i];
			alT.obj.alpha = FlxMath.lerp(alT.targetA, alT.obj.alpha, lerpVal);
			alT.obj.y	  = FlxMath.lerp(alT.targetY, alT.obj.y    , lerpVal);
			alT.obj.x	  = FlxMath.lerp(alT.targetX, alT.obj.x    , lerpVal);
		}

		pauseText.x += elapsed * 70;
		if (pauseText.x >= 5) 
			pauseText.x = pauseText.x - (pauseText.width / 3);
	}
}
