package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;

import gameplay.Note;
import states.ChartingState;

using StringTools;

/*
	In retrospect, it is not recommended to write a custom UI.
	The code, is unfortunately quite messy. And naturally may lend itself to weird bugs.
	
	One day, this code may be replaced. As for now this will stay as-is.
*/

class ChartUI_Grid extends StaticSprite {
    public var gridColours:Array<Array<Array<Int>>> = [
        [[255, 200, 200], [255, 215, 215]], // Red
        [[200, 200, 255], [215, 215, 255]], // Blue
        [[240, 240, 200], [240, 240, 215]], // Yellow / White
        [[200, 255, 200], [215, 255, 215]], // Green
    ];

	public function new(cWidth:Int, cHeight:Int, columns:Int, rows:Int, division:Int = 4) {
		var emptySprite:BitmapData = new BitmapData(cWidth * columns, cHeight * rows, true);
		var colOffset:Int = 0;

		for(i in 0...columns)
			for(j in 0...rows){
				var grCol = CoolUtil.cfArray(gridColours[j % division][(i + colOffset) % 2]);

				emptySprite.fillRect(new Rectangle(i * cWidth, j * cHeight, cWidth, cHeight), grCol);
				colOffset++;
			}

		// blackline down the middle.
		for(i in 1...Math.floor(columns / Note.keyCount))
			emptySprite.fillRect(new Rectangle((cWidth * Note.keyCount * i) - 2, 0, 4, cHeight * rows), FlxColor.BLACK);

		super(0,0);
		
		loadGraphic(emptySprite);
	}
}

class ChartUI_Generic extends FlxSprite {
	public static var uiColours:Array<Array<Int>> = [
		[155, 100, 160], // Dark
		[200, 120, 210], // Light
		[240, 150, 250], // 3D light
		[170, 170, 200], // Note select colour
		[20,  45,  55 ], // Swamp green background colour
	];

	public var blockInput:Bool = false;
	public var canvas:BitmapData;

	public inline function drawSquare(dx:Int, dy:Int, w:Int, h:Int, ?indent:Bool = false){
		var col1:Int = indent ? 0 : 2;
		var col2:Int = indent ? 2 : 0;

		canvas.fillRect(new Rectangle(dx+3,dy+3, w-6, h-6), CoolUtil.cfArray(uiColours[1]));

		// Dark
		canvas.fillRect(new Rectangle(dx+1,dy+h-3, w-1,   3), CoolUtil.cfArray(uiColours[col2]));
		canvas.fillRect(new Rectangle(dx+w-3,  dy, 3,	h-3), CoolUtil.cfArray(uiColours[col2]));
		
		// Light
		canvas.fillRect(new Rectangle(dx,	   dy,	 w-3,	3), CoolUtil.cfArray(uiColours[col1]));
		canvas.fillRect(new Rectangle(dx+w-3,  dy,	 1,		2), CoolUtil.cfArray(uiColours[col1]));
		canvas.fillRect(new Rectangle(dx+w-2,  dy,	 1,		1), CoolUtil.cfArray(uiColours[col1]));

		canvas.fillRect(new Rectangle(dx,	 dy+3,	 3,   h-5), CoolUtil.cfArray(uiColours[col1]));
		canvas.fillRect(new Rectangle(dx,  dy+h-2,	 2,		1), CoolUtil.cfArray(uiColours[col1]));
		canvas.fillRect(new Rectangle(dx,  dy+h-1,	 1,		1), CoolUtil.cfArray(uiColours[col1]));

	}

	public inline function makeText(w:Int, h:Int, ?indent:Bool = false, ?txt:String = '', ?dx:Int = 0, ?dy:Int = 0){
		drawSquare(dx,dy, w,h, indent);

		if(txt != null && txt != '') {
			var text:FlxText = new FlxText(0,0,0,txt,16);
			stamp(text, dx + Std.int((w - text.width) / 2), dy + Std.int((h - text.height) / 2));
		}
	}

	public function keyInsert(k:Int){}
	public function mouseOverlaps(){}
	public function mouseDown(){
		ChartingState.currentElement = this;
	}
	public function mouseUp(){
		ChartingState.currentElement = null;
	}
	public function forceExit(){
		ChartingState.currentElement = null;
	}

	public function new(x:Float, y:Float, w:Int, h:Int, i:Bool, t:String){
		super(x,y);

		canvas = new BitmapData(w, h, true);
		loadGraphic(canvas);
		makeText(w,h,i,t);
		antialiasing = false;
	}
}

class ChartUI_Text extends ChartUI_Generic {
	public function new(x:Float, y:Float, t:String){
		super(x+1280,y, 0, 0, false, '');

		var text:FlxText = new FlxText(0,0,0,t,12);
		loadGraphic(text.graphic);

		offset.x += 1280; // Required to prevent highlighting text.
	}
}

class ChartUI_CheckBox extends ChartUI_Generic{
	public var changeFunc:Bool->Void;
	public var checked:Bool = false;

	public function new(x:Float, y:Float, ?w:Int = 30, ?h:Int = 30, startChecked:Bool = false, onChange:Bool->Void){
		super(x,y,w,h,true,'');

		changeFunc = onChange;
		checked = startChecked;

		if(checked)
			drawSquare(6,6, w - 12, h - 12, false);
	}

	override public function mouseDown(){
		super.mouseDown();

		checked = !checked;
		drawSquare(6,6, Math.floor(width) - 12, Math.floor(height) - 12, true);
	}

	override public function mouseUp(){
		super.mouseUp();

		var w = Math.floor(width);
		var h = Math.floor(height);

		changeFunc(checked);
		drawSquare(0,0,w,h,true);

		if(checked) 
			drawSquare(6,6, w - 12, h - 12, false);
	}
}

