package ui;

import lime.utils.Assets;
import flixel.FlxSprite;

import backend.Song;

#if !debug @:noDebug #end
class CharacterIcon extends FlxSprite {
	public var originalScale:Float = 1;
	public var curChar:String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false, ?bopOnBeat:Bool = false) {
		super();

		if (bopOnBeat)
			Song.beatHooks.push(iconBop);

		active = bopOnBeat;
		changeIcon(char, isPlayer);
	}
	
	public function changeIcon(char:String, isPlayer:Bool){
		var path = Paths.lImage('icons/$char');
		loadGraphic(Paths.lImage('icons/face'), true, 150, 150);

		if (Assets.exists(path))
			loadGraphic(path, true, 150, 150);

		animation.add('neutral', [0], 0, false, isPlayer);
		animation.add('losing',  [1], 0, false, isPlayer);
		animation.play('neutral');

		updateHitbox();
		centerOffsets();
		centerOrigin ();

		curChar = char;
		scrollFactor.set();
	}

	private function iconBop():Void
		scale.x = scale.y += 0.2;

	override function update(elapsed:Float)
		scale.x = scale.y = Math.max(scale.y - (elapsed * 2), originalScale);
}
