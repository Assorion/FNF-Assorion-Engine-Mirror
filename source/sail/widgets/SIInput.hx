package sail.widgets;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import openfl.events.*;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;

using StringTools;

class SIInput extends SIGeneric {
	private var editing:Bool = false;
	private var bgSpr:SIStyle;
	private var textSpr:FormattedText;
	private var previousMuteKeys:Array<FlxKey>    = [];
	private var previousVolUpKeys:Array<FlxKey>   = [];
	private var previousVolDownKeys:Array<FlxKey> = [];

	public var curText:String = '';
	public var callback:String->Bool->Void = null;

	public var allowedSymbols = "1234567890qwertyuiopasdfghjklzxcvbnm`-=[];',./ ";

	public function new(?relativeSide:SISide = UNDER, ?defaultCorner:SIDiagonal = TOPLEFT, ?reference:SIGeneric
	, width:Int, defaultText:String = '', ?container:SIContainer = null) {
		super(relativeSide, defaultCorner, reference, width, null, container);
		
		textSpr   = new FormattedText(2, 0, 0, defaultText, 12, SIGeneric.TEXT_COLOUR);
		curText   = defaultText;
	}

	public function changeText(to:String, useCallback:Bool, finishCallback:Bool = false) {
		var prevText = curText;
		curText      = to;
		textSpr.text = to + (editing ? '_' : '');
		textSpr.x    = x + 3;
		textSpr.y    = y;
		textSpr.y   += (h - textSpr.height) / 2;

		if (textSpr.width > w) {
			changeText(prevText, false);
			return;
		}

		if (useCallback && callback != null)
			callback(curText, finishCallback);
	}

	public function keyHit(ev:KeyboardEvent) {
		var keyStr = backend.CoolUtil.keyCodeToString(ev.keyCode, true).toLowerCase();

		if (ev.keyCode == FlxKey.ENTER)
			master.changeLastComponent(null);

		if (ev.keyCode == FlxKey.BACKSPACE) 
			changeText(curText.substring(0, curText.length - 1), true);

		if (allowedSymbols.contains(keyStr))
			changeText(curText + keyStr, true);
	}

	override public function redraw() {
		super.redraw();

		bgSpr = Type.createInstance(style, [w, h]);
		bgSpr.drawSquare(0, 0, w, h, true);
		sprGroup.add(new StaticSprite().loadGraphic(bgSpr.getData()));
		sprGroup.add(textSpr);

		changeText(curText, false);
	}

	override public function onClickRelease() {
		super.onClickRelease();

		if (editing)
			return;

		previousMuteKeys    = FlxG.sound.muteKeys;
		previousVolUpKeys   = FlxG.sound.volumeUpKeys;
		previousVolDownKeys = FlxG.sound.volumeDownKeys;
		FlxG.sound.muteKeys = FlxG.sound.volumeUpKeys = FlxG.sound.volumeDownKeys = [];
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		FlxG.stage.dispatchEvent(new Event('input_grab'));

		editing = true;
		changeText(curText, false);
	}

	override public function offClick() {
		if (!editing)
			return;

		FlxG.sound.muteKeys       = previousMuteKeys;
		FlxG.sound.volumeUpKeys   = previousVolUpKeys;
		FlxG.sound.volumeDownKeys = previousVolDownKeys;
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		FlxG.stage.dispatchEvent(new Event('input_release'));

		editing = false;
		changeText(curText, true, true);
	}
}
