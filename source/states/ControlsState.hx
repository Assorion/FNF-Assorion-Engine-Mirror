package states;

import ui.Alphabet;
import ui.ListMenu;
import ui.NewTransition;

class ControlsState extends ListMenu {
	private var CONTROL_LIST:Array<Dynamic> = [
		['note left',  Binds.note_left],
		['note down',  Binds.note_down],
		['note up',    Binds.note_up],
		['note right', Binds.note_right],
		[''            , null],
		['ui left',    Binds.ui_left],
		['ui down',    Binds.ui_down],
		['ui up',      Binds.ui_up],
		['ui right',   Binds.ui_right],
		[''            , null],
		['select',     Binds.ui_accept],
		['back',       Binds.ui_back]
	];

	private var rebinding:Bool = false;
	private var curColumn:Int  = 0;
	private var secondColumn:Array<Alphabet> = [];
	private var thirdColumn:Array<Alphabet>  = [];

	override function create() {
		addBG(0,255,110);
		super.create();
		refreshControlsList();
	}

	public function refreshControlsList(){
		clearItems();
		secondColumn = [];
		thirdColumn  = [];

		for(i in 0...CONTROL_LIST.length){
			var firstBind:String  = '';
			var secondBind:String = '';

			if (CONTROL_LIST[i][0] != ''){
				firstBind  = CoolUtil.keyCodeToString(CONTROL_LIST[i][1][0], false);
				secondBind = CoolUtil.keyCodeToString(CONTROL_LIST[i][1][1], false);
			}

			pushMenuItem(new Alphabet(0, ListMenu.Y_OFFSET + 20, CONTROL_LIST[i][0], true), null);

			secondColumn[i] = new Alphabet(0, ListMenu.Y_OFFSET + 20, firstBind, true);
			thirdColumn[i]  = new Alphabet(0, ListMenu.Y_OFFSET + 20, secondBind, true);
			listGroup.add(secondColumn[i]);
			listGroup.add(thirdColumn[i]);
		}

		changeSelection(0);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		for(i in 0...secondColumn.length) {
			var sItem = secondColumn[i];
			var tItem = thirdColumn[i];
			sItem.x = 800  - (sItem.width * 0.5);
			tItem.x = 1100 - (tItem.width * 0.5);
			sItem.y = tItem.y = listItems[i].spr.y;
			sItem.alpha = tItem.alpha = Math.min(listItems[i].spr.alpha, ListMenu.DESELECTED_ALPHA);

			if (i == curSel)
				(curColumn == 0 ? sItem : tItem).alpha = 1;
		}
	}

	override public function exitFunction() 
		if (!NewTransition.skip())
			EventState.changeState(new OptionsState());

	override public function changeSelection(to:Int = 0) {
		if (curSel + to >= 0 && curSel + to < CONTROL_LIST.length - 1 && CONTROL_LIST[curSel + to][0] == '')
			to *= 2;

		super.changeSelection(to);
	}

	override public function altChange(to:Int = 0) {
		curColumn = CoolUtil.intCircularModulo(curColumn + to, 2);
		changeSelection(0);
	}

	override public function keyHit(ev:KeyboardEvent){
		if (rebinding){ 
			CONTROL_LIST[curSel][1][curColumn] = ev.keyCode;
			rebinding = false;

			refreshControlsList();
			return;
		}

		super.keyHit(ev);

		if (!ev.keyCode.check(Binds.ui_accept)) 
			return;

		rebinding = true;

		for(i in 0...listItems.length)
			listItems[i].targetA = i != curSel ? 0 : 1;
	}
}
