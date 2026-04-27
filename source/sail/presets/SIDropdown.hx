package sail.presets;

import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;
import sail.presets.SIButton;
import sail.presets.SIInput;
import sail.presets.SIHoverableContainer;

class SIDropdown extends SIHoverableContainer {
	private var buttons:Array<SIButton> = [];
	private var mainButton:SIButton;
	private var originalHeight:Int;
	private var open:Bool = false;

	public var options:Array<String> = [];
	public var curOpt:Int = 0;

	public var callback:String->Int->Void = null;

	public function new(options:Array<String>, defaultOpt:String, width:Int, anchor:SICardinal, reference:SIGeneric, style:Class<SIStyleGeneric>) {
		super(width, SIGeneric.DEFAULT_COMPONENT_HEIGHT, anchor, reference);

		this.options = options;
		this.style = style;
		originalHeight = height;
		corner = TOPLEFT;
		spacing = 0;

		mainButton = new SIButton(defaultOpt, width - height, RIGHT, null);
		mainButton.callback = function() {
			showOptions();
		};
		mainButton.offClickCallback = function() {
			if (!buttons.contains(cast SIMasterContainer.lastComponent))
				closeOptions();
		};

		// If the character somehow isn't rendering for you: It's supposed to be a down arrow.
		var sideButton = new SIButton('↓', height, RIGHT, mainButton);
		sideButton.callback = mainButton.callback;
		sideButton.offClickCallback = mainButton.offClickCallback;

		addChild(mainButton);
		addChild(sideButton);
	}

	public function showOptions() {
		if (open) {
			closeOptions();
			return;
		}

		open = true;
		height = originalHeight;

		for(i in 0...options.length) {
			var newButton = new SIButton(options[i], width, BOTTOM, i != 0 ? buttons[buttons.length - 1] : mainButton);
			height += newButton.height;
			newButton.callback = function() {
				SIMasterContainer.lastComponent = null;
				curOpt = i;

				mainButton.changeLabel(options[curOpt]);
				closeOptions();

				if (callback != null)
					callback(options[curOpt], curOpt);
			};
			
			buttons.push(newButton);
			addChild(newButton);

		}

		redraw();
		parent.sprite.remove(sprite, true);
		parent.sprite.add(sprite);
	}

	public function closeOptions() {
		if (!open)
			return;

		open = false;
		height = originalHeight;
		
		while(buttons.length > 0)
			removeChild(buttons.pop());

		parent.redraw();
	}
}
