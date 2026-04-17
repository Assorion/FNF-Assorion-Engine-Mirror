package;

import flixel.FlxG;
import flixel.FlxState;

import backend.Song;
import ui.NewTransition;

typedef DelayedEvent = {
	var execTime:Float;
	var execFunc:Void->Void;
}

class EventState extends FlxState {
	public var events:Array<DelayedEvent> = [];

	private function keyHit(ev:KeyboardEvent){}
	private function keyRel(ev:KeyboardEvent){}

	override function create() {
		persistentUpdate = true;

		Song.clearHooks();
		openSubState(new NewTransition(null, false));
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP  , keyRel);
		super.create();
	}

	override function destroy(){
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP  , keyRel);
		super.destroy();
	}

	public static function changeState(target:FlxState) {
		NewTransition.activeTransition = new NewTransition(target, true);
		FlxG.state.persistentUpdate = false;
		FlxG.state.openSubState(NewTransition.activeTransition);
	}

	override function update(elapsed:Float) {
		var i = -1;
		while(++i < events.length) {
			events[i].execTime -= elapsed;

			if (events[i].execTime <= 0){
				events[i].execFunc();
				events.splice(i--, 1);
			}
		}

		super.update(elapsed);
	}

	public inline function postEvent(forward:Float, func:Void->Void)
		events.push({
			execTime: forward,
			execFunc: func
		});

	public inline function executeAllEvents()
		for(i in 0...events.length)
			events[i].execFunc();
}
