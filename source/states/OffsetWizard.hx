package states;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import backend.Song;
import ui.NewTransition;

class OffsetWizard extends EventState {
	public var oldOffset:Int = 0;
	public var newOffset:Int = 0;

	private var offsetGraph:BitmapData;
	private var infoText:FormattedText;
	private var offsetText:FormattedText;

	var lastBeatTime:Float = 0;
	var hitOffsets:Array<Float> = [];
	var activelyListening:Bool = false;

	override public function create(){
		super.create();
		
		FlxG.sound.playMusic(Paths.lMusic('ui/offsetSong'));
		FlxG.sound.music.looped = false;
		FlxG.sound.pause();
		Song.musicSet(115);

		oldOffset = Settings.audio_offset;
		Settings.audio_offset = 0;

		var bgImage:StaticSprite = new StaticSprite(0,0).loadGraphic(Paths.lImage("ui/defaultMenuBackground"));
		bgImage.color = FlxColor.fromRGB(110, 120, 255);
		
		infoText = new FormattedText(0, 0, 0, "Tap a key to the beat until the short song is over.\nIt is recommended to do this with your eyes closed.", null, 30, 0xFFFFFFFF, CENTER, OUTLINE);
		infoText.screenCenter();
		infoText.y -= 250;
		
		offsetText = new FormattedText(0, 0, 0, "Press any key to begin!", null, 60, 0xFFFFFFFF, CENTER, OUTLINE);
		offsetText.screenCenter();

		add(bgImage);
		add(offsetText);
		add(infoText);

		offsetGraph = new BitmapData(1100, 45, true, 0x66000000);
		offsetGraph.fillRect(new Rectangle(548, 0, 5, 45), 0xFFFF0000);
	}

	override function update(elapsed:Float){
		super.update(elapsed);

		if(activelyListening)
			Song.update(FlxG.sound.music.time);
	}

	public function stepHit() {
		if((Song.currentStep - 2) & 3 == 0)
			lastBeatTime = CoolUtil.getCurrentTime() + (Song.crochet * 0.0005);

		if(Song.currentStep <= 132)
			return;

		activelyListening = false;
		lastBeatTime = 0;

		for(i in 0...hitOffsets.length)
			lastBeatTime += hitOffsets[i] / hitOffsets.length;
		
		newOffset = Math.round(Math.max(lastBeatTime, 0));
		offsetText.text = 'Your offset: ${newOffset}ms\nPress any key to save your results';
		offsetText.screenCenter(); 

		offsetGraph.fillRect(new Rectangle((lastBeatTime / Song.crochet * 1100) + 548, 0, 5, 45), 0xFF00FF00);
	}

	private var countdownHappening:Bool = false;
	function startCountdown() {
		var introSounds:Array<String> = ['intro3', 'intro2', 'intro1', 'introGo'];
		var introStrings:Array<String> = ['Three', 'Two', 'One', 'Go!'];
		var graphSprite:StaticSprite = new StaticSprite(0, 0).loadGraphic(offsetGraph);

		graphSprite.screenCenter();
		graphSprite.y += 250;
		graphSprite.alpha = 0;
		graphSprite.scale.set(0.8, 0.8);
		add(graphSprite);

		FlxTween.tween(graphSprite,		  {alpha: 1  },	1,	 {ease: FlxEase.sineOut});
		FlxTween.tween(graphSprite.scale, {x: 1, y: 1}, 1.2, {ease: FlxEase.sineOut});
		countdownHappening = true;

		for(i in 0...4){	
			var snd:FlxSound = new FlxSound().loadEmbedded(Paths.lSound('gameplay/' + introSounds[i]));
			FlxG.sound.list.add(snd);
			snd.volume = 0.6;

			postEvent(i * Song.crochet * 0.001, function(){
				snd.play();
				offsetText.text = introStrings[i];
				offsetText.screenCenter();	
			});
		}

		postEvent(4 * Song.crochet * 0.001, function(){
			offsetText.text = "Join in the beat at anytime";
			offsetText.screenCenter();

			FlxG.sound.music.time = 0;
			FlxG.sound.music.play();

			activelyListening = true;
			countdownHappening = false;
			lastBeatTime = CoolUtil.getCurrentTime();
			Song.stepHooks.push(stepHit);
		});
	}

	private var leaving:Bool = false;	
	override function keyHit(ev:KeyboardEvent){
		if(ev.keyCode.check(Binds.ui_back) || leaving){
			if(leaving){
				NewTransition.skip();
				return;
			}

			Settings.audio_offset = oldOffset;
			EventState.changeState(new OptionsState());
			leaving = true;

			if(FlxG.sound.music != null && FlxG.sound.music.playing)
				FlxG.sound.music.stop();

			return;
		}

		if(!FlxG.sound.music.playing && !countdownHappening){
			if(hitOffsets.length > 0){
				Settings.audio_offset = newOffset;
				EventState.changeState(new OptionsState());

				leaving = true;
				return;
			} 

			startCountdown();
		}

		if(!activelyListening)
			return;
		
		var tappedOffset:Float = (CoolUtil.getCurrentTime() - lastBeatTime) * 1000;
		hitOffsets.push(tappedOffset);

		offsetText.text = 'Last hit: ${Math.round(tappedOffset)}ms';
		offsetText.screenCenter();

		offsetGraph.fillRect(new Rectangle((tappedOffset / Song.crochet * 1100) + 550, 0, 1, 45), 0xFFFFFF00);
	}
}
