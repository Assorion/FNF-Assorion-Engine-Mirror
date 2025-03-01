package gameplay;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;

import backend.Song;
import ui.Alphabet;
import ui.MenuTemplate;
import ui.NewTransition;
import states.PlayState;

#if !debug @:noDebug #end
class PauseSubstate extends EventSubstate {
	public static inline var botplayText:String = 'BOTPLAY'; // Text that shows in PlayState when Botplay is turned on
	private var optionList:Array<String> = ['Resume Game', 'Restart Song', 'Toggle Botplay', 'Exit To Menu'];
	
	public var curSelected:Int = 0;
	public var pauseText:FormattedText;
	public var alphaTexts:Array<MenuObject> = [];

	var bottomBlack:StaticSprite;
	var blackSpr:StaticSprite;
	var pauseMusic:FlxSound;
	var playState:PlayState;
	var activeTweens:Array<FlxTween> = [];

	public function new(camera:FlxCamera, ps:PlayState) {
		super();

		playState = ps;

		pauseMusic = new FlxSound().loadEmbedded(Paths.lMusic('gameplay/breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play();
		FlxG.sound.list.add(pauseMusic);

		blackSpr = new StaticSprite(0,0).makeGraphic(camera.width, camera.height, FlxColor.BLACK);
		blackSpr.alpha = 0;
		add(blackSpr);

		for (i in 0...optionList.length) {
			var option:Alphabet = new Alphabet(0, MenuTemplate.yDiffer * i, optionList[i], true);
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
		' | DIFFICULTY: ${CoolUtil.diffString(PlayState.curDifficulty, 1).toUpperCase()}' +
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
		FlxTween.tween(blackSpr,   { alpha:  0 }, 0.4, {onComplete: 

		// Closing
		function(t:FlxTween){
			pauseMusic.stop();
			pauseMusic.destroy();
			playState.paused = false;
			close();

			if(FlxG.sound.music.time > 0){
				playState.vocals.play();
				FlxG.sound.music.play();
				FlxG.sound.music.time = playState.vocals.time = Song.millisecond + Settings.audio_offset;
			}
		}});
	}

	private function changeSelection(change:Int = 0)
	{
		if(leaving)
			return;

		FlxG.sound.play(Paths.lSound('ui/scrollMenu'), 0.4);
		curSelected = (curSelected + change + optionList.length) % optionList.length;

		for(i in 0...alphaTexts.length){
			var item = alphaTexts[i];
			item.targetA = i != curSelected ? 0.4 : 1;

			item.targetY = (i - curSelected) * MenuTemplate.yDiffer;
			item.targetX = (i - curSelected) * MenuTemplate.xDiffer;
			item.targetY += MenuTemplate.yOffset;
			item.targetX += MenuTemplate.xOffset;
		}
	}

	override public function keyHit(ev:KeyboardEvent)
		ev.keyCode.bindFunctions([
			[Binds.UI_UP,   function(){ changeSelection(-1); }],
			[Binds.UI_DOWN, function(){ changeSelection(1);  }],
			[Binds.UI_ACCEPT, function(){
				if(leaving)
					return;
	
				switch(curSelected){
					case 0:
						leave();
					case 1:
						NewTransition.skippedLast = true;
						FlxG.resetState();
					case 2:
						Settings.botplay = !Settings.botplay;
						playState.scoreTxt.text = botplayText;
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
