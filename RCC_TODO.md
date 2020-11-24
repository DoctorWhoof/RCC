

RCC, Godot SFZ Instrument editor 
-------------------------------------------------------------------------------
GUI based editor that provides similar controls as TriloTracker on the MSX, with editable wavetable and macro editors. Once the instrument set is created, it can be exported as SFZ (text files+wave files), and optionally converted to SF2 using Polyphone (works in Polyphone 2.2).

-------------------------------------------------------------------------------
Keys:

	[ ] Not started
	[X] Done
	[.] In progress
	[/] Abandoned
	[~] Done, but could be better
	[?] Unknown, needs review
	--->Priority
-------------------------------------------------------------------------------

Target: 1.0 Release

	[ ] App Icon

	[ ] Move Undo "push" and "pull" functionality into an Undo singleton, so that it's available from any editor, not just the main scene. 

	[ ] BUG: pasting envelopes needs to respect min/max values

	[ ] Shortcuts
			[ ] Shortcut tool tips

	[X] Hide Multi-sample related controls when Minimal Export Scheme is selected 

	[X] Duplicating instruments doesn't duplicate all new instrument features (i.e. export scheme)

	[X] Envelope filters? Having trouble matching Quarth sounds...

	[X] Edit Filters need to clamp values

	[X] Regenerate Auto Vibrato's Pitch envelope whenever instrument's loop points or envelope size change

	[.] Undo system, probably keeping duplicates of the instrument resources in memory
		- Partially working! (envelopes edits only). Figure out an undo system for anything, not just envelopes - probably using project copies?
		- There's a Godot bug with deep-duplicating resources that's getting in the way. I could:
			- Wait for Godot 4.0 or use project.duplicate(true) for each undo step, or
			- Create a system to copy all project's instruments on each undo step, to be able to undo instrument moving/adding/removing.

	[.] Envelope Edit: Copy and Paste

	[.] Instrument inspector improvements:
		[.] Add Instrument comment text box
		[.] Add Current note and octave box at the bottom for user feedback.
		[ ] Transpose note (0 to 11). Maybe use a single value internally and 	"break it" into note and octave in the UI?

	[X] Add "Default Export Style" per instrument.
		[X] Add override export style to Export Options Dialog: No override means per instrument settings, can be overridden to "baked" or "minimal".

	[X] Apparently .XM envelopes can only have a few points... let's focus on .IT instead (alternative: optimized envelopes. Needs testing). .IT is the only tracker format that allows pitch envelopes, anyway.

	[X] Think about what to do about Pitch envelopes.
		X Hide them, for Tracker format compatibility?
		- Have the UI communicate that it's being driven by auto-vibrato?

	[X] Export Options dialog
			[X] File numbering:
				[X] Digit count
				[X] None
				[X] Prepend
				[X] Append
			[X] Remove old files?
			[X] Convert spaces to "_"
			[X] Override precision and sample rate
			[/] Should wave export also include numbering?
			[/] Override min/max sample interval

	[X] Replace Pitch Envelope with Vibrato Controls for OpenMPT compatibility

	[X] SFZ Export modes:
		[X] Full: RCC Envelopes are baked into the output wave files for maximum accuracy, at the expense of file sizes.
		[.] Minimal: Tiny, single loop, single wave files with sfz envelopes. RCC Envelopes need to be represented in the UI with lines connecting the start of each column, i.e. each point will be separated by at least one column. Only the first column in noise envelopes is used (i.e. The entire sample is either noise or tone). Not accurate, but results in much smaller file sizes.
			- Using arbitrary envelopes may be an OpenMPT specific feature, since Renoise or Polyphone didn't seem to work with it.
			- Update: egN opcodes are in SFZ V2, which not all apps support. OpenMPT's implementation seems correct?

	[X] Test higher mix rate (88.2Khz) in OpenMPT

	[X] OpenMPT SFZ Export Fixes:
		[X] Volume envelopes are getting cut-off at the bottom. Maybe it's non-linear?
		[X] Notes seem a semitone too high 

	[X] BUG: Loop is wrong when importing baked sfz into OpenMPT. Try writing the loop mode into the group? (Solution: "no_loop" value for non-looping waves, instead of "one_shot")


-------------------------------------------------------------------------------

Target: 1.1 Release

	[ ]General clean up:
		[ ] Script and Class names (Like "ExportStyle" to "Scheme", etc.)
		[ ] Remove unnecessary/unused files
		[ ] Code comments

-------------------------------------------------------------------------------

