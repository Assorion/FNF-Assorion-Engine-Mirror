package sail;

import flixel.group.FlxSpriteGroup;

import sail.style.SIStyleGeneric;

// TODO: check haxe 3.4.7 compatibility
enum SIDiagonal {
	TOPLEFT;
	TOPRIGHT;
	BOTTOMLEFT;
	BOTTOMRIGHT;
}

enum SICardinal {
	TOP;
	LEFT;
	BOTTOM;
	RIGHT;
}

class SIGeneric {
	public static inline final DEFAULT_COMPONENT_HEIGHT:Int = 25;
	public static inline final DEFAULT_TEXT_COLOUR:Int = 0xFFFFFFFF;
	public static inline final DEFAULT_HOVER_COLOUR:Int = 0xFFBBBBCC;

	private var parent:SIContainer;
	private var x:Float; // Refrain from changing these manually
	private var y:Float;

	public var style:Class<SIStyleGeneric>;
	public var reference:SIGeneric;
	public var anchor:SICardinal;
	public var sprite:FlxSpriteGroup;
	public var width:Int;
	public var height:Int;

	public function new(width:Int, height:Int, anchor:SICardinal, reference:SIGeneric) {
		this.width     = width;
		this.height    = height;
		this.anchor    = anchor;
		this.reference = reference;
	}

	private inline function isMouseOver(mouseX:Float, mouseY:Float):Bool
		return mouseX >= x && mouseY >= y && mouseX < x + width && mouseY < y + height;

	public function redraw():Void {
		x = findReferenceX();
		y = findReferenceY();
		sprite.x = x;
		sprite.y = y;

		sprite.clear();
		sprite.color = 0xFFFFFFFF;
		parent.sprite.add(sprite);
	}

	public function offClick() {}

	public function onClickRelease() {}

	public function onClick(mouseX:Float, mouseY:Float):Bool {
		SIMasterContainer.lastComponent = this;
		return isMouseOver(mouseX, mouseY);
	}

	public function hover(mouseX:Float, mouseY:Float):Bool {
		var mouseOver = isMouseOver(mouseX, mouseY);
		sprite.color = mouseOver ? DEFAULT_HOVER_COLOUR : 0xFFFFFFFF; 
		return mouseOver;
	}

	/***************************************/

	public function findReferenceX():Float {
		// TODO: Add spacing
		if (reference == null)
			switch(parent.corner) {
			case TOPLEFT, BOTTOMLEFT:
				return parent.spacing;
			case TOPRIGHT, BOTTOMRIGHT:
				return (parent.width - parent.spacing) - width;
			}

		switch(anchor) {
		case TOP:
			return reference.x;
		case LEFT:
			return (reference.x - width) - parent.spacing;
		case BOTTOM:
			return reference.x;
		case RIGHT:
			return reference.x + reference.width + parent.spacing;
		}
	}

	public function findReferenceY():Float {
		if (reference == null)
			switch(parent.corner) {
			case TOPLEFT, TOPRIGHT:
				return parent.spacing;
			case BOTTOMLEFT, BOTTOMRIGHT:
				return (parent.height - parent.spacing) - height;
			}

		switch(anchor) {
		case TOP:
			return (reference.y - height) - parent.spacing;
		case LEFT:
			return reference.y;
		case BOTTOM:
			return reference.y + reference.height + parent.spacing;
		case RIGHT:
			return reference.y;
		}
	}
}
