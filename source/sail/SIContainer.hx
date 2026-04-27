package sail;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;

// TODO: remove this!
import backend.CoolUtil;

class SIContainer extends SIGeneric {
	private var children:Array<SIGeneric> = [];

	public var spacing:Float = 0;
	// TODO: move corner into SI generic
	public var corner:SIDiagonal;

	public function new(width:Int, height:Int, anchor:SICardinal, reference:SIGeneric) {
		sprite = new FlxSpriteGroup();
		corner = TOPLEFT;

		super(width, height, anchor, reference);
	}

	public function addChild(child:SIGeneric) {
		child.parent = this;
		child.style  = style;

		if (children.indexOf(child) < 0)
			children.push(child);
	}

	public function removeChild(child:SIGeneric) {
		children.remove(child);
		redraw();
	}

	public function setChildren(newChildren:Array<SIGeneric>) {
		children = newChildren;
		for(i in 0...children.length)
			children[i].parent = this;

		redraw();
	}

	override public function redraw() {
		/*var r:Int = CoolUtil.randomRange(0, 255);
		var g:Int = CoolUtil.randomRange(0, 255);
		var b:Int = CoolUtil.randomRange(0, 255);

		var BG:FlxSprite = new FlxSprite(0, 0).makeGraphic(width, height, 0xFF000000 | (r << 16) | (g << 8) | b);*/
		super.redraw();
		//sprite.add(BG);

		for(i in 0...children.length) 
			children[i].redraw();
	}

	override public function hover(mouseX:Float, mouseY:Float):Bool {
		if (!isMouseOver(mouseX, mouseY))
			return false;

		var ret:Bool = false;

		for(i in 0...children.length)
			ret = children[i].hover(mouseX - x, mouseY - y) || ret;

		return ret;
	}

	override public function onClick(mouseX:Float, mouseY:Float):Bool {
		if (!isMouseOver(mouseX, mouseY))
			return false;

		for(i in 0...children.length) 
			if (children[i].onClick(mouseX - x, mouseY - y)) 
				return true;

		return false;
	}
}
