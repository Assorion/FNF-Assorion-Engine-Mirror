package sail.widgets;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;
import sail.style.SIStyleDropdown;

class SIDropButton extends SIButton {
	public var offClickCallback:Void->Void;

	override function offClick()
		if (offClickCallback != null)
			offClickCallback();
}

class SIDropdown extends SIContainer {
	private var bgSpr:SIStyle;
	private var optText:FormattedText;

	private var optionContainer:SIContainer;
	private var optionButtons:Array<SIButton> = [];
	private var dropButton:SIDropButton;
	private var down:Bool;

	public var options:Array<String> = [];
	public var curOption:String;
	public var callback:String->Void;

	public function rollDown() {
		if (down) {
			rollUp(curOption, false);
			return;
		}

		down = true;
		dropButton.changeLabel('/\\');
		parent.addChild(optionContainer);
		parent.redraw();
	}

	public function rollUp(opt:String, useCallback:Bool) {
		curOption = optText.text = opt;

		if (callback != null && useCallback) {
			callback(opt);
			return;
		}

		down = false;
		dropButton.changeLabel('\\/');
		parent.removeChild(optionContainer);
		parent.redraw();
	}

	public function new(?relativeSide:SISide = UNDER, ?defaultCorner:SIDiagonal = TOPLEFT, ?reference:SIGeneric
	, width:Int, defaultOpt:String, options:Array<String>, ?container:SIContainer = null) {
		super(relativeSide, defaultCorner, reference, width, null, container);
		
		this.options   = options;
		this.curOption = defaultOpt;

		optText = new FormattedText(0, 0, 0, defaultOpt, 14, SIGeneric.TEXT_COLOUR);
		optionContainer = new SIContainer(UNDER, this, w, h * (options.length + 1), null);
		optionContainer.ignoreSpacing = true;
		dropButton = new SIDropButton(null, TOPRIGHT, h, '\\/', this);
		dropButton.offClickCallback = function() {
			rollUp(curOption, false);
		};
		dropButton.callback = function() {
			rollDown();
		};

		var tmpButton:SIButton = null;
		for(i in 0...options.length) {
			tmpButton = new SIDropButton(UNDER, TOPLEFT, tmpButton, width, options[i], optionContainer);
			tmpButton.style = SIStyleDropdown;
			tmpButton.callback = function() {
				rollUp(options[i], true);
			};

			optionButtons[i] = tmpButton;
		}
	}

	override function redraw() {
		super.redraw();

		optText.text = curOption;
		optText.x = 6;
		optText.y = (h - optText.height) * 0.5;

		bgSpr = Type.createInstance(style, [w - h, h]);
		bgSpr.drawSquare(0, 0, w - h, h, false);

		sprGroup.add(new StaticSprite().loadGraphic(bgSpr.getData()));
		sprGroup.add(optText);
	}
}
