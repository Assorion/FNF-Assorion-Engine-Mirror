package gameplay;

import flixel.FlxG;
import flixel.FlxSprite;

import backend.Song;
import states.PlayState;

#if !debug @:noDebug #end
class StrumNote extends FlxSprite {
	public static inline final NOTE_SPACING:Float = 160 * 0.7;

	/* pressTime is used in two ways: A) When it's an NPC strum: it's used to time how long is left before making the strum go static again.
	   or B) when it's a player's strum: pressTime will be used instead for double-tapping prevention. */
	public var pressTime:Float = 0; 
	public var isPlayer:Bool = false;

	public function new(X:Float, Y:Float, directions:Array<String>, data:Int = 0, player:Int = 0, isPlayer:Bool = false){
		super(X,Y);
		
		frames = Paths.lSparrow('gameplay/noteAssets');

		// Load animations into cache
		animation.addByPrefix('static', 'arrow' + directions[data]);
		animation.addByPrefix('press', Note.NOTE_COLOURS[data] + ' press'  , 24, false);
		animation.addByPrefix('glow',  Note.NOTE_COLOURS[data] + ' confirm', 24, false);
		playAnim('glow');
		playAnim('press');
		playAnim('static');

		setGraphicSize(Math.round(width * 0.7));
		updateHitbox();

		x += NOTE_SPACING * data;
		x += 98;
		x += (FlxG.width / 2) * player;
		alpha = 0;

		this.isPlayer = isPlayer;
	}

	override function update(elapsed:Float){
		super.update(elapsed);

		if(pressTime < 0) 
			return;

		pressTime -= elapsed * Song.division * 1000;
		if(pressTime <= 0 && (!isPlayer || Settings.botplay))
			playAnim();
	}

	public function playAnim(?animationName:String = 'static'){
		animation.play(animationName, true);
		centerOffsets();
		centerOrigin ();
	}  
}
