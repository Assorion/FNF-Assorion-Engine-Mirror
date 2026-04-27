package sail.presets;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;

import backend.CoolUtil;

using StringTools;

class SIInput extends SIGeneric {
	private var BGData:SIStyleGeneric;
	private var textSpr:FormattedText;
	private var editing:Bool = false;
	private var previousMuteKeys:Array<FlxKey>    = [];
	private var previousVolUpKeys:Array<FlxKey>   = [];
	private var previousVolDownKeys:Array<FlxKey> = [];

	public var text:String = '';
	public var callback:String->Bool->Void = null;

	public var allowedSymbols = "1234567890qwertyuiopasdfghjklzxcvbnm`-=[];',./ ";

	public function new(defaultValue:String, width:Int, anchor:SICardinal, reference:SIGeneric) {
		super(width, SIGeneric.DEFAULT_COMPONENT_HEIGHT, anchor, reference);

		sprite         = new FlxSpriteGroup();
		textSpr        = new FormattedText(2, 0, 0, defaultValue, 12, SIGeneric.DEFAULT_TEXT_COLOUR);
		textSpr.y      = (height - textSpr.height) / 2;
		text           = defaultValue;
	}

	override public function redraw() {
		var BGSpr:FlxSprite = new FlxSprite(0,0);
		BGData = Type.createInstance(style, [width, height, false]);
		BGData.createSquare([], 0, 0, width, height, this, true, false);
		BGSpr.loadGraphic(BGData);
		BGSpr.antialiasing = false;
		textSpr.text = text;

		super.redraw();
		sprite.add(BGSpr);
		sprite.add(textSpr);
		changeText(text, false);
	}

	public function changeText(to:String, useCallback:Bool, finishCallback:Bool = false) {
		var prevText = text;
		text         = to;
		textSpr.text = '$to${editing ? "_" : ""}';
		textSpr.x    = sprite.x + 6;
		textSpr.y    = (height - textSpr.height) / 2;
		textSpr.y   += sprite.y;

		if (textSpr.width > width) {
			changeText(prevText, false);
			return;
		}

		if (useCallback && callback != null)
			callback(text, finishCallback);
	}

	public function keyHit(ev:KeyboardEvent) {
		var keyStr = CoolUtil.keyCodeToString(ev.keyCode, true).toLowerCase();

		if (ev.keyCode == FlxKey.ENTER)
			offClick();

		if (ev.keyCode == FlxKey.BACKSPACE) 
			changeText(text.substring(0, text.length - 1), true);

		if (allowedSymbols.contains(keyStr))
			changeText(text + keyStr, true);
	}

	override public function onClick(mouseX:Float, mouseY:Float) {
		if (!isMouseOver(mouseX, mouseY))
			return false;

		SIMasterContainer.lastComponent = this;

		if (editing)
			return true;

		if (!SIMasterContainer.inputGrabbed) {
			previousMuteKeys    = FlxG.sound.muteKeys;
			previousVolUpKeys   = FlxG.sound.volumeUpKeys;
			previousVolDownKeys = FlxG.sound.volumeDownKeys;
			FlxG.sound.muteKeys = FlxG.sound.volumeUpKeys = FlxG.sound.volumeDownKeys = [];
		}

		SIMasterContainer.inputGrabbed = editing = true;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		changeText(text, false);
		return true;
	}

	override public function offClick() {
		if (!editing)
			return;

		editing = false;
		SIMasterContainer.inputGrabbed = false;
		FlxG.sound.muteKeys       = previousMuteKeys;
		FlxG.sound.volumeUpKeys   = previousVolUpKeys;
		FlxG.sound.volumeDownKeys = previousVolDownKeys;

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		changeText(text, true, true);
	}
}
