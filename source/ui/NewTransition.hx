package ui;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;

#if !debug @:noDebug #end
class NewTransition extends FlxSubState {
	public	static var activeTransition:NewTransition = null;
	public	static var skippedLast:Bool = true;
	private static var existingGraphic:FlxGraphic;

	public var whiteSprite:FlxSprite;
	public var transitionIn:Bool;
	public var pendingState:FlxState;

	public static function initialise(){
		var tempSprite:FlxSprite = new StaticSprite(0,0).makeGraphic(1280, 720, 0xFFFFFFFF);
		tempSprite.graphic.persist = true;
		tempSprite.graphic.destroyOnNoUse = false;

		existingGraphic = tempSprite.graphic;
	}

	public function new(pendingState:FlxState, transIn:Bool){
		super();

		transitionIn = transIn;
		activeTransition = transitionIn ? this : null;
		this.pendingState = pendingState;

		var mainCamera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		var z:Float = 1 / mainCamera.zoom;

		whiteSprite = new StaticSprite(0,0).loadGraphic(existingGraphic);
		whiteSprite.alpha = transitionIn ? 0 : 1;
		whiteSprite.scale.set(z, z);
		whiteSprite.scrollFactor.set();
		whiteSprite.camera = mainCamera;
		add(whiteSprite);

		if(skippedLast){
			skippedLast = false;
			whiteSprite.alpha = 0;
		}
	}

	public function inComplete(){
		close();
		
		activeTransition = null;
		FlxG.switchState(pendingState);
	}

	public function outComplete()
		close();

	public static function skip():Bool {
		if(activeTransition == null) 
			return false;

		skippedLast = true;
		activeTransition.inComplete();
		return true;
	}

	override function update(elapsed:Float){
		whiteSprite.alpha += elapsed * (transitionIn ? 4 : -2);

		if(whiteSprite.alpha == (transitionIn ? 1 : 0)) 
			transitionIn ? inComplete() : outComplete();
	}

}
