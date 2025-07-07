package states;

import ui.Alphabet;
import ui.MenuTemplate;
import ui.NewTransition;

class ControlsState extends MenuTemplate {
	private var CONTROL_LIST:Array<Dynamic> = [
		['note left',  Binds.note_left],
		['note down',  Binds.note_down],
		['note up',    Binds.note_up],
		['note right', Binds.note_right],
		['', null],
		['ui left',    Binds.ui_left],
		['ui down',    Binds.ui_down],
		['ui up',      Binds.ui_up],
		['ui right',   Binds.ui_right],
		['', null],
		['select',     Binds.ui_accept],
		['back',       Binds.ui_back]
	];

	private var rebinding:Bool = false;

	override function create() {
		addBG(0,255,110);
		columns = 3;

		super.create();
		createNewList();
	}

	public function createNewList(){
		for(object in arrGroup)
			remove(object.obj);
		
		arrGroup = [];

		for(i in 0...CONTROL_LIST.length){
			var firstBind:String  = '';
			var secondBind:String = '';

			if (CONTROL_LIST[i][0] != ''){
				firstBind  = CoolUtil.keyCodeToString(CONTROL_LIST[i][1][0], false);
				secondBind = CoolUtil.keyCodeToString(CONTROL_LIST[i][1][1], false);
			}

			pushObject(new Alphabet(0, MenuTemplate.Y_OFFSET + 20, CONTROL_LIST[i][0], true));
			pushObject(new Alphabet(0, MenuTemplate.Y_OFFSET + 20, firstBind, true));
			pushObject(new Alphabet(0, MenuTemplate.Y_OFFSET + 20, secondBind, true));
		}

		changeSelection();
	}

	override public function exitFunction()
	if (!NewTransition.skip())
		EventState.changeState(new OptionsState());
	

	override public function changeSelection(to:Int = 0) {
		// Skip blank space
		if (curSel + to >= 0 && CONTROL_LIST[curSel + to][0] == '')
			to *= 2;

		super.changeSelection(to);
	}

	override public function keyHit(ev:KeyboardEvent){
		if (rebinding){ 
			CONTROL_LIST[curSel][1][curAlt] = ev.keyCode;
			rebinding = false;

			createNewList();
			return;
		}

		super.keyHit(ev);

		if (!ev.keyCode.check(Binds.ui_accept)) 
			return;

		rebinding = true;
		for(i in 0...arrGroup.length)
			if (Math.floor(i / columns) != curSel)
				arrGroup[i].targetA = 0;
	}
}
