extends Node
## Efectos de sonido base (M-02), generados en código: no hay archivos de audio.
## Cada sonido es un AudioStreamWAV con PCM de 16 bits armado con ondas y ruido bajo una
## envolvente, al estilo sfxr. Son originales, así que no traen licencias. Salen por el bus
## de Efectos de Settings. Sin dispositivo de audio (headless) no pasa nada: se cae en silencio.

const RATE := 22050
const VOICES := 8
## Nombres de los sonidos disponibles.
const NAMES: Array[StringName] = [
	&"flipper", &"bumper", &"slingshot", &"plunger", &"drain", &"ball_saved", &"jackpot",
]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
## Cuántas veces se pidió cada sonido (lo usan los tests).
var play_counts := {}


func _ready() -> void:
	for sound in NAMES:
		_streams[sound] = _build(sound)


## Reproduce un sonido por nombre. `pitch` varía el tono para que no suene siempre igual.
func play(sound: StringName, pitch := 1.0) -> void:
	if not _streams.has(sound):
		return
	play_counts[sound] = int(play_counts.get(sound, 0)) + 1
	if _players.is_empty():
		_make_players()
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[sound]
	player.pitch_scale = maxf(pitch, 0.1)
	player.play()


func stream_of(sound: StringName) -> AudioStreamWAV:
	return _streams.get(sound)


func _make_players() -> void:
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = &"Efectos" if AudioServer.get_bus_index(&"Efectos") != -1 else &"Master"
		add_child(player)
		_players.append(player)


func _build(sound: StringName) -> AudioStreamWAV:
	match sound:
		&"flipper":  # Golpe seco y grave.
			return _make(0.09, 160.0, 70.0, 0.0, 0.35, 0.35, 8.0)
		&"bumper":  # Boing agudo.
			return _make(0.16, 520.0, 1100.0, 0.0, 0.1, 0.4, 4.0)
		&"slingshot":  # Chasquido: ruido con un tono corto.
			return _make(0.1, 320.0, 160.0, 1.0, 0.55, 0.35, 7.0)
		&"plunger":  # Resorte que se suelta: sube rápido.
			return _make(0.28, 110.0, 520.0, 0.0, 0.15, 0.4, 3.0)
		&"drain":  # Caída descendente.
			return _make(0.7, 330.0, 45.0, 0.0, 0.2, 0.45, 2.0)
		&"ball_saved":  # Arpegio ascendente corto.
			return _arpeggio([523.25, 659.25, 783.99], 0.09)
		&"jackpot":  # Arpegio largo y brillante.
			return _arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0], 0.08)
	return null


## Un tono que barre de `f0` a `f1`, con `noise` de ruido (0..1), onda cuadrada
## según `square` (0 = seno, 1 = cuadrada) y envolvente exponencial de caída `decay`.
func _make(seconds: float, f0: float, f1: float, noise: float, square: float, gain: float,
		decay: float) -> AudioStreamWAV:
	var count := int(seconds * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + int(f0)  # Determinista: el mismo sonido siempre.
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		phase += lerpf(f0, f1, t) / RATE
		var s := sin(TAU * phase)
		var sq := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		var tone := lerpf(s, sq, square)
		var n := rng.randf_range(-1.0, 1.0)
		var attack := minf(1.0, i / 40.0)
		samples[i] = lerpf(tone, n, noise) * exp(-decay * t * 2.0) * attack * gain
	return _to_wav(samples)


func _arpeggio(notes: Array, step: float) -> AudioStreamWAV:
	var all := PackedFloat32Array()
	for freq: float in notes:
		var count := int(step * RATE)
		var phase := 0.0
		for i in count:
			var t := float(i) / count
			phase += freq / RATE
			var sq := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			all.append(lerpf(sin(TAU * phase), sq, 0.3) * exp(-2.5 * t) * minf(1.0, i / 30.0) * 0.35)
	return _to_wav(all)


func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav
