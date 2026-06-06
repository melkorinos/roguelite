extends Node

# ──────────────────────────────────────────────────────────────────────────────
# AudioManager — procedural chiptune sound effects, no asset files required.
# All sounds are generated from PCM math at startup (~8ms one-time cost).
# Scenes call: AudioManager.play("buy"), AudioManager.play("fire_t2"), etc.
#
# Sound names: click  buy  sell  forge  upgrade  reject  fire_t1  fire_t2  fire_t3
# ──────────────────────────────────────────────────────────────────────────────

const SAMPLE_RATE: int = 44100
const POOL_SIZE:   int = 10   # max simultaneous sounds

var _players: Array[AudioStreamPlayer] = []
var _pool_idx: int = 0
var _sounds:   Dictionary = {}   # String → AudioStreamWAV
var _volume_db: float = 0.0


func _ready() -> void:
	for _i: int in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"   # route through SFX bus so SettingsManager's SFX slider applies
		add_child(p)
		_players.append(p)
	# Seed initial volume from saved settings (SettingsManager loads before AudioManager)
	var sfx: float = SettingsManager.get_sfx_volume()
	_volume_db = -80.0 if sfx <= 0.001 else linear_to_db(sfx)
	_build_sounds()


func play(sound: String) -> void:
	if not _sounds.has(sound):
		return
	var p: AudioStreamPlayer = _players[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	p.stream = _sounds[sound] as AudioStreamWAV
	p.volume_db = _volume_db
	p.play()


func set_volume_db(db: float) -> void:
	_volume_db = db


# ── Sound construction ────────────────────────────────────────────────────────

func _build_sounds() -> void:
	# click — crisp bright ping (E6, 1318 Hz), 35 ms sine
	_sounds["click"] = _wav(_tone(1318.5, 0.035, 0.42, "sine"))

	# buy — ascending coin jingle: E5 → G5 → C6 (sine, Mario pickup)
	var buy := PackedByteArray()
	_append(buy, 659.25, 0.042, 0.50, "sine")
	_append(buy, 783.99, 0.042, 0.50, "sine")
	_append(buy, 1046.5, 0.080, 0.52, "sine")
	_sounds["buy"] = _wav(buy)

	# sell — descending coin return: G5 → E5 → C5 (sine, still pleasant)
	var sell := PackedByteArray()
	_append(sell, 783.99, 0.040, 0.45, "sine")
	_append(sell, 659.25, 0.040, 0.45, "sine")
	_append(sell, 523.25, 0.075, 0.42, "sine")
	_sounds["sell"] = _wav(sell)

	# forge — alchemical synthesis: triangle-wave rumble rising to a bright sine ping;
	# triangle = warm/earthy (materials going in), sine = clean (new thing coming out)
	var forge := PackedByteArray()
	_append(forge, 196.00, 0.055, 0.38, "triangle")  # G3 — earthy base
	_append(forge, 293.66, 0.050, 0.40, "triangle")  # D4
	_append(forge, 440.00, 0.050, 0.44, "triangle")  # A4 — building tension
	_append(forge, 880.00, 0.115, 0.52, "sine")       # A5 — bright synthesis ping
	_sounds["forge"] = _wav(forge)

	# upgrade — merge/level-up chime: ascending C5→E5→G5→C6 (sine, full octave resolve)
	var upgrade := PackedByteArray()
	_append(upgrade, 523.25, 0.040, 0.48, "sine")  # C5
	_append(upgrade, 659.25, 0.040, 0.50, "sine")  # E5
	_append(upgrade, 783.99, 0.040, 0.50, "sine")  # G5
	_append(upgrade, 1046.5, 0.095, 0.54, "sine")  # C6 — octave resolve
	_sounds["upgrade"] = _wav(upgrade)

	# reject — denied/no-gold buzz: descending square E4→A3 (minor-7th drop, dissonant)
	var reject := PackedByteArray()
	_append(reject, 329.63, 0.048, 0.42, "square")  # E4
	_append(reject, 220.00, 0.090, 0.40, "square")  # A3
	_sounds["reject"] = _wav(reject)

	# fire_t1 — short punchy NES hit: single square A4 (440 Hz), 65 ms
	_sounds["fire_t1"] = _wav(_tone(440.0, 0.065, 0.44, "square"))

	# fire_t2 — two-note hit A4 → E5 (square), slightly richer
	var t2 := PackedByteArray()
	_append(t2, 440.0,  0.040, 0.44, "square")
	_append(t2, 659.25, 0.065, 0.46, "square")
	_sounds["fire_t2"] = _wav(t2)

	# fire_t3 — satisfying ascending blast C5 → E5 → G5 → C6 (square, big hit)
	var t3 := PackedByteArray()
	_append(t3, 523.25, 0.042, 0.50, "square")
	_append(t3, 659.25, 0.042, 0.50, "square")
	_append(t3, 783.99, 0.042, 0.52, "square")
	_append(t3, 1046.5, 0.090, 0.55, "square")
	_sounds["fire_t3"] = _wav(t3)


# ── PCM helpers ───────────────────────────────────────────────────────────────

# Single-tone shorthand.
func _tone(freq: float, duration: float, amplitude: float, wave: String) -> PackedByteArray:
	var buf := PackedByteArray()
	_append(buf, freq, duration, amplitude, wave)
	return buf


# Append one tone segment to an existing buffer.
func _append(buf: PackedByteArray, freq: float, duration: float, amplitude: float, wave: String) -> void:
	var n: int = int(SAMPLE_RATE * duration)
	var attack_n: int = int(SAMPLE_RATE * 0.005)  # 5 ms linear attack
	for i: int in n:
		# Envelope: quick attack, then smooth exponential decay
		var env: float
		if i < attack_n:
			env = float(i) / float(attack_n)
		else:
			env = pow(1.0 - float(i - attack_n) / float(n - attack_n), 1.6)
		env = maxf(env, 0.0)

		var t: float = float(i) / float(SAMPLE_RATE)
		var phase: float = freq * t
		var v: float
		match wave:
			"sine":
				v = sin(TAU * phase)
			"square":
				v = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			"triangle":
				var p: float = fmod(phase, 1.0)
				v = 2.0 * abs(2.0 * p - 1.0) - 1.0
			_:
				v = sin(TAU * phase)

		var s: int = clampi(int(v * env * amplitude * 32767.0), -32768, 32767)
		buf.append(s & 0xFF)
		buf.append((s >> 8) & 0xFF)


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream
