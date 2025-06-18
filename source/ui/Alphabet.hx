package ui;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

using StringTools;

#if !debug @:noDebug #end
class Alphabet extends FlxSpriteGroup {
	public var text(default, set):String = "";
	public var isBold:Bool = false;

	private var letterOffset:Float = 0;

	public function new(x:Float, y:Float, str:String = "", ?bold:Bool = true) {
		super(x, y);

		isBold = bold;
		text = str.toLowerCase();
	}

	public function addText()
		for(character in text.split('')) {
			if (' -_'.contains(character) || !AlphaCharacter.completeList.contains(character)) {
				letterOffset += 40;
				continue;
			}

			var letter:AlphaCharacter = new AlphaCharacter(letterOffset, 0, character, isBold);
			add(letter);

			letterOffset += letter.width;
		}

	private function set_text(value:String){
		clear();

		text = value.toLowerCase();
		letterOffset = 0;
		addText();

		return value;
	}
}

class AlphaCharacter extends FlxSprite {
	public static inline var numbers:String		 = "1234567890";
	public static inline var symbols:String		 = "|~#$%()*+-<=>@[]^_.,'!?";
	public static inline var completeList:String = "abcdefghijklmnopqrstuvwxyz1234567890|~#$%()*+-<=>@[]^.,'!?";

	private var letter:String;
	private var replacementArray:Array<Array<Dynamic>> = [
		['.', "'", '?', '!'],
		['period', 'apostraphie', 'question mark', 'exclamation point'],
		[50, -5, 0, 0]
	];

	public function new(x:Float, y:Float, char:String, bolded:Bool) {
		super(x, y);

		var tex = Paths.lSparrow('ui/alphabet');
		frames = tex;
		letter = char;

		bolded ? createBold() : createLetter();
	}

	public function createBold() {
		animation.addByPrefix(letter, letter.toUpperCase() + " bold", 24);
		animation.play(letter);
		updateHitbox();
	}

	public function createLetter() {
		var suffix = numbers.contains(letter) ? '' : ' capital';

		if (symbols.contains(letter)) {
			replaceWithSymbol();
			return;
		}

		animation.addByPrefix(letter, '$letter$suffix', 24);
		animation.play(letter);
		updateHitbox();

		y = (110 - height);
	}

	public function replaceWithSymbol() {
		for(i in 0...replacementArray[0].length)
			if (letter == replacementArray[0][i]){
				letter = replacementArray[1][i];
				y     += replacementArray[2][i];
				break;
			}

		animation.play(letter);
		updateHitbox();
	}
}
