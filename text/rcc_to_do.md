
SOUNDFONT TO DO

[.] Godot SFZ Instrument editor:
	GUI based editor that provides the same controls as TriloTracker on the MSX, with editable wavetable and macro editors. Once the instrument set is created, it can be exported as SFZ (text files+wave files), and optionally converted to SF2 using Polyphone (works in Polyphone 2.2).

-------------------------------------------------------------------------------

--->[ ] Functional Morph envelope
		[ ] Multiple waveforms per instrument

--->[ ] Separate Pitch envelope into:
		- Note (each step is a note, arbitrary range)
		- Pitch (frequency shift, -1.0 to +1.0 with 8 or 16 steps each way)

	[.] Loading and saving
		[X] Session file, loaded and saved automatically
		[/] Multi Instrument Export to single SFZ - Not doable!
------->[ ] File open and save dialogue boxes. Needs "FileDialog" node

	[ ] Escape Key Stops all playback

	[ ] Export Settings: If single sample, pick the exported note

	[ ] Undo system, probably keeping duplicates of the instrument resources

	[ ] Visual feedback on piano keys (highlight and fade)

	[ ] Instrument instancing (SFZ preset with different name but same group(?))

	[ ] Envelope processing:
		[ ] Offset left, right
		[ ] Mirror H and V
		[ ] Add Noise
		[ ] Volume + -
		[ ] Smooth

	[ ] Move RCC_Connections to root node, maybe remove outgoing signals (call nodes directly from the root)
		[ ] While you're at it, Consider creating a Wave Editors scene, so that RCC_Connections will send fewer output signals

	[X] Envelope Editing Improvements
		[X] Preset waves
			[X] Separate into wave, volume and pitch presets
		[X] Add "attack" and "release" checkboxes to envelope editors. When off, envelope ignores anything outside in/out points and loops instead of holding value
		[X] Functional Noise envelope
		[X] Top and Bottom margins for max/min value
		[X] Numeric feedback when dragging bars
		[X] Grey out envelope areas when attack/release are disabled
		[X] Consider linking all envelope lengths and loop points, for simplicity. Otherwise, finding the Least Common Multiples between all loop points can dramatically increase the exported file size.

	[X] Realtime playback engine for notes+macros
		[X] Waveform visualization for debugging
		[ ] "Output view" with final waveform

	[X] BUG: Only Volume envelope dictates instrument looping
		- Clue: Instrument.at_end(), and envelope "completed" behavior seems to be at fault here.

	[?] Very low (F1 and lower) notes cause the loop points to fail, since the note frequency falls below 60Hz (tick rate).
		- Solution: different method for calculating loop points, based on calculating how many samples each note frequency needs.
		- Maybe only use the new method on lower octaves, but if it works really well then it can be used everywhere
		- UPDATE: Seems good enough now for most cases, and the method mentioned above didn't quite work (doesn't account for the loop length, the fact that during a loop the last note may need to be cut off, etc)

	[X] Triangle wave is very quiet. Possibly an issue committing the envelopes?

	[X] SFZ Export is still buggy, pitch envelopes don't work correctly (check "Square" instrument in Renoise)

	[X] Better defaults:
		[X] Range 2 to 7, interval 3
		[X] No loop for envelopes
		[ ] BUG? Ensure 4 bit envelopes have max_value=15, not 16

	[X] Fix exported loop points bug. Loop points must be consistent between real time playback and baked SFZ, down to the actual sample . May require returning precise in/out points (in samples, not ticks) from the generator function, probably based on the where "instrument.commit_envelopes" function runs.	
		[X] Improve commit_envelopes, based on sign change? Threshold? Think about it.

	[?] "Sleep" playback engine when nothing is played
		(Seems to be working, needs more testing)

	[X] Test wave output from Godot (using "AudioEffectRecord"). (Update: just use AudioStreamPlayer.save_to_wav() )

	[X] Basic wavetable editing UI
		[X] Playback using piano keys
			[X] Pressing a new key before releasing previous key not working correctly
		[X] Clean playback (no "clicking when changing pitch/volume")
		[X] Instruments always have envelope arrays with min size=1
		[X] Pressing keys should properly use ADSR (not cut off)
		[X] Disable processing when nothing is playing.

	[X] Macro editing UI.
		[X] Volume
		[X] Pitch
		[X] Noise Volume
		[X] Loop points (needs playback engine)
		[X] Max value (zooms the editor in/out)
		[X] Length (linked in all macro editors)

	[X] Instrument Inspector
		[X] Add Export fields:
			[X] Octave range
			[X] Mix frequency (22050/44100)
			[X] Resolution (8/16 bit)

	[X] Instrument List Buttons (+,-,duplicate, up, down)

	[/] Think about centralized instruments (should RCC be a singleton?)

	[X] Non real time wave generation
		[X] Refactor so that same "engine" can be real time or not
		[X] Full wave export with macro "baked in"
		[X] Prototype simple SFZ export with single wave file per instrument
		[X] Multi Sample Export
		[X] Selectable number of wave files. Too few and the macros will play weirdly, since they're baked in. I'm estimating 1 every 3 or 4 notes (3 or 4 per octave) should play OK and keep the SF2 file size under 500Kb.
		[X] Export samples to a sub folder
		[X] Export all instruments to .wav or .sfz

	[X] Raise middle octave to C4 (to allow lower pitched notes)

-------------------------------------------------------------------------------

Keys:
	[ ] Not started
	[X] Done
	[.] In progress
	[/] Abandoned
	[~] Done, but could be better
	[?] Unknown, needs review
	--->Priority