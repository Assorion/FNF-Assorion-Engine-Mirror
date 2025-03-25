package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.ui.FlxUIState;

import backend.Song;
import ui.NewTransition;

typedef DelayedEvent = {
	var endTime:Float;
	var exeFunc:Void->Void;
}

#if !debug @:noDebug #end
class EventState extends FlxUIState {
	public var tabOutTimeStamp:Float = 0;
	public var events:Array<DelayedEvent> = [];

	public function keyHit(ev:KeyboardEvent){}
	public function keyRel(ev:KeyboardEvent){}

	override function create() {
		openSubState(new NewTransition(null, false));
		Song.clearHooks();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP  , keyRel);

		persistentUpdate = true;

		super.create();
	}

	override function destroy(){
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP  , keyRel);

		super.destroy();
	}

	public static function changeState(target:FlxState) {
		NewTransition.activeTransition = new NewTransition(target, true);

		FlxG.state.openSubState(NewTransition.activeTransition);
		FlxG.state.persistentUpdate = false;
	}

	override function update(elapsed:Float) {
		var i = -1;
		var cTime = CoolUtil.getCurrentTime();
		while(++i < events.length)
			if(cTime >= events[i].endTime){
				events[i].exeFunc();
				events.splice(i--, 1);
			}

		super.update(elapsed);
	}

	public function postEvent(forward:Float, func:Void->Void)
		events.push({
			endTime: CoolUtil.getCurrentTime() + forward,
			exeFunc: func
		});

	public function executeAllEvents()
		for(i in 0...events.length)
			events[i].exeFunc();

	override function onFocusLost(){
		tabOutTimeStamp = CoolUtil.getCurrentTime();	
		super.onFocusLost();
	}

	override function onFocus(){
		for(ev in events)
			ev.endTime += CoolUtil.getCurrentTime() - tabOutTimeStamp;

		super.onFocus();
	}
}
