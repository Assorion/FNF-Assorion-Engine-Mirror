package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import haxe.Json;

import backend.Song;
import backend.Chart;
import ui.CharacterIcon;
import gameplay.Note;
import gameplay.StageLogic;

import sail.*;
import sail.widgets.*;
import sail.style.SIStyleGeneric;
import sail.style.SIStyleContrast;

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
	private static inline final NOTE_SELECT_COLOUR:Int = 0xFF9999CC; // RGB: 153 153 204
	private static inline final GRID_SIZE:Int = 40;
	private final tabNames:Array<String> = ['Properties', 'Section', 'Players', 'Help'];

	private var mainUIBox:SITabbedContainer;
	private var sectionCameraStepper:SIStepper;
	private var sectionCopyStepper:SIStepper;
	private var showCopyPreview:Bool = false;
	private var inputGrabbed:Bool = false;

	private var grid:StaticSprite;
	private var gridGroup:FlxSpriteGroup;
	private var noteGroup:FlxSpriteGroup;
	private var highlightBox:StaticSprite;
	private var selectionBox:StaticSprite;

	private var warningText:FormattedText;
	private var sectionText:FormattedText;
	private var noteTypeText:FormattedText;
	private var snapText:FormattedText;
	private var textTween:FlxTween;

	public var vocals:FlxSound;
	public var curNoteType:Int;
	public var songData:ChartData;
	public var selectedNotes:Map<Int, Array<NoteData>> = new Map<Int, Array<NoteData>>();

	var stepTime:Float = 0;
	var timingLine:StaticSprite;
	var curSection:Int = 0;
	var gridSelectX:Int;
	var gridSelectY:Float;

	var snaps:Array<Float> = [1/2, 3/4, 1, 3/2, 2, 4]; // 0.5, 0.75, 1, 1.5, 2, 4
	var curZoom:Int = 2;

	private function autoSave(){
		saveSong(true);
		postEvent(120, autoSave);
	}

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
		FlxG.sound.muteKeys = [];
		FlxG.sound.list.add(vocals);
		FlxG.sound.music.play(); // Playing and immidietly pausing is required to handle some timing weirdness.
		FlxG.sound.music.pause();
		FlxG.sound.music.volume = 0.75;
		FlxG.sound.music.time = vocals.time = 0;

		FlxG.stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseScroll);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_MOVE,  mouseMove);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_DOWN,  mouseDown);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_UP,    mouseUp);
		FlxG.stage.addEventListener(MouseEvent.RIGHT_CLICK, mouseRight);
		FlxG.stage.addEventListener('input_grab',    uiInputGrab);
		FlxG.stage.addEventListener('input_release', uiInputRelease);

		var bg:StaticSprite = new StaticSprite().loadGraphic(Paths.image('ui/defaultMenuBackground'));
		bg.setGraphicSize(1280, 720);
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = FlxColor.fromRGB(20, 45, 55);
		add(bg);

		gridGroup = new FlxSpriteGroup(380, 70);
		noteGroup = new FlxSpriteGroup(380, 70);
		add(gridGroup);
		add(noteGroup);

		highlightBox = new StaticSprite(0, 0).makeGraphic(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);

		selectionBox = new StaticSprite(0, 0).makeGraphic(1, 1, NOTE_SELECT_COLOUR);
		selectionBox.alpha = 0;
		selectionBox.origin.set(0, 0);
		add(selectionBox);
		
		// UI Stuff
		mainUIBox = new SITabbedContainer(368, 630, 5, 35, tabNames, [propertiesUI(), sectionUI(), playersUI(), helpUI()]);
		mainUIBox.style = Settings.high_contrast ? SIStyleContrast : SIStyleGeneric;
		mainUIBox.declareMaster();
		mainUIBox.changeTab(0);

		sectionText  = new FormattedText(0, 0, 0, '', null, 16, 0xFFFFFFFF, LEFT);
		noteTypeText = new FormattedText(0, 0, 0, 'Note type: 0 (${Note.NOTE_TYPES[0].assets})', null, 16, 0xFFFFFFFF, LEFT);
		snapText     = new FormattedText(0, 0, 0, 'Snap: 1', null, 16, 0xFFFFFFFF, LEFT);
		warningText  = new FormattedText(0, 0, 0, '', null, 16, 0xFFFFFFFF, LEFT);
		sectionText.y  = FlxG.height - 20;
		noteTypeText.y = FlxG.height - 35;
		snapText.y     = FlxG.height - 50;
		warningText.y  = 0;
		add(sectionText);
		add(noteTypeText);
		add(snapText);
		add(warningText);
		add(mainUIBox.sprGroup);

		reloadGrid();
		reloadNotes();

		#if desktop
		postEvent(120, autoSave);
		#end
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
			noteGroup.members[i].alpha = stepTime % 16 >= cast(noteGroup.members[i], Note).strumTime ? 0.75 : 1;
	}

	function stepHit()
		if (FlxG.sound.music.playing)
			stepTime = (Song.millisecond * Song.division * 0.25) + (stepTime * 0.75);

	private inline function noteSelected(noteData:NoteData, sec:Int):Bool 
		return selectedNotes.exists(sec) && (selectedNotes.get(sec)).contains(noteData);

	private inline function sectionNullCheck(sec:Int):Bool {
		var section = songData.sections[sec];
		songData.sections[sec] = section ?? {
			cameraFacing: 0,
			notes: []
		};

		return section == null;
	}

	function reloadGrid() {
		gridGroup.clear();

		for(i in 0...songData.characterCharts){
			var tmpIcon = new CharacterIcon(songData.characters[i].name);
			tmpIcon.x = (GRID_SIZE * i * PlayState.KEY_COUNT) + GRID_SIZE;
			tmpIcon.y = gridGroup.y - 140;
			tmpIcon.alpha = songData.activePlayer == i ? 1 : 0.5;
			tmpIcon.scale.set(0.5, 0.5);

			tmpIcon.updateHitbox();
			gridGroup.add(tmpIcon);
		}

		grid = new ChartGrid(40, 40, PlayState.KEY_COUNT * songData.characterCharts, 16, 4);
		timingLine = new StaticSprite(0, 0).makeGraphic(Math.round(grid.width), 4, 0xFFFFFFFF);

		gridGroup.add(grid);
		gridGroup.add(timingLine);
		gridGroup.add(highlightBox);
	}

	function genNote(strumTime:Float, column:Int, type:Int, sustain:Bool, isEnd:Bool, player:Int):Note {
		var newNote = new Note(strumTime, column, type, sustain, isEnd);
		newNote.setGraphicSize(Math.floor(GRID_SIZE * (sustain ? 0.4 : 1)), GRID_SIZE);
		newNote.updateHitbox();
		newNote.player = player;
		newNote.flipY = false;
		newNote.x = (column + (player * PlayState.KEY_COUNT)) * GRID_SIZE;
		newNote.y = strumTime * GRID_SIZE;

		return newNote;
	}

	function reloadNotes() {
		sectionNullCheck(curSection);
		sectionText.text = 'Section: $curSection';
		sectionCameraStepper.setValue(Utility.intClamp(songData.sections[curSection].cameraFacing + 1, 0, songData.characters.length));
		noteGroup.clear();

		for(i in 0...songData.sections[curSection].notes.length){
			var noteData = songData.sections[curSection].notes[i];
			var newNote = genNote(noteData.strumTime, noteData.column, noteData.type, false, false, noteData.player);
			newNote.color = noteSelected(noteData, curSection) ? NOTE_SELECT_COLOUR : 0xFFFFFFFF;
			noteGroup.add(newNote);

			for(j in 1...noteData.length + 1){
				var susNote = genNote(noteData.strumTime + j, noteData.column, noteData.type, true, j == noteData.length, noteData.player);
				susNote.x += GRID_SIZE * 0.3;
				susNote.color = newNote.color;
				noteGroup.add(susNote);
			}
		}

		var offSec = songData.sections[curSection + Math.floor(sectionCopyStepper.value)]; 

		if (!showCopyPreview || offSec == null)
			return;

		for(i in 0...offSec.notes.length) {
			var noteData = offSec.notes[i];
			var newNote = genNote(noteData.strumTime, noteData.column, noteData.type, false, false, noteData.player);
			newNote.color = 0xAA000000;
			noteGroup.add(newNote);
		}
	}

	function correctSection(sec:Int):Bool {
		var dirty:Bool = false;
		var i:Int = -1;

		while(++i < songData.sections[sec].notes.length){
			var tmpNote = songData.sections[sec].notes[i];
			var secOffset = Math.floor(tmpNote.strumTime / 16);

			tmpNote.player = Utility.intCircularMod(tmpNote.player + Math.floor(tmpNote.column / PlayState.KEY_COUNT), songData.characterCharts);
			tmpNote.column = Utility.intCircularMod(tmpNote.column, PlayState.KEY_COUNT);
			tmpNote.strumTime = Utility.circularMod(tmpNote.strumTime, 16);

			if (secOffset == 0 || (secOffset < 0 && sec == 0))
				continue;

			dirty = true;
			sectionNullCheck(sec + secOffset);
			songData.sections[sec].notes.splice(i--, 1);
			songData.sections[sec + secOffset].notes.push(tmpNote);

			if (noteSelected(tmpNote, sec)){
				if (selectedNotes.get(sec + secOffset) == null && songData.sections[sec + secOffset] != null)
					selectedNotes.set(sec + secOffset, []);

				(selectedNotes.get(sec)).remove(tmpNote);
				(selectedNotes.get(sec + secOffset)).push(tmpNote); 
			}
		}

		return dirty;
	}
	
	function mouseScroll(ev:MouseEvent) {
		vocals.pause();
		FlxG.sound.music.pause();

		FlxG.sound.music.time = Math.max((Song.currentStep - (ev.delta - (Settings.audio_offset > 0 ? 1 : 0))) * Song.stepCrochet, 0);
		Song.update(FlxG.sound.music.time);
		stepTime = Math.max(Song.millisecond * Song.division, 0);
	}

	function mouseMove(ev:MouseEvent) {
		mainUIBox.hover(FlxG.mouse.x, FlxG.mouse.y);

		gridSelectX = Utility.intClamp(Math.floor((FlxG.mouse.x - gridGroup.x) / GRID_SIZE), 0, (songData.characterCharts * PlayState.KEY_COUNT) - 1);
		gridSelectY = Utility.clamp(Math.floor(((FlxG.mouse.y - gridGroup.y) * snaps[curZoom]) / GRID_SIZE) / snaps[curZoom], 0, 15);
		highlightBox.x = (gridSelectX * GRID_SIZE) + gridGroup.x;
		highlightBox.y = (gridSelectY * GRID_SIZE) + gridGroup.y;
		highlightBox.alpha = FlxG.mouse.x < gridGroup.x ? 0 : 0.75;

		if (FlxG.mouse.pressed && FlxG.keys.pressed.CONTROL){
			selectionBox.scale.x = FlxG.mouse.x - selectionBox.x;
			selectionBox.scale.y = FlxG.mouse.y - selectionBox.y;
		}
	}

	function mouseUp(ev:MouseEvent) {
		mainUIBox.onClickRelease();

		if (!FlxG.keys.pressed.CONTROL) 
			return;

		var selBoxX = ((selectionBox.x + (selectionBox.scale.x < 0 ? selectionBox.scale.x : 0)) - gridGroup.x) / GRID_SIZE;
		var selBoxY = ((selectionBox.y + (selectionBox.scale.y < 0 ? selectionBox.scale.y : 0)) - gridGroup.y) / GRID_SIZE;
		var selBoxWidth  = Math.abs(selectionBox.scale.x) / GRID_SIZE;
		var selBoxHeight = Math.abs(selectionBox.scale.y) / GRID_SIZE;

		selectionBox.alpha = 0;
		selectionBox.scale.set(0, 0);
		selectedNotes.clear();
		selectedNotes.set(curSection, []);

		for(i in 0...songData.sections[curSection].notes.length){
			var tmpNote = songData.sections[curSection].notes[i];

			if (tmpNote.column + (PlayState.KEY_COUNT * tmpNote.player) >= selBoxX
			 && tmpNote.column + (PlayState.KEY_COUNT * tmpNote.player) + 1 < selBoxX + selBoxWidth
			 && tmpNote.strumTime + 1 < selBoxY + selBoxHeight
			 && tmpNote.strumTime >= selBoxY)
				selectedNotes.get(curSection).push(tmpNote);
		}

		reloadNotes();
	}

	function mouseDown(ev:MouseEvent) {
		mainUIBox.onClick(FlxG.mouse.x, FlxG.mouse.y);

		if (FlxG.keys.pressed.CONTROL){
			selectionBox.alpha = 0.75;
			selectionBox.x = FlxG.mouse.x;
			selectionBox.y = FlxG.mouse.y;
			selectionBox.scale.set(0, 0);
			return;
		}

		if (FlxG.mouse.x < gridGroup.x)
			return;

		for(i in 0...songData.sections[curSection].notes.length){
			var tmpNote = songData.sections[curSection].notes[i];
			
			if (Math.floor(tmpNote.strumTime * 10) == Math.floor(gridSelectY * 10)
			 && tmpNote.player == Math.floor(gridSelectX / PlayState.KEY_COUNT)
			 && tmpNote.column == gridSelectX % PlayState.KEY_COUNT){
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
			type: curNoteType
		};

		songData.sections[curSection].notes.push(createdNote);
		selectedNotes.clear();
		selectedNotes.set(curSection, [createdNote]);
		reloadNotes();
	}
	
	function mouseRight(ev:MouseEvent) {
		for(k in selectedNotes.keys())
			while((selectedNotes.get(k)).length > 0)
				songData.sections[k].notes.remove(selectedNotes.get(k).pop());

		reloadNotes();
	}

	function uiInputGrab(ev:Event)
		inputGrabbed = true;

	function uiInputRelease(ev:Event)
		inputGrabbed = false;

	inline function shiftNotes(strumAdd:Int, columnAdd:Int){
		for(k in selectedNotes.keys())
			for(i in 0...selectedNotes.get(k).length){
				selectedNotes.get(k)[i].strumTime += strumAdd;
				selectedNotes.get(k)[i].column    += columnAdd;
			}

		for(k in selectedNotes.keys())
			correctSection(k);

		reloadNotes();
	}

	inline function jumpToSection(newStepTime:Float){
		FlxG.sound.music.pause();
		vocals.pause();
		stepTime = Math.max(newStepTime, 0);
		FlxG.sound.music.time = stepTime * Song.stepCrochet;
	}

	override function keyHit(ev:KeyboardEvent) {
		if (inputGrabbed) 
			return;

		if (FlxG.keys.pressed.SHIFT){
			ev.keyCode.bindFunctions([
				[Binds.ui_down, function(){
					for(k in selectedNotes.keys())
						for(i in 0...selectedNotes.get(k).length)
							selectedNotes.get(k)[i].length++;
					
					reloadNotes();
				}],
				[Binds.ui_up, function(){
					for(k in selectedNotes.keys())
						for(i in 0...selectedNotes.get(k).length)
							if (selectedNotes.get(k)[i].length > 0)
								selectedNotes.get(k)[i].length--;
					
					reloadNotes();
				}],
				[Binds.ui_left, function(){
					curNoteType = Utility.intCircularMod(--curNoteType, Note.NOTE_TYPES.length);
					noteTypeText.text = 'Note type: $curNoteType (${Note.NOTE_TYPES[curNoteType].assets})';

					for(k in selectedNotes.keys())
						for(i in 0...selectedNotes.get(k).length)
							selectedNotes.get(k)[i].type = curNoteType;
				
					reloadNotes();
				}],
				[Binds.ui_right, function(){
					curNoteType = Utility.intCircularMod(++curNoteType, Note.NOTE_TYPES.length);
					noteTypeText.text = 'Note type: $curNoteType (${Note.NOTE_TYPES[curNoteType].assets})';

					for(k in selectedNotes.keys())
						for(i in 0...selectedNotes.get(k).length)
							selectedNotes.get(k)[i].type = curNoteType;
					
					reloadNotes();
				}],
				[Binds.ui_back, function(){
					jumpToSection(0);
				}]
			]);
			return;
		}

		if (FlxG.keys.pressed.CONTROL){
			ev.keyCode.bindFunctions([
				[[FlxKey.C], function(){
					var newSelection:Map<Int, Array<NoteData>> = new Map<Int, Array<NoteData>>();

					for(k in selectedNotes.keys()){
						newSelection.set(k, []);

						for(i in 0...selectedNotes.get(k).length){
							var newNoteData:NoteData = Reflect.copy(selectedNotes.get(k)[i]);
							songData.sections[k].notes.push(newNoteData);
							newSelection.get(k).push(newNoteData);
						}
					}

					selectedNotes = newSelection;
				}],
				[[FlxKey.V], function(){
					for(k in selectedNotes.keys())
						for(n in selectedNotes.get(k))
							n.column = PlayState.KEY_COUNT - 1 - n.column;

					reloadNotes();
				}],
				[Binds.ui_down, function(){
					shiftNotes(1, 0);
				}],
				[Binds.ui_up, function(){
					shiftNotes(-1, 0);
				}],
				[Binds.ui_right, function(){
					shiftNotes(0, 1);
				}],
				[Binds.ui_left, function(){
					shiftNotes(0, -1);
				}],
				[Binds.ui_accept, function(){
					selectedNotes.clear();
					selectedNotes.set(curSection, []);
					for(n in songData.sections[curSection].notes)
						(selectedNotes.get(curSection)).push(n);

					reloadNotes();
				}]
			]);
			return;
		}

		ev.keyCode.bindFunctions([
			[Binds.ui_back, function(){
				FlxG.mouse.visible = false;
				FlxG.sound.music.volume = 1;
				FlxG.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseScroll);
				FlxG.stage.removeEventListener(MouseEvent.MOUSE_MOVE,  mouseMove);
				FlxG.stage.removeEventListener(MouseEvent.MOUSE_DOWN,  mouseDown);
				FlxG.stage.removeEventListener(MouseEvent.MOUSE_UP,    mouseUp);
				FlxG.stage.removeEventListener(MouseEvent.RIGHT_CLICK, mouseRight);
				FlxG.stage.removeEventListener('input_grab',    uiInputGrab);
				FlxG.stage.removeEventListener('input_release', uiInputRelease);

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
				jumpToSection((curSection + 1) * 16);
			}],
			[Binds.ui_up, function(){
				jumpToSection((curSection - 1) * 16);
			}],
			[Binds.ui_left, function(){
				curZoom = Utility.intClamp(curZoom - 1, 0, snaps.length - 1);
				snapText.text = 'Snap: ${1 / snaps[curZoom]}';
			}],
			[Binds.ui_right, function(){
				curZoom = Utility.intClamp(curZoom + 1, 0, snaps.length - 1);
				snapText.text = 'Snap: ${1 / snaps[curZoom]}';
			}]
		]);
	}

	override function keyRel(ev:KeyboardEvent) {
		if (!ev.keyCode.check([FlxKey.CONTROL]))
			return;

		selectionBox.alpha = 0;
		selectionBox.scale.set(0, 0);
	}

	/* UI Stuff **********************************/
	private inline function postWarning(text:String, colour:Int){
		if (textTween != null)
			textTween.cancel();

		warningText.alpha = 1;
		warningText.color = colour;
		warningText.text  = text;
		textTween = FlxTween.tween(warningText, {alpha: 0}, 1.75, {startDelay: 1.25});
	}

	private function saveSong(autosave:Bool = false){
		var corrections:String = '';
		var fileName:String = (autosave ? 'autosave.json' : 'edit.json');
		var path = 'assets/data/songs/${PlayState.songData.name}/editor';

		// Safety checks
		if (!StageLogic.STAGE_NAMES.contains(songData.stage))
			corrections += 'No stage called "${songData.stage}". (NOT Fixed)\n';

		if (songData.characterCharts > songData.characters.length){
			songData.characterCharts = songData.characters.length;
			corrections += 'More charts than characters. (Fixed)\n';
		}

		if (songData.activePlayer >= songData.characterCharts){
			songData.activePlayer = 0;
			corrections += 'Active player was higher than amount of charts. (Defaulted to 0)\n';
		}

		if (songData.BPM < 0 || songData.speed < 0 || songData.activePlayer < 0 || songData.startDelay < 0)
			corrections += 'Either BPM, speed, active player, or start delay was under 0. (NOT fixed)\n';

		for(i in 0...songData.sections.length){
			if (sectionNullCheck(i))
				corrections += 'Section $i did not exist. (Fixed)\n';

			if (correctSection(i))
				corrections += 'Section $i contained notes outside of range. (Fixed)\n';

			for(n in songData.sections[i].notes){
				var j:Int = -1;
				while(++j < songData.sections[i].notes.length){
					var tmpNote = songData.sections[i].notes[j];

					if (tmpNote == n 
					 || tmpNote.strumTime != n.strumTime 
				 	 || tmpNote.player != n.player 
					 || tmpNote.column != n.column)
						continue;

					corrections += 'Found duplicate note at section $i, position ${tmpNote.strumTime}. (Fixed)\n';
					songData.sections[i].notes.splice(j--, 1);
				}
			}
		}

		reloadNotes();

		var JsonString:String = Json.stringify(songData, '\t'); // '\t' enables pretty printing.

		#if desktop
		sys.FileSystem.createDirectory('$path');
		sys.io.File.saveContent('$path/$fileName', JsonString);
		postWarning('File saved to "$path/$fileName"', autosave ? 0xFF00AAFF : 0xFF00FFAA);
		
		if (corrections != '' && !autosave){
			sys.io.File.saveContent('$path/errors.txt', corrections);
			postWarning('Check errors/warnings at "$path/errors.txt"', 0xFFFFFF00);
			trace('\n' + corrections);
		}
		#else
		var fileDialog = new lime.ui.FileDialog();
		fileDialog.save(haxe.io.Bytes.ofString(JsonString), null, fileName);
		postWarning('File saved', 0xFF00FFAA);
		#end
	}

	function setHealthBarColour(player:Int, channel:Int, value:Int, colBox:SIColourbox) {
		channel = (2 - channel) << 3;

		var newColour = songData.healthColours[player];
		newColour ^= newColour & (0xFF << channel);
		newColour |= value << channel;
	
		songData.healthColours[player] = newColour;
		colBox.setColour(songData.healthColours[player]);
	}

	function propertiesUI():SIContainer {
		var tab = new SIContainer(null, TOPLEFT, 358, 590, mainUIBox);
		tab.spacing = 5;
		
		var nameBox = new SIInput(null, TOPLEFT, 170, songData.name, tab);
		nameBox.callback = function(str:String, finish:Bool) {
			songData.name = str;
		};

		var BPMStepper = new SIStepper(UNDER, nameBox, 170, songData.BPM, tab);
		BPMStepper.min = 1;
		BPMStepper.max = 1000;
		BPMStepper.callback = function(num:Float) {
			FlxG.sound.music.pause();
			vocals.pause();
			songData.BPM = num;
			Song.configure(songData.BPM);
		};

		var speedStepper = new SIStepper(UNDER, BPMStepper, 170, songData.speed, tab);
		speedStepper.min = 0.1;
		speedStepper.max = 10;
		speedStepper.step = 0.1;
		speedStepper.callback = function(num:Float) {
			songData.speed = num;
		};

		var stageDrop = new SIDropdown(UNDER, speedStepper, 170, songData.stage, StageLogic.STAGE_NAMES, tab);
		stageDrop.callback = function(str:String) {
			songData.stage = str;
		};

		/* Just for health bar colours :facepalm: */
		var oppCol = songData.healthColours[0];
		var oppColourbox = new SIColourbox(UNDER, stageDrop, oppCol, tab);
		var oppRS = new SIStepper(RIGHT, oppColourbox, 100, (oppCol >> 16) & 0xFF, tab);
		var oppGS = new SIStepper(RIGHT, oppRS,        100, (oppCol >> 8)  & 0xFF, tab);
		var oppBS = new SIStepper(RIGHT, oppGS,        100,  oppCol        & 0xFF, tab);
		oppRS.callback = function(num:Float) { setHealthBarColour(0, 0, Math.floor(num), oppColourbox); };
		oppGS.callback = function(num:Float) { setHealthBarColour(0, 1, Math.floor(num), oppColourbox); };
		oppBS.callback = function(num:Float) { setHealthBarColour(0, 2, Math.floor(num), oppColourbox); };

		var proCol = songData.healthColours[1];
		var proColourbox = new SIColourbox(UNDER, oppColourbox, proCol, tab);
		var proRS = new SIStepper(RIGHT, proColourbox, 100, (proCol >> 16) & 0xFF, tab);
		var proGS = new SIStepper(RIGHT, proRS,        100, (proCol >> 8)  & 0xFF, tab);
		var proBS = new SIStepper(RIGHT, proGS,        100,  proCol        & 0xFF, tab);
		proRS.callback = function(num:Float) { setHealthBarColour(1, 0, Math.floor(num), proColourbox); };
		proGS.callback = function(num:Float) { setHealthBarColour(1, 1, Math.floor(num), proColourbox); };
		proBS.callback = function(num:Float) { setHealthBarColour(1, 2, Math.floor(num), proColourbox); };
		oppRS.min = oppGS.min = oppBS.min = proRS.min = proGS.min = proBS.min = 0;
		oppRS.max = oppGS.max = oppBS.max = proRS.max = proGS.max = proBS.max = 255;
		/******************************************/

		var voicesCheck = new SICheckbox(UNDER, proColourbox, songData.hasVoices, tab);
		voicesCheck.callback = function(chk:Bool) {
			FlxG.sound.music.pause();
			vocals.pause();
			songData.hasVoices = chk;
			songData.hasVoices ? vocals.loadEmbedded(Paths.playableSong(songData.name, true)) : vocals = new FlxSound();
		};

		new SILabel(RIGHT, nameBox, 'Song Name', tab);
		new SILabel(RIGHT, BPMStepper, 'Song Tempo', tab);
		new SILabel(RIGHT, speedStepper, 'Scroll Speed', tab);
		new SILabel(RIGHT, stageDrop, 'Stage Name', tab);
		new SILabel(RIGHT, voicesCheck, 'Use Vocal Track', tab);

		var saveButton = new SIButton(null, BOTTOMRIGHT, 120, 'Save', tab);
		saveButton.callback = function() {
			saveSong(false);
		};

		var clearButton = new SIButton(ONTOP, saveButton, 120, 'Clear', tab);
		clearButton.callback = function() {
			songData.sections = [];
			sectionNullCheck(0);
			jumpToSection(0);
			reloadNotes();
		};

		var selectButton = new SIButton(ONTOP, clearButton, 120, 'Select All', tab);
		selectButton.callback = function() {
			selectedNotes.clear();
			for(i in 0...songData.sections.length){
				selectedNotes.set(i, []);
				for(n in songData.sections[i].notes)
					selectedNotes.get(i).push(n);
			}

			reloadNotes();
		};

		var reloadButton = new SIButton(ONTOP, selectButton, 120, 'Reload Song', tab);
		reloadButton.callback = function() {
			postWarning('Using "${Paths.playableSong(songData.name, false)}"', 0xFF00FFAA);
			FlxG.sound.list.remove(vocals);
			FlxG.sound.playMusic(Paths.playableSong(songData.name, false));
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			FlxG.sound.music.volume = 0.75;

			vocals.pause();
			vocals = new FlxSound();
			FlxG.sound.list.add(vocals);

			if (songData.hasVoices)
				vocals.loadEmbedded(Paths.playableSong(songData.name, true));
		}

		return tab;
	}

	function sectionUI() {
		var cameraLabel:SILabel = null;
		var tab = new SIContainer(null, TOPLEFT, 358, 590, mainUIBox);
		tab.spacing = 5;

		sectionCameraStepper = new SIStepper(null, TOPLEFT, 120, songData.sections[curSection].cameraFacing + 1, tab);
		sectionCameraStepper.callback = function(num:Float) {
			var rnum = Math.round(Math.max(Math.min(num, songData.characters.length), 1));
			sectionCameraStepper.setValue(rnum, true);
			cameraLabel.changeLabel('Camera Facing: ' + songData.characters[rnum - 1].name);
			songData.sections[curSection].cameraFacing = rnum - 1;
		};

		var clearButton = new SIButton(null, BOTTOMLEFT, 120, 'Clear', tab);
		clearButton.callback = function() {
			songData.sections[curSection] = null;
			sectionNullCheck(curSection);
			reloadNotes();
		};

		var swapButton = new SIButton(ONTOP, clearButton, 120, 'Swap/Shift', tab);
		swapButton.callback = function() {
			for(n in songData.sections[curSection].notes)
				++n.player;

			correctSection(curSection);
			reloadNotes();
		};

		var selectButton = new SIButton(ONTOP, swapButton, 120, 'Select', tab);
		selectButton.callback = function() {
			selectedNotes.clear();
			selectedNotes.set(curSection, []);

			for(n in songData.sections[curSection].notes)
				selectedNotes.get(curSection).push(n);

			reloadNotes();
		};

		var copyButton = new SIButton(ONTOP, selectButton, 120, 'Copy', tab);
		copyButton.callback = function() {
			var offSection = Utility.intClamp(curSection + sectionCopyStepper.value, 0, songData.sections.length - 1);
			sectionNullCheck(offSection);
			
			for(n in songData.sections[offSection].notes)
				songData.sections[curSection].notes.push(Reflect.copy(n)); 

			reloadNotes();
		};

		sectionCopyStepper = new SIStepper(ONTOP, copyButton, 120, 0, tab);
		sectionCopyStepper.callback = function(num:Float) {
			sectionCopyStepper.setValue(Math.round(num), true);
			if (showCopyPreview)
				reloadNotes();
		};

		var copyPreview = new SICheckbox(ONTOP, sectionCopyStepper, false, tab);
		copyPreview.callback = function(val:Bool) {
			showCopyPreview = val;
			reloadNotes();
		};

		cameraLabel = new SILabel(RIGHT, sectionCameraStepper, '', tab);
		new SILabel(RIGHT, sectionCopyStepper, 'Copy Offset', tab);
		new SILabel(RIGHT, copyPreview, 'Preview Copy Offset', tab);
		return tab;
	}

	private var characterNames:Array<String> = []; // Only used for the drop down
	private var playerDropDowns:Array<SIDropdown> = [null];
	private var positionBoxes:Array<Array<SIInput>> = [];
	function addPlayerDrop(ind:Int, tab:SIContainer) {
		playerDropDowns[ind] = new SIDropdown(UNDER, TOPLEFT, playerDropDowns[ind - 1], 150, songData.characters[ind].name, characterNames, tab);
		playerDropDowns[ind].callback = function(str:String) {
			songData.characters[ind].name = str;
			reloadGrid();
		};

		var xbox = new SIInput(RIGHT, playerDropDowns[ind], 55, Std.string(songData.characters[ind].x), tab);
		var ybox = new SIInput(RIGHT, xbox, 55, Std.string(songData.characters[ind].y), tab);
		positionBoxes[ind] = [xbox, ybox];
		xbox.callback = function(val:String, finished:Bool) {
			if (!finished)
				return;

			var fvalue:Float = Std.parseFloat(val);
			fvalue = Math.isNaN(fvalue) ? 0 : fvalue;
			songData.characters[ind].x = fvalue;
			xbox.changeText(Std.string(fvalue), false);
		};
		ybox.callback = function(val:String, finished:Bool) {
			if (!finished)
				return;

			var fvalue:Float = Std.parseFloat(val);
			fvalue = Math.isNaN(fvalue) ? 0 : fvalue;
			songData.characters[ind].y = fvalue;
			ybox.changeText(Std.string(fvalue), false);
		};
	}

	function findCharacterNames() {
		if (characterNames.length > 0) 
			return;

		characterNames = openfl.utils.Assets.list();

		var i = -1;
		while(++i < characterNames.length)
			if (characterNames[i].substring(0, 22) != 'assets/data/characters')
				characterNames.splice(i--, 1);

		for(i in 0...characterNames.length){
			var nameSplit:Array<String> = characterNames[i].split('/');
			characterNames[i] = nameSplit[nameSplit.length - 1];
			characterNames[i] = characterNames[i].split('.json')[0];
		}
	}

	function playersUI() {
		var tab = new SIContainer(null, TOPLEFT, 358, 590, mainUIBox);
		tab.spacing = 5;

		findCharacterNames();

		var activeStepper = new SIStepper(null, BOTTOMLEFT, 150, songData.activePlayer + 1, tab);
		activeStepper.min = 1;
		activeStepper.max = songData.characters.length;
		activeStepper.callback = function(num:Float) {
			var rnum = Math.round(Math.min(num, songData.characterCharts));
			songData.activePlayer = rnum - 1;
			activeStepper.setValue(rnum, true);
			reloadGrid();
		};

		var chartStepper = new SIStepper(ONTOP, activeStepper, 150, songData.characterCharts, tab);
		chartStepper.min = 1;
		chartStepper.max = songData.characters.length;
		chartStepper.callback = function(num:Float) {
			var rnum = Math.round(Math.min(num, 5)); // <-- 5 is arbitrary as anymore will not fit on screen.
			songData.characterCharts = rnum;
			chartStepper.setValue(rnum, true);
			activeStepper.setValue(songData.activePlayer + 1);
			reloadNotes();
		};

		var backwardsCheck = new SICheckbox(ONTOP, chartStepper, songData.renderBackwards, tab);
		backwardsCheck.callback = function(val:Bool) {
			songData.renderBackwards = val;
		};

		for(i in 0...songData.characters.length)
			addPlayerDrop(i, tab);

		var addButton = new SIButton(null, TOPRIGHT, 30, '+', tab);
		addButton.callback = function() {
			if (songData.characters.length >= 13)
				return;

			songData.characters.push({
				name: characterNames[0],
				x: 100,
				y: 100
			});

			activeStepper.max = chartStepper.max = songData.characters.length;
			addPlayerDrop(playerDropDowns.length, tab);
			reloadGrid();
			tab.redraw();
		};
	
		var popButton = new SIButton(LEFT, addButton, 30, '-', tab);
		popButton.callback = function() {
			if (songData.characters.length <= 1)
				return;

			tab.removeChild(playerDropDowns.pop());
			tab.removeChild(positionBoxes[positionBoxes.length - 1][1]);
			tab.removeChild(positionBoxes.pop()[0]);
			tab.redraw();
			songData.characters.pop();
			activeStepper.max = chartStepper.max = songData.characters.length;
			chartStepper.setValue(songData.characterCharts);
		};

		new SILabel(RIGHT, activeStepper, 'Active Player', tab);
		new SILabel(RIGHT, chartStepper, 'Amount of Charts', tab);
		new SILabel(RIGHT, backwardsCheck, 'Render Backwards', tab);
		return tab;
	}

	var pagesText:Array<String> = [
		'Common controls:

		Down/Up: Jump forward/back a section
		Left/Right: Increase/decrease snapping
		Accept: Toggle pausing and playing
		Back: Test chart changes

		Click: Add note to grid
		Click (on top of note): Delete note
		Right click: Delete selected notes',

		'Controls while holding SHIFT:

		Down/Up: Change selected notes length
		Left/Right: Change selected notes type
		Back: Jump back to the first section

		Controls while holding CONTROL:
		
		Click (and Drag): Select multiple notes
		Down/Up: Move selected notes up/down
		Left/Right: Move select notes left/right
		Accept: Select all notes in section
		C: Copy all selected notes
		V: Mirror selected notes',

		'Players: 
		
		Unlike most other engines, players are
		stored as a variable sized list of
		characters. "CharacterCharts" determines
		the charts respective to the characters.

		Active player controls which of the
		characters in the character list will
		have the player controlling them.

		Each player has an X and Y value
		next to them to determine their location.'
	];

	function helpUI() {
		var tab = new SIContainer(null, TOPLEFT, 358, 590, mainUIBox);
		tab.spacing = 5;

		var helpLabel  = new SILabel(null,  TOPLEFT, pagesText[0], tab);
		var backButton = new SIButton(null, BOTTOMLEFT,  120, '< Back', tab);
		var nextButton = new SIButton(null, BOTTOMRIGHT, 120, 'Next >', tab);
		backButton.callback = function() {
			pagesText.unshift(pagesText.pop());
			helpLabel.changeLabel(pagesText[0]);
		};
		nextButton.callback = function() {
			pagesText.push(pagesText.shift());
			helpLabel.changeLabel(pagesText[0]);
		}
		return tab;
	}
}
