package sail.presets;

import openfl.geom.Rectangle;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;

class SIColourBox extends SIGeneric {
	private var nData:SIStyleGeneric;

	public var colour:Int;

	public function new(RGB:Int, anchor:SICardinal, reference:SIGeneric) {
		sprite = new FlxSpriteGroup();
		colour = RGB;

		super(SIGeneric.DEFAULT_COMPONENT_HEIGHT, SIGeneric.DEFAULT_COMPONENT_HEIGHT, anchor, reference);
	}

	override public function redraw() {
		var nSpr = new FlxSprite(0, 0);
		nData = Type.createInstance(style, [width, height, true]);
		nSpr.loadGraphic(nData);
		nSpr.antialiasing = false;
		setColour(colour);

		super.redraw();
		sprite.add(nSpr);
	}

	public function setColour(RGB:Int) {
		colour = RGB;

		var localRect = new Rectangle(0, 0, width, height);
		nData.fillRect(localRect, RGB);
		nData.createSquare([], 0, 0, width, height, this, false, true);
	}

	override public function hover(mouseX:Float, mouseY:Float) {
		return false;
	}

	override public function onClick(mouseX:Float, mouseY:Float) {
		return false;
	}
}
