extends Node
## Seam + Week-3 hook. Routes audio through AudioCue Resources so Week 3 only
## swaps stream FILES, never adds wiring. Streams are empty until then. (§6)

func play_sfx(id: String) -> void:
	# Later: fetch AudioCue from Database, play on a pooled player.
	pass

func play_music(id: String) -> void:
	# Later: fetch AudioCue from Database, crossfade music.
	pass