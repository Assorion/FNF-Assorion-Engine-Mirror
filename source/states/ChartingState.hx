package states;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import openfl.geom.Rectangle;
import openfl.events.MouseEvent;
import openfl.display.BitmapData;

import backend.Song;
import gameplay.Note;

class ChartGrid extends StaticSprite {
    public final gridColours:Array<Array<Array<Int>>> = [
        [[255, 200, 200], [255, 215, 215]], // Red
        [[200, 200, 255], [215, 215, 255]], // Blue
        [[240, 240, 200], [240, 240, 215]], // Yellow / White
        [[200, 255, 200], [215, 255, 215]], // Green
    ];

	public function new(cWidth:Int, cHeight:Int, columns:Int, rows:Int, division:Int = 4) {
		var emptySprite:BitmapData = new BitmapData(cWidth * columns, cHeight * rows, true);
		var colOffset:Int = 0;

		for(i in 0...columns)
			for(j in 0...rows){
				var grCol = CoolUtil.cfArray(gridColours[j % division][(i + colOffset) % 2]);

				emptySprite.fillRect(new Rectangle(i * cWidth, j * cHeight, cWidth, cHeight), grCol);
				colOffset++;
			}

		for(i in 1...Math.floor(columns / PlayState.KEY_COUNT))
			emptySprite.fillRect(new Rectangle((cWidth * PlayState.KEY_COUNT * i) - 2, 0, 4, cHeight * rows), FlxColor.BLACK);

		super(0,0);
		loadGraphic(emptySprite);
	}
}

class ChartingState extends EventState {
	public var songData:SongData;
	public var noteList:Array<Array<Note>> = [];
	public var gridSize:Int = 40;

	public var vocals:FlxSound;

	var gridGroup:FlxSpriteGroup;
	var noteLine:StaticSprite;
	var grid:StaticSprite;

	var stepTime:Float = 0;
	var curSection:Int = -1;

	override function create(){
		super.create();

		songData = PlayState.songData;
		Song.stepHooks.push(stepHit);

		vocals = new FlxSound();
		if (songData.needsVoices)
			vocals.loadEmbedded(Paths.playableSong(songData.name, true));

		FlxG.mouse.visible = true;
		FlxG.sound.list.add(vocals);
		FlxG.sound.music.pause();
		FlxG.sound.music.time = 0;

		FlxG.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseScroll);
		FlxG.stage.addEventListener(MouseEvent.RIGHT_CLICK, mouseRightClick);

		for(section in 0...songData.notes.length)
			for(fNote in songData.notes[section].sectionNotes){
				if(noteList[section] == null)
					noteList[section] = [];

				var noteData :Int = Std.int(fNote[1]);
				var susLength:Int = Std.int(fNote[2]);
				var player	 :Int = CoolUtil.intBoundTo(Std.int(fNote[3]), 0, songData.playLength - 1);
				var ntype	 :Int = Std.int(fNote[4]);

				var newNote = new Note(fNote[0], noteData, ntype, false, false);
				newNote.player = player;
				noteList[section].push(newNote);

				/*if(susLength > 1)
					for(i in 0...susLength+1){
						var susNote = new Note(time + i + 0.5, noteData, ntype, true, i == susLength);
						susNote.scrollFactor.set();
						susNote.player = player;
						chartNotes.push(susNote);
					}*/
			}

		//noteList.sort((A,B) -> Std.int(A.strumTime - B.strumTime));

		var bg:StaticSprite = new StaticSprite().loadGraphic(Paths.lImage('ui/defaultMenuBackground'));
		bg.setGraphicSize(1280, 720);
		bg.updateHitbox();
		bg.screenCenter();
		bg.color  = FlxColor.fromRGB(20, 45, 55);
		add(bg);

		gridGroup = new FlxSpriteGroup(10, 100);
		gridGroup.y = 50;
		add(gridGroup);

		grid     = new ChartGrid(40, 40, PlayState.KEY_COUNT * songData.playLength, 16, 4);
		noteLine = new StaticSprite(0, 0).makeGraphic(Math.round(grid.width), 4, 0xFFFFFFFF);

		gridGroup.add(grid);
		gridGroup.add(noteLine);
	}

	override function destroy(){
		super.destroy();

		FlxG.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		FlxG.stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		FlxG.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseScroll);
		FlxG.stage.removeEventListener(MouseEvent.RIGHT_CLICK, mouseRightClick);
	}

	override function update(elapsed:Float){
		Song.update(FlxG.sound.music.time);
		super.update(elapsed);

		if(FlxG.sound.music.playing)
			stepTime += elapsed * 1000 * Song.division;

		var oldCurSec:Int = curSection;

		noteLine.y = ((stepTime % 16) * 0.0625 * grid.height) + gridGroup.y;
		curSection = Math.floor(stepTime * 0.0625);

		//if(curSection != oldCurSec)
		//	sectionChange(Math.oldCurSec));
	}

	public function sectionChange(oldSection:Int){
		for(i in 0...noteList[oldSection].length)
			if(noteList[oldSection][i] != null)
				gridGroup.remove(noteList[oldSection][i]);

		for(i in 0...noteList[curSection].length)
			gridGroup.add(noteList[curSection][i]);
	}

	public function stepHit() 
		if(FlxG.sound.music.playing)
			stepTime = (Song.millisecond * Song.division * 0.25) + (stepTime * 0.75);

	public function mouseScroll(ev:MouseEvent){
		FlxG.sound.music.pause();
		FlxG.sound.music.time = Math.max((Song.currentStep - (ev.delta - 1)) * Song.stepCrochet, 0);
		Song.update(FlxG.sound.music.time);
		stepTime = Math.max(Song.millisecond * Song.division, 0);
	}
	
	public function mouseMove(ev:MouseEvent){}
	public function mouseDown(ev:MouseEvent){}
	public function mouseRightClick(ev:MouseEvent){}

	override function keyHit(ev:KeyboardEvent){
		ev.keyCode.bindFunctions([
			[Binds.ui_back, function(){
				FlxG.mouse.visible = false;
				EventState.changeState(new PlayState());
			}],
			[Binds.ui_accept, function(){
				FlxG.sound.music.playing ? FlxG.sound.music.pause() : FlxG.sound.music.play();
				
				if(songData.needsVoices){
					vocals.playing ? vocals.pause() : vocals.play();
					vocals.time = FlxG.sound.music.time;
				}
			}]
		]);
	}
}
