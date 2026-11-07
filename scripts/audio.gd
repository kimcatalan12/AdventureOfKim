extends Node
## Plays the music loop and sound effects. Mute silences both.

const EFFECTS := ["click", "pickup", "correct", "wrong", "hit", "win"]

var _music: AudioStreamPlayer
var _players := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://audio/music.wav")
	_music.finished.connect(_music.play)
	add_child(_music)
	for effect: String in EFFECTS:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://audio/%s.wav" % effect)
		add_child(player)
		_players[effect] = player
	apply_settings()


func start_music() -> void:
	if not _music.playing:
		_music.play()


func play(effect: String) -> void:
	if not Game.muted:
		_players[effect].play()


func apply_settings() -> void:
	_music.volume_db = linear_to_db(maxf(Game.music_level, 0.001))
	_music.stream_paused = Game.muted
	for player: AudioStreamPlayer in _players.values():
		player.volume_db = linear_to_db(maxf(Game.effects_level, 0.001))
