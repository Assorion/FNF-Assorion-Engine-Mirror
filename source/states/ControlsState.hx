package states;

import flixel.util.FlxColor;

import ui.Alphabet;
import ui.MenuTemplate;
import ui.NewTransition;

#if !debug @:noDebug #end
class ControlsState extends MenuTemplate {
	private var rebinding:Bool = false;
	private var controlList:Array<String> = [
		'NOTE_LEFT',
		'NOTE_DOWN',
		'NOTE_UP',
		'NOTE_RIGHT',
		'',
		'UI_LEFT',
		'UI_DOWN',
		'UI_UP',
		'UI_RIGHT',
		'',
		'UI_ACCEPT',
		'UI_BACK'
	];

	override function create() {
		addBG(FlxColor.fromRGB(0,255,110));
		columns = 3;

		super.create();
		createNewList();
	}

	public function createNewList(){
		for(object in arrGroup)
			remove(object.obj);
		
		arrGroup = [];

		for(i in 0...controlList.length){
			pushObject(new Alphabet(0, MenuTemplate.yOffset+20, controlList[i], true));

			var firstBind:String = '';
			var secondBind:String = '';

			if(controlList[i] != ''){
				var val:Dynamic = Reflect.field(Binds, controlList[i]);
				firstBind  = CoolUtil.getKeyNameFromString(val[0], false, false);
				secondBind = CoolUtil.getKeyNameFromString(val[1], false, false);
			}

			pushObject(new Alphabet(0, MenuTemplate.yOffset+20, firstBind , true));
			pushObject(new Alphabet(0, MenuTemplate.yOffset+20, secondBind, true));
		}

		changeSelection();
	}

	override public function exitFunction(){
		if(NewTransition.skip())
					return;

		EventState.changeState(new OptionsState());
	}

	// Skip blank space
	override public function changeSelection(to:Int = 0) {
		if(curSel + to >= 0 && controlList[curSel + to] == '')
			to *= 2;

		super.changeSelection(to);
	}

	override public function keyHit(ev:KeyboardEvent){
		if(rebinding){ 
				var original:Dynamic = Reflect.field(Binds, controlList[curSel]);
				original[curAlt] = ev.keyCode;
				Reflect.setField(Binds, '${controlList[curSel]}', original);

				rebinding = false;
				createNewList();
				return;
		}

		if(ev.keyCode.check(Binds.UI_ACCEPT)) {
			for(i in 0...arrGroup.length)
				if(Math.floor(i / columns) != curSel)
					arrGroup[i].targetA = 0;

			rebinding = true;
		}

		super.keyHit(ev);
	}
}
