package backend;

import haxe.Json;

using StringTools;

typedef NoteData = {
	var strumTime:Float;
	var column:Int;
	var length:Int;
	var player:Int;
	var type:Int;
}

typedef SectionData = {
	var cameraFacing:Int;
	var notes:Array<NoteData>;
}

typedef CharacterData = {
	var name:String;
	var x:Float;
	var y:Float;
}

typedef ChartData = {
	var name:String;
	var BPM:Float;
	var speed:Float;
	var stage:String;
	var hasVoices:Bool;

	var characters:Array<CharacterData>;
	var characterCharts:Int;
	var activePlayer:Int;
	var renderBackwards:Bool;

	var startDelay:Float;

	var sections:Array<SectionData>;

	var healthColours:Array<Int>;
	var iconNames:Array<String>;
}

class Chart {
	public static final DIFFICULTIES:Array<String> = ['easy', 'normal', 'hard'];

	private static var scores:Map<String, Int>;

	public static function loadScores()
		scores = SettingsManager.gSave.data.scores != null ? SettingsManager.gSave.data.scores : new Map<String, Int>();

	public static function loadFromJson(songStr:String, diff:Int):ChartData {
		songStr = songStr.toLowerCase();
		
		var tmpCast:ChartData = cast Json.parse(Paths.text('songs/$songStr/${DIFFICULTIES[diff]}.json'));
		if (cast(tmpCast.characterCharts, Int) <= 0) 
			tmpCast.characterCharts = 2;

		return tmpCast;
	}

	public static function getScore(name:String, diff:Int):Int {
		name = (name + DIFFICULTIES[diff]).toLowerCase().trim();
		return scores.exists(name) ? scores.get(name) : 0;
	}

	public static function saveScore(song:String, score:Int, diff:Int){
		if (getScore(song, diff) >= score) 
			return;

		scores.set((song + DIFFICULTIES[diff]).toLowerCase().trim(), score);
		SettingsManager.gSave.data.scores = scores;
		SettingsManager.flush();
	}
}
