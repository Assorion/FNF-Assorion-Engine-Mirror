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
    public final GRID_COLOURS:Array<Array<Array<Int>>> = [
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
				var grCol = GRID_COLOURS[j % division][(i + colOffset) % 2];

				emptySprite.fillRect(new Rectangle(i * cWidth, j * cHeight, cWidth, cHeight), FlxColor.fromRGB(grCol[0], grCol[1], grCol[2]));
				colOffset++;
			}

		for(i in 1...Math.floor(columns / PlayState.KEY_COUNT))
			emptySprite.fillRect(new Rectangle((cWidth * PlayState.KEY_COUNT * i) - 2, 0, 4, cHeight * rows), FlxColor.BLACK);

		super(0,0);
		loadGraphic(emptySprite);
	}
}

class ChartingState extends EventState {
	private static inline final NOTE_SELECT_COLOUR:Int = 0xFFAAAAAA;
	private static inline final GRID_SIZE:Int = 40;

	private var vocals:FlxSound;
	private var songData:SongData;
	
	private var gridGroup:FlxSpriteGroup;
	private var noteGroup:FlxSpriteGroup;
	private var grid:StaticSprite;
	private var highlightBox:StaticSprite;

	var stepTime:Float = 0;
	var curSection:Int = 0;
	var timingLine:StaticSprite;
	var gridSelectX:Int;
	var gridSelectY:Float;

