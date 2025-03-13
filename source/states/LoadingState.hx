package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUIState;
import openfl.utils.Assets;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;

using StringTools;

#if !debug @:noDebug #end
class LoadingState extends FlxUIState {
	public static inline var barWidth:Int = 1150;
	public static inline var barTopLn:Int = 150; 
	public static inline var inBarWidth:Int = 1120;
	public static inline var inBarTopLn:Int = 120;

	private var loadingBarBG:FlxSprite;
	private var loadingBarPC:FlxSprite;
	private var assetText:FormattedText;
	private var keepGraphic:BitmapData;

	public var objects:Array<String> = Assets.list();

	override function create(){
		FlxG.mouse.visible = persistentUpdate = false;

		var i = -1;
		while(++i < objects.length)
			if(objects[i].split('/')[0] != 'assets')
				objects.splice(i--, 1);

		var lbBG:BitmapData = new BitmapData(barWidth, barTopLn, true);
		lbBG.fillRect(new Rectangle(0 , 0 , barWidth   , barTopLn), 0xFFFFFFFF);
		lbBG.fillRect(new Rectangle(10, 10, barWidth-20, barTopLn-20), 0);

		keepGraphic = new BitmapData(inBarWidth, inBarTopLn, true);
		keepGraphic.fillRect(new Rectangle(0,0,inBarWidth,inBarTopLn), 0);

		loadingBarBG = new FlxSprite(0,0).loadGraphic(lbBG);
		loadingBarBG.screenCenter();

		loadingBarPC = new FlxSprite(0,0).loadGraphic(keepGraphic);
		loadingBarPC.screenCenter();

		var ldText = new FormattedText(0, 0, 0, "Loading:", null, 50, 0xFFFFFFFF, CENTER);
		ldText.screenCenter();
		ldText.y -= ldText.height * 4;

		assetText = new FormattedText(0, 0, 0, "", null, 40, 0xFFFFFFFF, CENTER);
		assetText.screenCenter();
		assetText.y -= assetText.height * 3.3;

		add(loadingBarBG);
		add(loadingBarPC);
		add(ldText);
		add(assetText);

		super.create();
	}

	private inline function addAsset(objectPath:String, objFormat:String)
		switch(objFormat){
		case 'png':
			var tmpImg:FlxSprite = new FlxSprite(0,0).loadGraphic(objectPath);
			tmpImg.graphic.persist = true;
			tmpImg.graphic.destroyOnNoUse = false;

			add(tmpImg);
			remove(tmpImg);
		case 'xml':
			var tmpImg:FlxSprite = new FlxSprite(0,0);
			tmpImg.frames = Paths.lSparrow(objectPath.substring(0, objectPath.length - 4), '');
			tmpImg.graphic.persist = true;
			tmpImg.graphic.destroyOnNoUse = false;

			add(tmpImg);
			remove(tmpImg);
		
		case 'ogg', 'mp3':
			var sound:FlxSound = new FlxSound().loadEmbedded(objectPath);
			sound.volume = 0.1;

			sound.play();
			sound.stop();
		case 'txt', 'json':
			Paths.lText(objectPath, '');
		}

	private var index:Int = 0;
	override function update(elapsed:Float){
		if(index == objects.length - 1) {
			objects = null;
			FlxG.camera.bgColor = 0x00000000;
			FlxG.camera.bgColor.alpha = 0;
			FlxG.switchState(cast Type.createInstance(Main.initState, []));
			return;
		}
		
		var obj:String = objects[index];
		trace('Caching: $obj');

		assetText.text = obj;
		assetText.screenCenter(X);

		var tmp = obj.split('.');
		var ending:String = tmp[tmp.length - 1];

		addAsset(obj, ending);
		index++;

		// Bar and text.
		var percent:Float = index / (objects.length - 1);

		var selColour:Int = FlxColor.fromRGB(
			Math.round(percent * 255), 
			180 + Math.round(75 * percent), 
			155 + Math.round(100 * percent)
		);

		keepGraphic.fillRect(new Rectangle(0,0,   Math.round(percent * inBarWidth), inBarTopLn), selColour);
		FlxG.camera.bgColor = FlxColor.fromRGB(0, Math.round(percent * 120), Math.round(percent * 103));
	}
}
