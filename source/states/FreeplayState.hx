package states;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;

import backend.Song;
import backend.HighScore;
import ui.Alphabet;
import ui.MenuTemplate;
import ui.NewTransition;
import ui.CharacterIcon;

using StringTools;

typedef FreeplaySongData = {
	var name:String;
	var icon:String;
}

#if !debug @:noDebug #end
class FreeplayState extends MenuTemplate {
	private static var curDifficulty:Int = 1;
	public var songList:Array<FreeplaySongData> = [];
	public var intendedScore:Int = 0;

	private var scoreBG:StaticSprite;
	private var scoreText:FormattedText;
	private var diffText:FormattedText;
	private var vocals:FlxSound;

	override function create() {
		addBG(145, 113, 255);
		super.create();

		songList = cast haxe.Json.parse(Paths.lText('freeplaySongList.json'));
		for(i in 0...songList.length){
			pushObject(new Alphabet(0, (60 * i) + 30, songList[i].name, true));
			pushIcon(new CharacterIcon(songList[i].icon, false));
		}

		var bottomBlack:StaticSprite = new StaticSprite(0, FlxG.height - 30).makeGraphic(1280, 30, FlxColor.BLACK);
		var descText = new FormattedText(5, FlxG.height - 25, 0, "Press Space to preview song / stop song. Left or Right to change the difficulty.", null, 20);
		scoreBG   = new StaticSprite(0, 0).makeGraphic(128, 66, 0xFF000000);
		scoreText = new FormattedText(scoreBG.x + 6, 5, 0, null, null, 32, FlxColor.WHITE, LEFT);
		diffText  = new FormattedText(scoreText.x, scoreText.y + 36, 0, "< NORMAL >", null, 24);
		scoreBG.alpha = 0.6;
		bottomBlack.alpha = 0.6;

		add(scoreBG);
		add(diffText);
		add(scoreText);
		add(bottomBlack);
		add(descText);

		changeSelection();
		altChange();

		vocals = new FlxSound();
		FlxG.sound.list.add(vocals);	
	}

	override function altChange(change:Int = 0){
		curDifficulty += change + Song.DIFFICULTIES.length;
		curDifficulty %= Song.DIFFICULTIES.length;

		diffText.text = '< ${Song.DIFFICULTIES[curDifficulty].toUpperCase()} >';
		scoreText.text = 'PERSONAL BEST: ${HighScore.getScore(songList[curSel].name, curDifficulty)}';

		scoreBG.scale.x = (scoreText.width + 10) / scoreBG.frameWidth;
		scoreBG.updateHitbox();
		scoreBG.x = 1280 - scoreBG.width;
		scoreText.x = diffText.x = scoreBG.x + 5;
	}

	override function changeSelection(chng:Int = 0){
		super.changeSelection(chng);
		altChange();
	}

	private var prevTime:Float = 0;
	private var playing:Bool = true;
	override public function keyHit(ev:KeyboardEvent){
		super.keyHit(ev);

		ev.keyCode.bindFunctions([
			[[FlxKey.SPACE], function(){
				playing = !playing;

				if(playing){
					FlxG.sound.playMusic(Paths.lMusic(Paths.MENU_MUSIC));
					FlxG.sound.music.time = prevTime;
					Song.musicSet(Paths.MENU_TEMPO);

					if(vocals == null) 
						return;
					
					vocals.stop();
					vocals.destroy();
					vocals = new FlxSound();
					return;
				}

				prevTime = FlxG.sound.music.time;
				
				FlxG.sound.playMusic(Paths.playableSong(songList[curSel].name));
				vocals.loadEmbedded(Paths.playableSong(songList[curSel].name, true));
				vocals.play();
				vocals.time = FlxG.sound.music.time = 0;	
			}],
			[Binds.ui_accept, function(){
				if(NewTransition.skip()) 
					return;

				PlayState.storyPlaylist = [];
				PlayState.curDifficulty = curDifficulty;
				PlayState.storyWeek     = -1;
				PlayState.totalScore    = 0;
				PlayState.songData      = Song.loadFromJson(songList[curSel].name, curDifficulty);
				EventState.changeState(new PlayState());
				FlxG.sound.music.stop();

				if (vocals.playing)
					vocals.stop();
			}]
		]);
	}
}
