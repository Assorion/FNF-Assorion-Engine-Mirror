package gameplay;

import backend.Song;
import states.PlayState;

typedef NoteType = {
	var assets:String;
	var mustHit:Bool;
	var rangeMul:Float;
	var onHit:Void->Void;
	var onMiss:Void->Void;
}

#if !debug @:noDebug #end
class Note extends StaticSprite { // If animated notes are desired, this will have to be changed from a StaticSprite to FlxSprite.
	public static var NOTE_COLOURS:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var NOTE_TYPES:Array<NoteType> = [
		{
			assets: 'noteAssets',
			mustHit: true,
			rangeMul: 1,
			onHit: null, 
			onMiss: null
		}
	];

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var curType:NoteType;
	public var player  :Int = 0;
	public var noteData:Int = 0;
	public var strumTime:Float = 0;
	public var isSustainNote:Bool = false;

	public function new(strumTime:Float, ?data:Int = 0, ?type:Int = 0, ?sustainNote:Bool = false, ?isEnd:Bool = false) {
		super();

		isSustainNote  = sustainNote;
		this.strumTime = strumTime;
		this.noteData  = data % PlayState.KEY_COUNT;
		this.curType   = NOTE_TYPES[type];

		var colour = NOTE_COLOURS[noteData];
		frames = Paths.lSparrow('gameplay/${curType.assets}');

		animation.addByPrefix('scroll' , colour + '0');
		if(isSustainNote){
			animation.addByPrefix('holdend', '$colour hold end');
			animation.addByPrefix('hold'   , '$colour hold piece');
		} 

		setGraphicSize(Std.int(width * 0.7));
		
		animation.play('scroll');
		centerOffsets();
		updateHitbox ();

		if (!isSustainNote) 
			return;

		alpha = 0.6;
		flipY = Settings.downscroll;
		offsetX += width / 2;
		var defaultOffset = (flipY ? -7 : 7) * PlayState.songData.speed;

		animation.play('holdend');

		var calc:Float = Song.stepCrochet / 100 * ((Song.BPM / 100) * (44 / 140)) * PlayState.songData.speed;
		scale.y = (scale.y * calc);

		if(Settings.downscroll)
			offsetY += height * (calc * 0.5);

		updateHitbox();
		offsetX -= width / 2;
		offsetY += defaultOffset;
		animation.remove('scroll');

		if(!isEnd) {
			animation.play('hold');
			scale.y = scale.y * (140 / 44);
			offsetY = defaultOffset;
			updateHitbox();
		}
	}

	public inline function typeAction(action:Int) {
		var curAct:Void->Void = [curType.onHit, curType.onMiss][action];
		if(curAct != null)
			curAct();
	}
}
