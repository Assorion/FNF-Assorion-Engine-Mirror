package backend;

import haxe.Json;

using StringTools;

typedef NoteData = {
	var strumTime:Float;
	var column:Int;
	var length:Int;
	var type:Int;
	var parentSection:Int;
}

typedef SectionData = {
	var sectionNotes:Array<NoteData>;
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
	public static final DIFFICULTIES:Array<String> = ['easy', 'normal', 'hard'];

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
		currentStep = -1;
		currentBeat = -1;
	}

	public static function clearHooks() {
		beatHooks = [];
		stepHooks = [];
	}

	public static function update(followTime:Float){
		var oldStep = currentStep;
		millisecond = followTime - Settings.audio_offset;
		currentStep = Math.floor(millisecond * division);

		if (oldStep != currentStep)
			stepHit();
	}

	private static function beatHit():Void 
		for(i in 0...beatHooks.length)
			beatHooks[i]();

	private static function stepHit():Void { 
		currentBeat = currentStep >> 2; 
		if (currentStep & 3 == 0)		
			beatHit();

		for(i in 0...stepHooks.length)
			stepHooks[i]();
	}

	public static function loadFromJson(songStr:String, diff:Int):SongData {
		songStr = songStr.toLowerCase();
		
		var tmpCast:SongData = cast Json.parse(Paths.lText('songs/$songStr/${DIFFICULTIES[diff]}.json')).song;

		if (cast(tmpCast.playLength, Int) <= 0) 
			tmpCast.playLength = 2;

		return tmpCast;
	}
}
