extends Node
## Original synthesized cues, no external audio dependencies or network streams.
var cues: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_index: int = 0
var ambience: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# A headless validator has no audio device; still expose cue generation to tests.
	if DisplayServer.get_name()=="headless":
		set_process(false)
		return
	for i in 10:
		var player = AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
	for cue in ["jump","land","step","swing","hit","hurt","cast","pickup","discovery","ui","dash","boom"]:
		cues[cue] = _make_cue(cue)
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	ambience.stream = _make_ambience()
	ambience.play()
	Events.sound.connect(play_cue)

func _process(_delta: float) -> void:
	if ambience:
		ambience.volume_db = linear_to_db(maxf(0.0001,float(RunState.settings.music))) - 17

func _exit_tree() -> void:
	for player in voices:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null
	cues.clear()

func play_cue(cue: String) -> void:
	if not cues.has(cue):
		return
	var player = voices[voice_index%voices.size()]
	voice_index += 1
	player.stream = cues[cue]
	player.volume_db = linear_to_db(maxf(0.0001,float(RunState.settings.sfx))) - (14 if cue == "step" else 4)
	player.pitch_scale = randf_range(0.95,1.05) if cue in ["step","swing","hit"] else 1.0
	player.play()

func _make_cue(cue: String) -> AudioStreamWAV:
	const RATE = 22050
	var durations = {"discovery":0.8,"pickup":0.34,"cast":0.28,"hurt":0.24,"boom":0.55,"swing":0.16,"dash":0.2}
	var duration: float = durations.get(cue,0.12)
	var count: int = int(duration*RATE)
	var bytes = PackedByteArray()
	bytes.resize(count*2)
	var rng = RandomNumberGenerator.new()
	rng.seed = cue.hash()
	for i in count:
		var t: float = float(i)/RATE
		var u: float = t/duration
		var frequency: float = 440.0
		var noise: float = rng.randf_range(-1,1)
		var sample: float
		match cue:
			"step", "land": frequency = 85.0*(1-u)
			"jump": frequency = 220+380*u
			"swing", "dash": frequency = 140+200*(1-u)
			"hit": frequency = 115*(1-u)
			"hurt": frequency = 140-80*u
			"cast": frequency = 350+650*u
			"discovery": frequency = [523.25,659.25,783.99,1046.5][mini(3,int(u*4))]
			"pickup": frequency = 660+440*u
			"boom": frequency = 55*(1-u)
			"ui": frequency = 760.0
		sample = sin(TAU*frequency*t)*0.55
		if cue in ["swing","dash","hit","boom","step","land"]:
			sample = lerpf(sample,noise,0.65 if cue in ["swing","dash"] else 0.3)
		if cue == "discovery":
			sample += sin(TAU*frequency*2*t)*0.15
		sample *= minf(1.0,t*200)*pow(1-u,2.5)*0.55
		bytes.encode_s16(i*2,int(clampf(sample,-1,1)*32767))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream

func _make_ambience() -> AudioStreamWAV:
	const RATE = 22050
	const LENGTH = 4
	var bytes = PackedByteArray()
	bytes.resize(RATE*LENGTH*2)
	for i in RATE*LENGTH:
		var t: float = float(i)/RATE
		var sample = sin(TAU*110*t)*0.12 + sin(TAU*165*t)*0.06 + sin(TAU*220*t)*0.025
		sample *= 0.8+0.2*sin(TAU*0.25*t)
		bytes.encode_s16(i*2,int(sample*32767))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = RATE*LENGTH
	stream.data = bytes
	return stream