	override function create(){
		super.create();

		songData = PlayState.songData;
		Song.stepHooks.push(stepHit);

		vocals = new FlxSound();
		if (songData.hasVoices)
			vocals.loadEmbedded(Paths.playableSong(songData.name, true));

		vocals.play();
		vocals.pause();
		FlxG.mouse.visible = true;
		FlxG.sound.list.add(vocals);
		FlxG.sound.music.play(); // Playing and immidietly pausing is required to handle some timing weirdness.
		FlxG.sound.music.pause();
		FlxG.sound.music.time = vocals.time = 0;

		FlxG.stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseScroll);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);

		var bg:StaticSprite = new StaticSprite().loadGraphic(Paths.lImage('ui/defaultMenuBackground'));
		bg.setGraphicSize(1280, 720);
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = FlxColor.fromRGB(20, 45, 55);
		add(bg);

		gridGroup = new FlxSpriteGroup(15, 70);
		noteGroup = new FlxSpriteGroup(15, 70);
		add(gridGroup);
		add(noteGroup);

		highlightBox = new StaticSprite(0, 0).makeGraphic(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);
		highlightBox.alpha = 0.7;
		
		reloadGrid();
		reloadNotes();
	}

	override function update(elapsed:Float){
		Song.update(FlxG.sound.music.time);
		super.update(elapsed);

		if (FlxG.sound.music.playing)
			stepTime += elapsed * 1000 * Song.division;

		var oldSection = curSection;

		timingLine.y = ((stepTime % 16) * 0.0625 * grid.height) + gridGroup.y;
		curSection = Math.floor(stepTime * 0.0625);

		if (oldSection != curSection)
			reloadNotes();

		for(i in 0...noteGroup.length)
			noteGroup.members[i].alpha = timingLine.y >= noteGroup.members[i].y ? 0.6 : 1;
	}

	public function stepHit()
	if (FlxG.sound.music.playing)
		stepTime = (Song.millisecond * Song.division * 0.25) + (stepTime * 0.75);

	public function reloadGrid() {
		gridGroup.clear();

		grid = new ChartGrid(40, 40, PlayState.KEY_COUNT * songData.characterCharts, 16, 4);
		timingLine = new StaticSprite(0, 0).makeGraphic(Math.round(grid.width), 4, 0xFFFFFFFF);

		gridGroup.add(grid);
		gridGroup.add(timingLine);
		gridGroup.add(highlightBox);
	}

	public function reloadNotes() {
		noteGroup.clear();

		if (songData.sections[curSection] == null)
			songData.sections[curSection] = {
				cameraFacing: 0,
				notes: []
			};

		for(noteData in songData.sections[curSection].notes){
			var newNote = new Note(noteData.strumTime, noteData.column, noteData.type, false, false);
			newNote.player = noteData.player;
			newNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
			newNote.updateHitbox();
			newNote.x = (noteData.column + (noteData.player * PlayState.KEY_COUNT)) * GRID_SIZE;
			newNote.y = noteData.strumTime * GRID_SIZE;

			for(i in 1...noteData.length + 1){
				var susNote = new Note(noteData.strumTime + i, noteData.column, noteData.type, true, i == noteData.length);
				susNote.player = noteData.player;
				susNote.setGraphicSize(Math.floor(GRID_SIZE * 0.4), GRID_SIZE);
				susNote.updateHitbox();
				susNote.x = newNote.x + (GRID_SIZE * 0.3);
				susNote.y = susNote.strumTime * GRID_SIZE;
				susNote.flipY = false;
				
				noteGroup.add(susNote);
			}

			noteGroup.add(newNote);
		}
	}

	public function mouseMove(ev:MouseEvent) {
		gridSelectX = CoolUtil.intBoundTo(Math.floor((FlxG.mouse.x - gridGroup.x) / GRID_SIZE), 0, (songData.characterCharts * PlayState.KEY_COUNT) - 1);
		gridSelectY = CoolUtil.boundTo(Math.floor((FlxG.mouse.y - gridGroup.y) / GRID_SIZE), 0, 15);
		highlightBox.x = (gridSelectX * GRID_SIZE) + gridGroup.x;
		highlightBox.y = (gridSelectY * GRID_SIZE) + gridGroup.y;
	}

	public function mouseScroll(ev:MouseEvent) {
		FlxG.sound.music.pause();
		FlxG.sound.music.time = Math.max((Song.currentStep - (ev.delta - 1)) * Song.stepCrochet, 0);
		Song.update(FlxG.sound.music.time);
		stepTime = Math.max(Song.millisecond * Song.division, 0);
	}

	public function mouseDown(ev:MouseEvent) {
		for(i in 0...songData.sections[curSection].notes.length){
			var tmpNote = songData.sections[curSection].notes[i];
			
			if (Math.floor(tmpNote.strumTime) == gridSelectY 
			 && tmpNote.column == gridSelectX % PlayState.KEY_COUNT
			 && tmpNote.player == Math.floor(gridSelectX / PlayState.KEY_COUNT)){
				songData.sections[curSection].notes.splice(i, 1);
				reloadNotes();
				return;
			}
		}

		var createdNote:NoteData = {
			strumTime: gridSelectY,
			column: gridSelectX % PlayState.KEY_COUNT,
			length: 0,
			player: Math.floor(gridSelectX / PlayState.KEY_COUNT),
			type: 0
		};

		songData.sections[curSection].notes.push(createdNote);
		reloadNotes();
	}

	override function keyHit(ev:KeyboardEvent) {
		ev.keyCode.bindFunctions([
			[Binds.ui_back, function(){
				FlxG.mouse.visible = false;

				FlxG.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseScroll);
				FlxG.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				FlxG.stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);

				EventState.changeState(new PlayState());
			}],
			[Binds.ui_accept, function(){
				FlxG.sound.music.playing ? FlxG.sound.music.pause() : FlxG.sound.music.play();

				if (songData.hasVoices){
					vocals.playing ? vocals.pause() : vocals.play();
					vocals.time = FlxG.sound.music.time;
				}
			}],
			[Binds.ui_down, function(){
				FlxG.sound.music.pause();
				vocals.pause();

				stepTime = (curSection + 1) * 16;
				FlxG.sound.music.time = stepTime * Song.stepCrochet;
			}],
			[Binds.ui_up, function(){
				FlxG.sound.music.pause();
				vocals.pause();

				stepTime = Math.max((curSection - 1) * 16, 0);
				FlxG.sound.music.time = stepTime * Song.stepCrochet;
			}]
		]);
	}
}
