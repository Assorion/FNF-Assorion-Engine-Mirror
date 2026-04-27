package sail.presets;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

import sail.SIGeneric;

class SILabel extends SIGeneric {
	private var textSpr:FormattedText;

	public function new(label:String, anchor:SICardinal, reference:SIGeneric) {
		sprite = new FlxSpriteGroup();
		textSpr = new FormattedText(0, 0, 0, label, 15, SIGeneric.DEFAULT_TEXT_COLOUR);

		super(0, 0, anchor, reference);
	}

	override public function redraw() {
		super.redraw();
		sprite.add(textSpr);
		changeLabel(textSpr.text);
	}

	public function changeLabel(newLabel:String) {
		textSpr.text = newLabel;
		textSpr.y    = (SIGeneric.DEFAULT_COMPONENT_HEIGHT - textSpr.height) / 2;
		textSpr.y   += sprite.y;
		textSpr.x    = sprite.x;
		width        = Math.floor(textSpr.width);
		height       = Math.floor(textSpr.height);
	}

	override public function hover(mouseX:Float, mouseY:Float):Bool 
		return false;
}
