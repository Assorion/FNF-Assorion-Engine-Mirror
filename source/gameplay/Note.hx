package gameplay;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;

class Note extends FlxSprite
{
	public static var colArr:Array<String> = ['purple', 'blue', 'green', 'red'];

	public var strumTime:Float = 0;
	public var curColor:String = 'purple';
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var player  :Int = 0;
	public var noteData:Int = 0;

	public var chartRef:Array<Dynamic> = [];

	//public var canBeHit:Bool = false;
	//public var tooLate:Bool = false;
	//public var wasGoodHit:Bool = false

	//public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	//public var noteScore:Float = 1;

	// this is inlined, you can't change this variable later.
	public static inline var swagWidth:Float = 160 * 0.7;

	public function new(strumTime:Float, data:Int, ?sustainNote:Bool = false, ?isEnd:Bool = false)
	{
		super();

		//x += 50;
		y = -2000;

		isSustainNote  = sustainNote;
		this.strumTime = strumTime;
		this.noteData  = data % 4;

		curColor = colArr[noteData];

		frames = Paths.lSparrow('gameplay/NOTE_assets');
		if(isSustainNote){
			animation.addByPrefix('holdend', '$curColor hold end');
			animation.addByPrefix('hold'   , '$curColor hold piece');
		} else 
			animation.addByPrefix('scroll' , curColor + '0');

		setGraphicSize(Std.int(width * 0.7));
		antialiasing = Settings.pr.antialiasing;

		//x += swagWidth * noteData;

		animation.play('scroll');
		updateHitbox();
		centerOffsets();
		centerOrigin ();

		if (!isSustainNote) return;

		alpha = 0.6;
		flipY = Settings.pr.downscroll;
		offsetX += width / 2;

		animation.play('holdend');

		var calc:Float = Conductor.stepCrochet / 100 * (1.2 * (44 / 140)) * PlayState.SONG.speed;
		var holdScale = scale.y = (scale.y * calc);

		if(Settings.pr.downscroll)
			offsetY += height * (calc * 1.2);

		updateHitbox();
		offsetX -= width / 2;
		offsetY += (Settings.pr.downscroll ? -7 : 7) * PlayState.SONG.speed;

		if (isEnd) return;

		animation.play('hold');
		scale.y = holdScale * (140 / 44);
		if(!Settings.pr.downscroll)
			updateHitbox();
	}
}
