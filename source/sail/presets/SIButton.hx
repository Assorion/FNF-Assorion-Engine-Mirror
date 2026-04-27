package sail.presets;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;

class SIButton extends SIGeneric {
	private var BGData:SIStyleGeneric;
	private var textSpr:FormattedText;
	
	public var callback:Void->Void = null;
	public var offClickCallback:Void->Void = null;

	public function new(label:String, width:Int, anchor:SICardinal, reference:SIGeneric) {
		super(width, SIGeneric.DEFAULT_COMPONENT_HEIGHT, anchor, reference);

		sprite = new FlxSpriteGroup();
		textSpr = new FormattedText(0, 0, 0, label, 12, SIGeneric.DEFAULT_TEXT_COLOUR);
	}

	override public function redraw() {
		BGData = Type.createInstance(style, [width, height, true]);
		var BGSpr = new FlxSprite(0, 0).loadGraphic(BGData);
		BGSpr.antialiasing = false;
		BGData.createSquare([], 0, 0, width, height, this, true, true);

		super.redraw();
		sprite.add(BGSpr);
		sprite.add(textSpr);
		changeLabel(textSpr.text);
	}

	public function changeLabel(newLabel:String) {
		textSpr.text = newLabel;
		textSpr.x = (width - textSpr.width) / 2;
		textSpr.y = (height - textSpr.height) / 2;
		textSpr.x += sprite.x;
		textSpr.y += sprite.y;
	}

	override public function onClick(mouseX:Float, mouseY:Float):Bool {
		if (!isMouseOver(mouseX, mouseY))
			return false;

		SIMasterContainer.lastComponent = this;
		BGData.createSquare([], 0, 0, width, height, this, false, false);
		return true;
	}

	override public function onClickRelease() {
		if (callback != null)
			callback();

		BGData.createSquare([], 0, 0, width, height, this, false, true);
	}

	override public function offClick()
		if (offClickCallback != null)
			offClickCallback();
}
