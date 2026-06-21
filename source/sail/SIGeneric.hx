package sail;

import flixel.group.FlxSpriteGroup;

import sail.style.SIStyleGeneric;

enum SIDiagonal {
	TOPLEFT;
	TOPRIGHT;
	BOTTOMLEFT;
	BOTTOMRIGHT;
}

enum SISide {
	LEFT;
	UNDER;
	RIGHT;
	ONTOP;
}

class SIGeneric {
	public static inline final COMPONENT_HEIGHT:Int = 30;
	public static inline final TEXT_COLOUR:Int = 0xFFFFFFFF; // Thanks to Flixel weirdness, you probably won't be able to change this
	public static inline final HOVER_COLOUR:Int = 0xFFBBBBCC;

	private var master:SIContainer;
	private var parent:SIContainer;

	private var x:Float = 0;
	private var y:Float = 0;
	public var w:Int;
	public var h:Int;

	public var reference:SIGeneric;
	public var relativeSide:SISide;
	public var defaultCorner:SIDiagonal;
	public var sprGroup:FlxSpriteGroup;
	public var style:Class<SIStyle>;
	public var ignoreSpacing:Bool;

	public function new(?relativeSide:SISide = UNDER, ?defaultCorner:SIDiagonal = TOPLEFT, ?reference:SIGeneric
	, width:Int, ?height:Int = COMPONENT_HEIGHT, ?container:SIContainer = null) {
		this.relativeSide  = relativeSide;
		this.defaultCorner = defaultCorner;
		this.reference     = reference;
		w = width;
		h = height;

		sprGroup = new FlxSpriteGroup();

		if (container != null)
			container.addChild(this);
	}

	public function mouseOver(x:Float, y:Float, ?radius:Float = 0):Bool
		return x >= this.x - radius     && y >= this.y - radius
			&& x <  this.x + w + radius && y <  this.y + h + radius;

	public function redraw() {
		sprGroup.clear();
		sprGroup.color = 0xFFFFFFFF;
	}

	/**********************************/

	public function hover(mouseX:Float, mouseY:Float):Bool {
		var over = mouseOver(mouseX, mouseY);
		sprGroup.color = over ? HOVER_COLOUR : 0xFFFFFFFF; 
		return over;
	}

	public function onClick(mouseX:Float, mouseY:Float):Bool {
		if (mouseOver(mouseX, mouseY) && master != null) {
			master.activeComponent = this;
			return true;
		}

		return false;
	} 

	public function onClickRelease() 
		if (master != null) {
			master.activeComponent = null;
			master.changeLastComponent(this);
		}

	public function offClick() {} 
}
