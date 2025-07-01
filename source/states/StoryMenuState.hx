package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

import backend.Song;
import backend.HighScore;
import ui.MenuTemplate;
import ui.NewTransition;

using StringTools;

typedef StoryData = {
	var weekAsset:String;
	var songs:Array<String>;
	var topText:String;
}

class StoryMenuState extends MenuTemplate {
	public static inline final SELECT_COLOUR:Int = 0xFF00FFFF;
	public static inline final WHITE_COLOUR :Int = 0xFFFFFFFF;

	private static var curDif:Int = 1;

	private var weekData:Array<StoryData> = [];

	public var weekBGs:Array<FlxSprite> = [new FlxSprite(640), new FlxSprite(640)];
	public var topText:FormattedText;
	public var trackList:FormattedText;

	var arrowSpr1:StaticSprite;
	var arrowSpr2:StaticSprite;
	var diffImage:StaticSprite;

	override function create(){
		super.create();

		weekData = cast haxe.Json.parse(Paths.lText('storyWeeks.json'));
		
		for(i in 0...weekData.length) {
			var weekGraphic:FlxSprite = new FlxSprite(0,0).loadGraphic(Paths.lImage('storyMenu/weeks/week-' + weekData[i].weekAsset));
			weekGraphic.updateHitbox();
			weekGraphic.centerOrigin();
			weekGraphic.scale.set(0.7, 0.7);
			weekGraphic.offset.x += 100;

			pushObject(weekGraphic);
		}

		var topBlack:StaticSprite = new StaticSprite(0,0).makeGraphic(640, 20, FlxColor.fromRGB(25,25,25));
		topText = new FormattedText(0, 2, 0, "", null, 18, FlxColor.GRAY, CENTER);
		topText.screenCenter(X);
		topText.x -= 320;

		arrowSpr1 = new StaticSprite(640 - 50, 42).loadGraphic(Paths.lImage('storyMenu/storyArrow'));
		arrowSpr1.centerOrigin();
		arrowSpr2 = new StaticSprite(640 - 330, 42).loadGraphic(Paths.lImage('storyMenu/storyArrow'));
		arrowSpr2.flipX = true;
		arrowSpr2.centerOrigin();

		diffImage = new StaticSprite(640, 45);
		diffImage.scale.set(0.7, 0.7);

		trackList = new FormattedText(0, 110, 0, "Tracks", null, 32, 0xFFE55777, CENTER);
		trackList.screenCenter(X);
		trackList.x -= 167.5;
		add(topBlack);
		add(topText);
		add(arrowSpr1);
		add(arrowSpr2);
		add(diffImage);
		add(trackList);

		changeSelection(0);
	}

	private var leaving:Bool = false;
	override function keyHit(ev:KeyboardEvent){
		super.keyHit(ev);

		if (!ev.keyCode.check(Binds.ui_accept)) 
			return;

		if (leaving){
			executeAllEvents();
			NewTransition.skip();
			return;
		}

		FlxG.sound.play(Paths.lSound('ui/confirmMenu'));
		leaving = true;

		PlayState.lastSeenCutscene = 0;	
		PlayState.storyPlaylist    = weekData[curSel].songs;
		PlayState.curDifficulty    = curDif;
		PlayState.storyWeek        = curSel;
		PlayState.totalScore       = 0;
		PlayState.songData         = Song.loadFromJson(weekData[curSel].songs[0], curDif);

		for(i in 0...8)
			postEvent(i / 8, function(){
				arrGroup[curSel].obj.color = (i & 1 == 0 ? WHITE_COLOUR : SELECT_COLOUR);
			});

		// SWITCH!
		postEvent(1, function(){
			EventState.changeState(new PlayState());
			
			if (FlxG.sound.music.playing)
				FlxG.sound.music.stop();
		});
	}

	public function changeDiff(to:Int, showArr:Bool){
		if (showArr){
			var arrow = [arrowSpr2, arrowSpr1][CoolUtil.intBoundTo(to, 0, 1)];
			arrow.color = SELECT_COLOUR;
			arrow.scale.set(0.9, 0.9);
		}

		curDif = CoolUtil.intCircularModulo(curDif + to, Song.DIFFICULTIES.length);

		diffImage.loadGraphic(Paths.lImage('storyMenu/' + Song.DIFFICULTIES[curDif]));
		diffImage.centerOrigin();
		diffImage.updateHitbox();
		diffImage.screenCenter(X);
		diffImage.x -= 167.5;

		topText.text = weekData[curSel].topText + ' - ${HighScore.getScore('week-$curSel', curDif)}';
		topText.screenCenter(X);
		topText.x -= 320;
	}

	override function keyRel(ev:KeyboardEvent){
		super.keyRel(ev);
		
		ev.keyCode.bindFunctions([
			[Binds.ui_left, function(){
				arrowSpr2.scale.set(1, 1);
				arrowSpr2.color = WHITE_COLOUR;
			}],
			[Binds.ui_right, function(){
				arrowSpr1.scale.set(1, 1);
				arrowSpr1.color = WHITE_COLOUR;
			}]
		]);
	}
	
	private var portraitTween:FlxTween;
	override function changeSelection(to:Int = 0){
		arrGroup[curSel].obj.color = WHITE_COLOUR;
		super.changeSelection(to);
		arrGroup[curSel].obj.color = SELECT_COLOUR;

		changeDiff(0, false);

		trackList.text = 'Tracks:\n';
		for(i in 0...weekData[curSel].songs.length)
			trackList.text += weekData[curSel].songs[i].toUpperCase() + '\n';

		trackList.screenCenter(X);
		trackList.x -= 167.5;

		// Portrait code
		weekBGs.push(weekBGs.shift());
		weekBGs[0].loadGraphic(Paths.lImage('storyMenu/weeks/portrait-${weekData[curSel].weekAsset}'));
		weekBGs[0].alpha = 0;
		weekBGs[1].alpha = 1;
		add(weekBGs[0]);

		if (portraitTween != null)
			portraitTween.cancel();

		portraitTween = FlxTween.tween(weekBGs[0], {alpha: 1}, 0.12, {onComplete: function(t:FlxTween){
			remove(weekBGs[1], true);
		}});
	}

	override function altChange(to:Int = 0)
		changeDiff(to, true);
}
