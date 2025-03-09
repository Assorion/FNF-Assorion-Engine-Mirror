package states;

class ChartingState extends EventState {
	public var noteList:Array<Note> = [];
	public var songData:SongData;

	public function create(){
		super.create();

		songData = PlayState.songData;

		for(section in songData.notes)
			for(fNote in section.sectionNotes){
				var noteData :Int = Std.int(fNote[1]);
				var susLength:Int = Std.int(fNote[2]);
				var player	 :Int = CoolUtil.intBoundTo(Std.int(fNote[3]), 0, songData.playLength - 1);
				var ntype	 :Int = Std.int(fNote[4]);

				var newNote = new Note(fNote[0], noteData, ntype, false, false);
				newNote.player = player;
				noteList.push(newNote);

				/*if(susLength > 1)
					for(i in 0...susLength+1){
						var susNote = new Note(time + i + 0.5, noteData, ntype, true, i == susLength);
						susNote.scrollFactor.set();
						susNote.player = player;
						chartNotes.push(susNote);
					}*/
			}

		noteList.sort((A,B) -> Std.int(A.strumTime - B.strumTime));

		
	}
}
