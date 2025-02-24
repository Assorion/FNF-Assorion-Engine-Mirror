package gameplay;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

import backend.Song;
import states.PlayState;

#if !debug @:noDebug #end
class GameOverSubstate extends EventSubstate {
	private var camFollow:FlxObject;
	private var characterRef:Character;
	private var blackFadeIn:StaticSprite;
	private var fadeCam:FlxCamera;
	private var playstateRef:PlayState;

	public function new(deadChar:Character, fadeOutCam:FlxCamera, pState:PlayState) {
		super();

		playstateRef = pState;

		var zoomMul:Float = 1 / FlxG.camera.zoom;
		blackFadeIn = new StaticSprite(0,0).makeGraphic(Math.round(FlxG.width * zoomMul), Math.round(FlxG.height * zoomMul), FlxColor.BLACK);
		blackFadeIn.scrollFactor.set();
		blackFadeIn.screenCenter();
		blackFadeIn.alpha = 0;
		add(blackFadeIn);

		/*
			The game over state doesn't create a new character, instead it pulls the
			current playing character out of PlayState and tells it to play the death animation.

			If instead your character uses a different sprite for it's death animations, you'll
			need to write some extra logic here to accommodate for that.
		*/

		characterRef = deadChar;
		deadChar.playAnim('firstDeath');
		fadeCam = fadeOutCam;
		playstateRef.remove(deadChar);
		add(deadChar);

		camFollow = new FlxObject(deadChar.getGraphicMidpoint().x, deadChar.getGraphicMidpoint().y, 1, 1);

		FlxG.sound.music.time = 0;
		FlxG.sound.play(Paths.lSound('gameplay/fnf_loss_sfx'));
		FlxG.camera.follow(camFollow, LOCKON, 0.023);

		Song.musicSet(100);

		FlxTween.tween(fadeCam,		{alpha: 0}, 3);
		FlxTween.tween(blackFadeIn, {alpha: 1}, 3, {onComplete: function(t:FlxTween){
			playstateRef.persistentDraw = false;

			remove(blackFadeIn);
			blackFadeIn.destroy();
			blackFadeIn = null;
		}});

		postEvent(2.5, function() {
			if(!leaving)
				FlxG.sound.playMusic(Paths.lMusic('gameOver'));
		});
	}

	override function update(elapsed:Float) {
		#if (flixel < "5.4.0")
		FlxG.camera.followLerp = (1 - Math.pow(0.5, FlxG.elapsed * 2)) * (60 / Settings.framerate);
		#end

		if(characterRef.animation.curAnim.finished)
			characterRef.playAnim('deathLoop');

		super.update(elapsed);
	}

	private var leaving:Bool = false;
	override function keyHit(ev:KeyboardEvent){
		if(leaving) {
			for(i in 0...events.length)
				events[i].exeFunc();
			
			return;
		}

		if(ev.keyCode.check(Binds.UI_BACK)){
			leaving = true;
			FlxG.sound.music.stop();
			playstateRef.exitPlayState();
			return;
		}

		if(!ev.keyCode.check(Binds.UI_ACCEPT))
			return;

		leaving = true;
		characterRef.playAnim('deathConfirm');
		FlxG.sound.music.stop();
		FlxG.sound.play(Paths.lSound('gameplay/gameOverEnd'));
		
		postEvent(0.7, function(){ FlxG.camera.fade(FlxColor.BLACK, 2, false); });
		postEvent(2.7, function(){
			FlxG.resetState();
		});
	}
}