Target: Low priority

	[ ] BUG: "SCC Bass Distorted" detected loop points are wrong when exporting to baked sfz. Disabling loop for now.

	[ ] Rename classes and variables called "ExportStyle" and "scheme" to "ExportScheme" and "export_scheme", including in UI for consistency

	[ ] Allow multiple instrument selection
		[ ] Multi instrument inspection
		[ ] Multi Instrument export

	[ ] SFZ Remapping - Each RCC instrument can be exported as multiple SFZ files with different indices and names (all copies point to the same wave files, which stay named as the original). This will be useful when creating a General Midi library.
		[ ] Alternate UI: GM Mapper, where each pre-filled GM Name can be assigned one of the project's instruments

	[ ] Export Settings: If single sample, pick the exported note

	[ ] Analogue emulation
		[ ] PSG noise "Click" artifact, useful for punchy percussion
		[ ] Fuzzy artifacts like overshoot and noise

	[ ] Morph envelope (Multiple waveforms per instrument)
		[ ] Maybe only two, with interpolation between?
		[ ] Or 4 different waves with a 2 bit envelope?

	[ ] Implement scalable UI (Cmd+Plus, Cmd+Minus)

	[ ] Replace piano keys timers with Tween nodes?

	[ ] Very low (F1 and lower) notes cause the loop points to fail, since the note frequency falls below 60Hz (tick rate).
		- Solution: different method for calculating loop points, based on calculating how many samples each note frequency needs.
		- Maybe only use the new method on lower octaves, but if it works really well then it can be used everywhere
		- UPDATE: Seems good enough now for most cases, and the method mentioned above didn't quite work (doesn't account for the loop length, the fact that during a loop the last note may need to be cut off, etc)
		[ ] New solution: increase length of loop section when note falls below 60Hz? +1 tick should do the trick!

	[ ] Envelope processing toolbar (each one can be a button on a floating toolbar over the envelope, or a toolbar that is docked and can be toggled):
		[ ] Selection, filters affect selection only unless nothing is selected
		[ ] Offset left, right
		[ ] Mirror H and V
		[.] Add Noise
		[.] Volume + -
		[.] Smooth

	[X] Optimize sfz envelopes (remove redundant points)

Done:

	[X] Escape Key Stops all playback

	[/] Instrument instancing (SFZ file with different name but same samples)

	[X] BUG: Some loop points are correct in inspector, but wrong on wave editors (and playback!) after quitting and reloading.
		[X] Possible solution: Remove envelope loop points, keep only instrument points. (removing variables from envelopes didn't work, but removing UI controls for them seems to have done the trick)

	[X] Create New instrument "in place" (not at bottom)

	[X] Non-Linear wavetable volume

	[X] Prepend numbers to exported files so that sorting order matches your project

	[X] Separate Pitch envelope into:
		- Note (each step is a note, arbitrary range)
		- Pitch (frequency shift, -1.0 to +1.0 with 8 or 16 steps each way)

	[X] Progress bar for exporting (updates per note, per instrument)

	[X] Visual feedback on piano keys (highlight and fade). Timer based?
		[X] Visual feedback on current octave change
		[X] Smooth scrolling (Another timer? Slerp?)
		[X] BUG Current Key highlighted is wrong when keyboard is used
		[X] Multiple bugs on piano scrolling.
			[X] Ensure it only scrolls when necessary
			[?] Key size (min_size.x) causes mouse clicks to not register.

	[X] Export multiple files dialog box that remembers last path

	[X] Bug: "effective_in" calculation needs to take into account non-looping envelopes (effective_in will only happen after one full envelope length)
		[?] Warn user that a mix of looping and non-looping envelopes can lead to undesirable exports
		[?] MAYBE: Try to calculate accurate loop_in when loops are in a mixed state and export pre-roll is used. A bit of a corner case.

	[X] BUG: "Square Lead" Test instrument loop points not export correctly below E2

	[X] Implement line_edit focus fix for spinboxes 

	[X] Loading and saving
		[X] Session file, loaded and saved automatically
		[/] Multi Instrument Export to single SFZ - Not doable!
		[X] File open and save dialogue boxes. Needs "FileDialog" nodes

	[X] Move RCC_Connections to root node, maybe remove outgoing signals (call nodes directly from the root)
		[?] While you're at it, Consider creating a "WaveEditors" scene, so that RCC_Connections will send fewer output signals

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

	[X] Triangle wave is very quiet. Possibly an issue committing the envelopes?

	[X] SFZ Export is still buggy, pitch envelopes don't work correctly (check "Square" instrument in Renoise)

	[X] Better defaults:
		[X] Range 2 to 7, interval 3
		[X] No loop for envelopes
		[?] BUG? Ensure 4 bit envelopes have max_value=15, not 16

	[X] Fix exported loop points bug. Loop points must be consistent between real time playback and baked SFZ, down to the actual sample . May require returning precise in/out points (in samples, not ticks) from the generator function, probably based on the where "instrument.commit_envelopes" function runs.	
		[X] Improve commit_envelopes, based on sign change? Threshold? Think about it.

	[X] "Sleep" playback engine when nothing is played
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

