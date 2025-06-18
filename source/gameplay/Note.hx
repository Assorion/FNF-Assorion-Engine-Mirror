package gameplay;

import backend.Song;
import states.PlayState;

typedef NoteType = {
	var assets:String;
	var mustHit:Bool;
	var onHit:Void->Void;
	var onMiss:Void->Void;
}

#if !debug @:noDebug #end
class Note extends StaticSprite { // If animated notes are desired, this will have to be changed from a StaticSprite to FlxSprite.
	public static final NOTE_COLOURS:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static final NOTE_TYPES:Array<NoteType> = [
		{
			assets: 'noteAssets',
			mustHit: true,
			onHit: null, 
			onMiss: null
		}
	];

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var curType:NoteType;
	public var player:Int = 0;
	public var column:Int = 0;
	public var strumTime:Float = 0;
	public var isSustainNote:Bool = false;

	public function new(strumTime:Float, ?initColumn:Int = 0, ?type:Int = 0, ?sustainNote:Bool = false, ?isEnd:Bool = false) {
		super();

		isSustainNote  = sustainNote;
		this.strumTime = strumTime;
		this.column    = initColumn % PlayState.KEY_COUNT;
		this.curType   = NOTE_TYPES[type];

		var colour = NOTE_COLOURS[column];
		frames = Paths.lSparrow('gameplay/${curType.assets}');

		animation.addByPrefix('scroll' , colour + '0');
		if (isSustainNote){
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

		animation.play('holdend');
		animation.remove('scroll');

		var calc:Float = Song.stepCrochet / 100 * ((Song.BPM / 100) * (44 / 140)) * PlayState.songData.speed;

		if (Settings.downscroll && isEnd)
			offsetY += height * (calc * 0.5);

		scale.y = (scale.y * calc);
		updateHitbox();
		offsetX -= width / 2;
		offsetY += (flipY ? -7 : 7) * PlayState.songData.speed;

		if (!isEnd) {
			animation.play('hold');
			scale.y = scale.y * (140 / 44);
			updateHitbox();
		}
	}

	public function typeAction(action:Int) {
		var curAct:Void->Void = [curType.onHit, curType.onMiss][action];

		if (curAct != null)
			curAct();
	}
}
