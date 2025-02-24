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
	private var events:Array<DelayedEvent> = [];

	override function create() {
		openSubState(new NewTransition(null, false));
		Song.clearHooks();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP  , keyRel);

		persistentUpdate = true;

		super.create();
	}

	public function keyHit(ev:KeyboardEvent){}
	public function keyRel(ev:KeyboardEvent){}

	override function destroy(){
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP  , keyRel);

		super.destroy();
	}

	private inline function postEvent(forward:Float, func:Void->Void)
		events.push({
			endTime: CoolUtil.getCurrentTime() + forward,
			exeFunc: func
		});

	override function update(elapsed:Float) {
		var i = -1;
		var cTime = CoolUtil.getCurrentTime();
		while(++i < events.length){
			if(cTime < events[i].endTime)
				continue;

			events[i].exeFunc();
			events.splice(i--, 1);
		}

		super.update(elapsed);
	}

	private inline function executeAllEvents()
		for(i in 0...events.length)
			events[i].exeFunc();

	public static function changeState(target:FlxState) {
		NewTransition.activeTransition = new NewTransition(target, true);

		FlxG.state.openSubState(NewTransition.activeTransition);
		FlxG.state.persistentUpdate = false;
	}
}
