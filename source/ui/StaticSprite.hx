package ui;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;

class StaticSprite extends FlxSprite {
    public function new(?x:Float = 0, ?y:Float = 0 ){
        super(x,y,null);
        active = false;
    }
    override public function update(elasped:Float){}
    
    override public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, 
										 frameHeight = 0, unique = false, ?key:String):StaticSprite {
        super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
        return this;
    }
    override public function makeGraphic(Width:Int, Height:Int, Color:Int = 0xFFFFFFFF, 
										 Unique:Bool = false, ?Key:String):StaticSprite {
        super.makeGraphic(Width, Height, Color, Unique, Key);
        return this;
    }
}
