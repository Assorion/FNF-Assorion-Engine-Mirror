package gameplay;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import haxe.Json;

import backend.Song;

using StringTools;

typedef AnimationData = {
	var animationName:String;
	var xmlName:String;
	var framerate:Int;
	var loop:Bool;
	var offsetX:Int;
	var offsetY:Int;
}

typedef CharacterData = {
	var idleSpeed:Int;
	var leftRightIdle:Bool;
	var flipX:Bool;
	var cameraOffsetX:Int;
	var cameraOffsetY:Int;
	var animations:Array<AnimationData>;
}

class Character extends FlxSprite {
	public var animOffsets:Map<String, Array<Int>> = new Map<String, Array<Int>>();
	public var camOffset:Array<Int> = [0,0];
	public var curCharacter:String;
	public var isPlayer:Bool;

	public var leftRightIdle:Bool = false;
	public var idleNextBeat :Bool = true;
	public var idlingSpeed:Int = 0;
	public var danced:Bool = false;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false) {
		Song.beatHooks.push(dance);
		super(x, y);

		this.isPlayer = isPlayer;
		curCharacter  = character;
		frames = Paths.lSparrow('gameplay/characters/$character');

		var charData:CharacterData = cast Json.parse(Paths.lText('characters/${character}.json'));

		idlingSpeed   = charData.idleSpeed;
		leftRightIdle = charData.leftRightIdle;
		flipX		  = charData.flipX;
		camOffset	  = [charData.cameraOffsetX, charData.cameraOffsetY];

		for(anim in charData.animations){
			animation.addByPrefix(anim.animationName.trim(), anim.xmlName.trim(), anim.framerate, anim.loop);
			animOffsets.set(anim.animationName.trim(), [anim.offsetX, anim.offsetY]);
			animation.play(anim.animationName.trim());
		}

		playAnim(leftRightIdle ? 'danceLeft' : 'idle');
	
		if (isPlayer) { 
			flipX = !flipX;
			camOffset[0] = -camOffset[0];
		}
	}

	public function dance() // 1 << idlingSpeed exponentially increases the beats per idle.
	if (FlxMath.absInt(Song.currentBeat) & (1 << idlingSpeed) - 1 == 0){
		if (!idleNextBeat){
			idleNextBeat = true;
			return;
		}

		if (!leftRightIdle){
			playAnim('idle', true);
			return;
		}

		danced = !danced;
		playAnim('dance' + (danced ? 'Right' : 'Left'), true);
	}

	public function playAnim(AnimName:String, ?INB:Bool = false) {
		idleNextBeat = INB;
		
		// Prevents crashes by checking if animation exists.
		var curOffset:Array<Int> = animOffsets.get(AnimName);
		if (curOffset != null && curOffset.length == 2) {
			animation.play(AnimName, true);
			offset.set(curOffset[0], curOffset[1]);
		}
	}
}
