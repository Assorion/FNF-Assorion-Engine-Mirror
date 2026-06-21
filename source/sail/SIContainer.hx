package sail;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class SIContainer extends SIGeneric {
	private var children:Array<SIGeneric> = [];
	public  var spacing:Float = 0;
	public  var redrawCallback:Void->Void;

	/* Only for master containers */
	private var lastComponent:SIGeneric;
	public  var activeComponent:SIGeneric;

	public function changeLastComponent(newComp:SIGeneric) {
		if (lastComponent != newComp && lastComponent != null)
			lastComponent.offClick();

		lastComponent = newComp;
	}

	public function addChild(newChild:SIGeneric) {
		newChild.master = master;
		newChild.parent = this;

		if (children.indexOf(newChild) < 0)
			children.push(newChild);
	}

	public function removeChild(remChild:SIGeneric) {
		while(children.indexOf(remChild) >= 0)
			children.remove(remChild);
	}

	public inline function declareMaster():FlxSpriteGroup {
		master = this;
		return sprGroup;
	}

	override public function redraw() {
		sprGroup.clear();
		sprGroup.color = 0xFFFFFFFF;
		sprGroup.x = x;
		sprGroup.y = y;

		if (redrawCallback != null)
			redrawCallback();
		
		for(i in 0...children.length) {
			var child = children[i];

			if (child.style == null)
				child.style = master.style;

			sprGroup.add(child.sprGroup);
			child.master = master;
			child.x = child.sprGroup.x = findChildX(child);
			child.y = child.sprGroup.y = findChildY(child);
			child.redraw();
		}

		hover(FlxG.mouse.x, FlxG.mouse.y);
	}

	/*******************************************/

	override public function hover(mouseX:Float, mouseY:Float):Bool {
		var ret:Bool = false;
		for(i in 0...children.length)
			ret = children[i].hover(mouseX, mouseY) || ret;

		return ret;
	}

	override public function onClick(mouseX:Float, mouseY:Float):Bool {
		for (i in 0...children.length)
			if (children[children.length - 1 - i].onClick(mouseX, mouseY))
				return true;

		changeLastComponent(null);
		return false;
	}

	override public function onClickRelease()
		if (activeComponent != null) {
			activeComponent.onClickRelease();
			activeComponent = null;
		}

	/*******************************************/

	public function findChildX(child:SIGeneric):Float {
		var ts:Float = child.ignoreSpacing ? 0 : spacing; 

		if (child.reference == null)
			switch(child.defaultCorner) {
			case TOPLEFT, BOTTOMLEFT:	
				return x + ts;
			case TOPRIGHT, BOTTOMRIGHT:
				return (x + w) - child.w - ts;
			}

		switch(child.relativeSide) {
		case LEFT:
			return child.reference.x - child.w - ts;
		case RIGHT:
			return child.reference.x + child.reference.w + ts;
		case ONTOP, UNDER:
			return child.reference.x;
		}
	}

	public function findChildY(child:SIGeneric):Float {
		var ts:Float = child.ignoreSpacing ? 0 : spacing;

		if (child.reference == null)
			switch(child.defaultCorner) {
			case TOPLEFT, TOPRIGHT:
				return y + ts;
			case BOTTOMLEFT, BOTTOMRIGHT:
				return (y + h) - child.h - ts;
			}

		switch(child.relativeSide) {
		case ONTOP:
			return child.reference.y - child.h - ts;
		case UNDER:
			return child.reference.y + child.reference.h + ts;
		case LEFT, RIGHT:
			return child.reference.y;
		}
	}
}
