package backend;

using StringTools;

class HighScore {
	private static var songScores:Map<String, Int>;

	public static function loadScores()
		songScores = SettingsManager.gSave.data.songScores != null ? SettingsManager.gSave.data.songScores : new Map<String, Int>();

	public static inline function scoreExists(s:String):Int {
		s = s.toLowerCase().trim();

		return songScores.exists(s) ? songScores.get(s) : 0;
	}

	public static function saveScore(song:String, score:Int, diff:Int){
		var songNaem:String = song.toLowerCase().trim() + Song.DIFFICULTIES[diff];

		if (scoreExists(songNaem) >= score) 
			return;

		songScores.set(songNaem, score);
		SettingsManager.gSave.data.songScores = songScores;
		SettingsManager.flush();
	}

	public static function getScore(song:String, diff:Int):Int
		return scoreExists(song + Song.DIFFICULTIES[diff]);
}
