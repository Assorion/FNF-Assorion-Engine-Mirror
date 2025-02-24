package backend;

import haxe.Json;

using StringTools;

typedef SectionData = {
	var sectionNotes:Array<Dynamic>;
	var cameraFacing:Int;
}

typedef CharacterData = {
	var name:String;
	var x:Float;
	var y:Float;
}

typedef SongData = {
	var name:String;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var stage:String;

	var playLength:Int;
	var activePlayer:Int;
	var characters:Array<CharacterData>;
	var renderBackwards:Bool;

	var startDelay:Float;

	var notes:Array<SectionData>;
}

#if !debug @:noDebug #end
class Song {
	public static var beatHooks:Array<Void->Void> = [];
	public static var stepHooks:Array<Void->Void> = [];

	public static var BPM		 :Float;
	public static var crochet	 :Float;
	public static var stepCrochet:Float;
	public static var division	 :Float;
	public static var millisecond:Float;
	public static var currentStep:Int;
	public static var currentBeat:Int;

	public static function musicSet(tempo:Float) {
		var newCrochet = (60 / tempo) * 250;

		BPM			= tempo;
		crochet		= newCrochet * 4;
		stepCrochet = newCrochet;
		division	= 1 / newCrochet;
		millisecond = -Settings.audio_offset;
		currentStep = 0;
		currentBeat = 0;
	}

	public static function clearHooks() {
		beatHooks = [];
		stepHooks = [];
	}

	public static function update(followTime:Float){
		millisecond = followTime - Settings.audio_offset;

		var newStep = Math.floor(millisecond * division);
		if (currentStep != newStep && (currentStep = newStep) >= -1)
			stepHit();
	}

	private static function beatHit():Void 
		for(i in 0...beatHooks.length)
			beatHooks[i]();

	private static function stepHit():Void { 
		currentBeat = currentStep >> 2; 
		if(currentStep & 3 == 0)		
			beatHit();

		for(i in 0...stepHooks.length)
			stepHooks[i]();
	}

	public static function loadFromJson(songStr:String, diff:Int):SongData {
		songStr = songStr.toLowerCase();
		
		var tmpCast:SongData = cast Json.parse(Paths.lText('songs/$songStr/${CoolUtil.diffString(diff, 0)}.json')).song;

		if (cast(tmpCast.playLength, Int) <= 0) 
			tmpCast.playLength = 2;

		return tmpCast;
	}
}