class ChartUI_Button extends ChartUI_Generic {
	public var dropDownButton:Bool = false;

	public var clickFunc:Void->Void;
	public var txt:String = '';

	public var popupCounter:Float = 0;
	private static inline var clickTime:Float = 0.08;

	public function new(x:Float, y:Float, ?w:Int = 90, ?h:Int = 30, onClick:Void->Void, ?text:String){
		super(x,y,w,h,false,text);

		clickFunc = onClick;
		txt = text;
	}

	override public function mouseDown(){
		super.mouseDown();

		makeText(Math.floor(width), Math.floor(height), true, txt);
		if(dropDownButton) 
			return;

		clickFunc();
	}

	override public function mouseUp(){
		super.mouseUp();

		if(dropDownButton){
			clickFunc();
			return;
		}

		makeText(Math.floor(width), Math.floor(height), false, txt);
	}

}

class ChartUI_InputBox extends ChartUI_Generic {
	public var curText:String = '';
	public var changeFunc:String->Void;
	public var uneditedText:String = '';
	public static inline var allowedCharacters:String = "abcdefghijklmnopqrstuvwxyz1234567890-+=_!@#$%^&*(){}[]\\;'\":,.<>/? ";

	private var tickingCounter:Float = 0;
	private var suffix:String = ' _';

	public inline function redoText(){
		curText = uneditedText;
		if(ChartingState.currentElement == this)
			curText += suffix;

		makeText(Math.floor(width), Math.floor(height), true, curText, 0,0);
	}

	public function new(x:Float, y:Float, ?w:Int = 90, ?h:Int = 30, startText:String = '', onChange:String->Void){
		super(x,y,w,h,true,startText);

		changeFunc = onChange;
		uneditedText = startText;
	}
	
	public override function forceExit(){
		super.forceExit();

		changeFunc(uneditedText);
		redoText();

		FlxG.sound.muteKeys = [FlxKey.ZERO];
	}

	public override function mouseDown(){
		super.mouseDown();

		pSuffix = '';
		suffix	= ' _';
		tickingCounter = 0;

		redoText();

		FlxG.sound.muteKeys = [];
	}
	public override function keyInsert(char:Int){
		if(char == FlxKey.BACKSPACE){
			uneditedText = uneditedText.substring(0, uneditedText.length - 1);
			redoText();
			return;
		}

		var tmpChar:String = CoolUtil.getKeyNameFromString( char, true, true ).toLowerCase();
		if(!allowedCharacters.contains(tmpChar)) return;

		uneditedText += tmpChar;
		redoText();
	}

	private var pSuffix:String = '';
	override function update(elapsed:Float)
	if(ChartingState.currentElement == this){

		tickingCounter += elapsed;
		if(tickingCounter >= 1) 
			tickingCounter -= 1;

		pSuffix = tickingCounter < 0.5 ? ' _' : '	';

		if(pSuffix == suffix) 
			return;

		suffix = pSuffix;
		redoText();
	}

	override public function mouseUp(){}
}

// This is super messy. Sorry.
class ChartUI_DropDown extends ChartUI_Generic {
	public var parentGroup:FlxTypedSpriteGroup<ChartUI_Generic>;
	public var buttonList:Array<ChartUI_Button> = [];
	public var changeFunc:Int->String->Void;
	public var expanded:Bool = false;
	public var items:Array<String>;
	public var curText:String = '';
	public var prevDotButton:Bool = false;

	public inline function dotButton(open:Bool){
		var w:Int = Math.floor(width) - 30;
		var h:Int = Math.floor(height);

		makeText(w,  h, open, curText, 0, 0);
		makeText(30, h, open, expanded ? '^' : 'v', w, 0);

		prevDotButton = open;
	}

	public function new(x:Float, y:Float, ?w:Int = 90, ?h:Int = 30, items:Array<String>, text:String = '', onChange:Int->String->Void, parent:FlxTypedSpriteGroup<ChartUI_Generic>){
		super(x,y,w + 30,h,false,'');

		changeFunc	= onChange;
		parentGroup = parent;
		curText		= text;
		this.items	= items;

		dotButton(false);
	}

	public function removeButtons(){
		for(i in 0...buttonList.length){
			parentGroup.remove(buttonList[i], true);

			buttonList[i].destroy();
			buttonList[i] = null;
		}

		buttonList = [];
	}
	
	override public function forceExit(){
		if(!buttonList.contains(cast(ChartingState.overlappingElement, ChartUI_Button))){
			expanded = false;
			removeButtons();

			if(!prevDotButton)
				dotButton(false);
		}

		if(!prevDotButton)
			super.forceExit();
	}

	public override function mouseDown(){
		dotButton(true);

		expanded = !expanded;
		if(!expanded){
			forceExit();
			return;
		}

		super.mouseDown();

		var w:Int = Math.floor(width);
		var h:Int = Math.floor(height);

		for(i in 0...items.length){
			buttonList[i] = new ChartUI_Button(x - parentGroup.x,(y - parentGroup.y) + (h * (i + 1)), w, h, function(){
				curText = items[i];
				expanded = false;

				changeFunc(i, items[i]);
				removeButtons();
				dotButton(false);

				ChartingState.overlappingElement = ChartingState.currentElement = null;
			}, items[i]);

			buttonList[i].dropDownButton = true;
			parentGroup.add(buttonList[i]);
		}
	}
	public override function mouseUp(){
		dotButton(false);
		if(prevDotButton)
			ChartingState.currentElement = null;
	}
}
