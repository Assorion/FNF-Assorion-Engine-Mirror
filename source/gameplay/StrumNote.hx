package gameplay;

import flixel.FlxG;
import flixel.FlxSprite;

import backend.Song;
import states.PlayState;

#if !debug @:noDebug #end
class StrumNote extends FlxSprite {
	public var isPlayer:Bool = false;
	public var pressTime:Float = 0;
	public var curState:Int = 0;

	public function new(X:Float, Y:Float, data:Int = 0, player:Int = 0, isPlayer:Bool = false){
		super(X,Y);
		
		frames = Paths.lSparrow('gameplay/NOTE_assets');

		// Load animations into cache
		animation.addByPrefix('static', 'arrow' + PlayState.singDirections[data]);
		animation.addByPrefix('pressed', Note.colourArray[data] + ' press'	, 24, false);
		animation.addByPrefix('confirm', Note.colourArray[data] + ' confirm', 24, false);
		playAnim(2);
		playAnim(1);
		playAnim(0);

		setGraphicSize(Math.round(width * 0.7));
		updateHitbox();

		x += Note.swagWidth * data;
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

	// This 'state' variable is used simply cause string checks are more expensive than integer checks.
	public function playAnim(state:Int = 0){
		curState = state;

		animation.play(['static', 'pressed', 'confirm'][state], true);
		centerOffsets();
		centerOrigin ();
	}  
}
