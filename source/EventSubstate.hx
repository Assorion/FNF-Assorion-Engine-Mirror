package;

import flixel.FlxG;
import flixel.FlxSubState;

import EventState;

class EventSubstate extends FlxSubState {
	private var events:Array<DelayedEvent> = [];

	public function keyHit(ev:KeyboardEvent){}
	public function keyRel(ev:KeyboardEvent){}

	override function create() {
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP  , keyRel);
		super.create();
	}

	override function destroy() {
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHit);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP  , keyRel);
		super.destroy();
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

	private function postEvent(forward:Float, func:Void->Void)
		events.push({
			execTime: forward,
			execFunc: func
		});
}
