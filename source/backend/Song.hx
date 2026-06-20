package backend;

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

	private static function beatHit():Void 
		for(i in 0...beatHooks.length)
			beatHooks[i]();

	private static function stepHit():Void { 
		currentBeat = currentStep >> 2; 
		if (currentStep % 4 == 0)		
			beatHit();

		for(i in 0...stepHooks.length)
			stepHooks[i]();
	}

	public static function configure(tempo:Float) {
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
}
