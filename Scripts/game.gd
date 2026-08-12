extends Control


# --------------------------------------------------
# NODES
# --------------------------------------------------

@onready var tile_buttons: Array[Button] = [
	$MarginContainer/VBoxContainer/GridContainer/Tile0,
	$MarginContainer/VBoxContainer/GridContainer/Tile1,
	$MarginContainer/VBoxContainer/GridContainer/Tile2,
	$MarginContainer/VBoxContainer/GridContainer/Tile3
]

@onready var round_label: Label = $MarginContainer/VBoxContainer/RoundLabel
@onready var instruction_label: Label = $MarginContainer/VBoxContainer/InstructionLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var reaction_label: Label = $MarginContainer/VBoxContainer/ReactionLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton


# --------------------------------------------------
# AUDIO
# --------------------------------------------------

@onready var tile_click_sound: AudioStreamPlayer = $TileClickSound
@onready var wrong_sound: AudioStreamPlayer = $WrongSound
@onready var perfect_sound: AudioStreamPlayer = $PerfectSound
@onready var end_run_sound: AudioStreamPlayer = $EndRunSound


# --------------------------------------------------
# PERFECT FX
# --------------------------------------------------

var perfect_fx_layer: Control
var perfect_flash: ColorRect
var perfect_label: Label


# --------------------------------------------------
# SETTINGS
# --------------------------------------------------

const STARTING_SEQUENCE_LENGTH: int = 3
const ROUNDS_PER_DIFFICULTY_INCREASE: int = 5
const MAX_ROUNDS: int = 20

const FLASH_TIME: float = 0.22
const FLASH_GAP: float = 0.14

const WRONG_PENALTY_MS: float = 500.0


# --------------------------------------------------
# CURRENT ROUND STATE
# --------------------------------------------------

var sequence: Array[int] = []

var current_input_index: int = 0
var current_round: int = 0

var accepting_input: bool = false
var game_running: bool = false

var round_start_usec: int = 0
var first_input_usec: int = 0

var mistakes_this_round: int = 0

var score: int = 0


# --------------------------------------------------
# SESSION STATISTICS
# --------------------------------------------------

var reaction_times: Array[float] = []

var total_time_ms: float = 0.0
var total_mistakes: int = 0

var perfect_streak: int = 0

var wrong_message_version: int = 0


# --------------------------------------------------
# READY
# --------------------------------------------------

func _ready() -> void:
	
	create_perfect_fx()
	
	
	for i in range(tile_buttons.size()):
		
		var button: Button = tile_buttons[i]
		
		button.focus_mode = Control.FOCUS_NONE
		button.modulate = Color.WHITE
		
		button.button_down.connect(
			_on_tile_pressed.bind(i)
		)
	
	
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.button_down.connect(_on_start_pressed)
	
	
	instruction_label.text = "PRESS START"
	time_label.text = "TIME: ---"
	reaction_label.text = "REACTION: ---"
	score_label.text = "SCORE: 0"
	round_label.text = "ROUND 0"


# --------------------------------------------------
# CREATE PERFECT FX
# --------------------------------------------------

func create_perfect_fx() -> void:
	
	if is_instance_valid(perfect_fx_layer):
		return
	
	
	# FX LAYER
	
	perfect_fx_layer = Control.new()
	
	add_child(perfect_fx_layer)
	
	perfect_fx_layer.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	
	perfect_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	perfect_fx_layer.z_index = 100
	
	
	# FULL-SCREEN FLASH
	
	perfect_flash = ColorRect.new()
	
	perfect_fx_layer.add_child(perfect_flash)
	
	perfect_flash.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	
	perfect_flash.color = Color.WHITE
	perfect_flash.modulate.a = 0.0
	perfect_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	
	# PERFECT LABEL
	
	perfect_label = Label.new()
	
	perfect_fx_layer.add_child(perfect_label)
	
	perfect_label.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	
	perfect_label.text = "PERFECT!"
	
	perfect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perfect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	perfect_label.add_theme_font_size_override(
		"font_size",
		120
	)
	
	perfect_label.modulate.a = 0.0
	perfect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


# --------------------------------------------------
# START / RESTART
# --------------------------------------------------

func _on_start_pressed() -> void:
	
	if game_running:
		return
	
	
	game_running = true
	
	current_round = 0
	score = 0
	
	reaction_times.clear()
	
	total_time_ms = 0.0
	total_mistakes = 0
	
	perfect_streak = 0
	wrong_message_version = 0
	
	
	start_button.hide()
	
	
	score_label.text = "SCORE: 0"
	time_label.text = "TIME: ---"
	reaction_label.text = "REACTION: ---"
	instruction_label.text = ""
	
	
	start_next_round()


# --------------------------------------------------
# START NEXT ROUND
# --------------------------------------------------

func start_next_round() -> void:
	
	current_round += 1
	
	accepting_input = false
	
	current_input_index = 0
	mistakes_this_round = 0
	first_input_usec = 0
	
	
	round_label.text = "ROUND %d / %d" % [
		current_round,
		MAX_ROUNDS
	]
	
	
	# 1-5   = 3 inputs
	# 6-10  = 4 inputs
	# 11-15 = 5 inputs
	# 16-20 = 6 inputs
	
	var difficulty_increase: int = int(
		float(current_round - 1)
		/ float(ROUNDS_PER_DIFFICULTY_INCREASE)
	)
	
	
	var sequence_length: int = (
		STARTING_SEQUENCE_LENGTH
		+ difficulty_increase
	)
	
	
	generate_sequence(sequence_length)
	
	
	await get_tree().create_timer(0.5).timeout
	
	
	await show_sequence()


# --------------------------------------------------
# GENERATE SEQUENCE
# --------------------------------------------------

func generate_sequence(length: int) -> void:
	
	sequence.clear()
	
	var previous_tile: int = -1
	
	
	for i in range(length):
		
		var random_tile: int = randi_range(0, 3)
		
		
		# Prevent consecutive identical tiles.
		while random_tile == previous_tile:
			random_tile = randi_range(0, 3)
		
		
		sequence.append(random_tile)
		
		previous_tile = random_tile
	
	
	print("Sequence: ", sequence)


# --------------------------------------------------
# SHOW SEQUENCE
# --------------------------------------------------

func show_sequence() -> void:
	
	instruction_label.text = "WATCH"
	
	
	for button in tile_buttons:
		button.modulate = Color.WHITE
	
	
	for tile_index in sequence:
		
		await flash_tile(tile_index)
		
		await get_tree().create_timer(
			FLASH_GAP
		).timeout
	
	
	instruction_label.text = "GO!"
	
	
	round_start_usec = Time.get_ticks_usec()
	
	accepting_input = true


# --------------------------------------------------
# PLAYER INPUT
# --------------------------------------------------

func _on_tile_pressed(tile_index: int) -> void:
	
	if not accepting_input:
		return
	
	
	# --------------------------------------------------
	# FIRST INPUT / REACTION
	# --------------------------------------------------
	
	if current_input_index == 0 and first_input_usec == 0:
		
		first_input_usec = Time.get_ticks_usec()
		
		
		var reaction_ms: float = (
			first_input_usec - round_start_usec
		) / 1000.0
		
		
		reaction_times.append(reaction_ms)
		
		
		reaction_label.text = (
			"REACTION: %.0f ms"
			% reaction_ms
		)
	
	
	# --------------------------------------------------
	# EXPECTED INPUT
	# --------------------------------------------------
	
	var expected_tile: int = sequence[current_input_index]
	
	
	print(
		"Pressed: ",
		tile_index,
		" | Expected: ",
		expected_tile,
		" | Position: ",
		current_input_index
	)
	
	
	# --------------------------------------------------
	# WRONG INPUT
	# --------------------------------------------------
	
	if tile_index != expected_tile:
		
		mistakes_this_round += 1
		
		flash_wrong(tile_index)
		haptic_wrong()
		
		wrong_sound.play()
		
		show_wrong_message()
		
		return
	
	
	# --------------------------------------------------
	# CORRECT INPUT
	# --------------------------------------------------
	
	flash_correct(tile_index)
	haptic_correct()
	
	tile_click_sound.play()
	
	
	current_input_index += 1
	
	
	if current_input_index >= sequence.size():
		
		finish_round()


# --------------------------------------------------
# WRONG MESSAGE
# --------------------------------------------------

func show_wrong_message() -> void:
	
	wrong_message_version += 1
	
	var this_message_version: int = wrong_message_version
	
	
	instruction_label.text = "WRONG! +500 ms"
	
	
	await get_tree().create_timer(0.25).timeout
	
	
	if (
		accepting_input
		and this_message_version == wrong_message_version
	):
		
		instruction_label.text = "GO!"


# --------------------------------------------------
# FINISH ROUND
# --------------------------------------------------

func finish_round() -> void:
	
	accepting_input = false
	
	
	var finish_usec: int = Time.get_ticks_usec()
	
	
	var raw_time_ms: float = (
		finish_usec - round_start_usec
	) / 1000.0
	
	
	var penalty_ms: float = (
		mistakes_this_round
		* WRONG_PENALTY_MS
	)
	
	
	var final_time_ms: float = (
		raw_time_ms
		+ penalty_ms
	)
	
	
	# --------------------------------------------------
	# SESSION STATS
	# --------------------------------------------------
	
	total_time_ms += final_time_ms
	total_mistakes += mistakes_this_round
	
	
	# --------------------------------------------------
	# ROUND TIME
	# --------------------------------------------------
	
	time_label.text = (
		"TIME: %.0f ms"
		% final_time_ms
	)
	
	
	# --------------------------------------------------
	# SCORE
	# --------------------------------------------------
	
	var base_score: int = (
		sequence.size()
		* 1000
	)
	
	
	var speed_bonus: int = max(
		0,
		int(3000.0 - final_time_ms)
	)
	
	
	var round_score: int = (
		base_score
		+ speed_bonus
	)
	
	
	score += round_score
	
	
	score_label.text = (
		"SCORE: %d"
		% score
	)
	
	
	# --------------------------------------------------
	# PERFECT / MISTAKE
	# --------------------------------------------------
	
	if mistakes_this_round == 0:
		
		perfect_streak += 1
		
		instruction_label.text = "PERFECT"
		
		
		# Perfect sound is for completed sequences,
		# but NOT the final sequence of the run.
		
		if current_round < MAX_ROUNDS:
			perfect_sound.play()
		
		
		# Visual celebration still happens on Round 20.
		play_perfect_effect()
	
	
	else:
		
		perfect_streak = 0
		
		instruction_label.text = (
			"%d MISTAKE(S)"
			% mistakes_this_round
		)
	
	
	# --------------------------------------------------
	# END OF RUN
	# --------------------------------------------------
	
	if current_round >= MAX_ROUNDS:
		
		finish_session()
		return
	
	
	# --------------------------------------------------
	# CONTINUE RUN
	# --------------------------------------------------
	
	await get_tree().create_timer(1.0).timeout
	
	start_next_round()


# --------------------------------------------------
# FINISH SESSION
# --------------------------------------------------

func finish_session() -> void:
	
	game_running = false
	accepting_input = false
	
	
	# This is the only major celebration sound used
	# when the full 20-round run ends.
	end_run_sound.play()
	
	
	# --------------------------------------------------
	# CALCULATE STATS
	# --------------------------------------------------
	
	var average_reaction_ms: float = 0.0
	var fastest_reaction_ms: float = 0.0
	
	
	if reaction_times.size() > 0:
		
		var reaction_total: float = 0.0
		
		fastest_reaction_ms = reaction_times[0]
		
		
		for reaction in reaction_times:
			
			reaction_total += reaction
			
			
			if reaction < fastest_reaction_ms:
				
				fastest_reaction_ms = reaction
		
		
		average_reaction_ms = (
			reaction_total
			/ reaction_times.size()
		)
	
	
	# --------------------------------------------------
	# RESULTS
	# --------------------------------------------------
	
	round_label.text = "SESSION COMPLETE"
	
	
	instruction_label.text = (
		"FASTEST: %.0f ms\nMISTAKES: %d"
		% [
			fastest_reaction_ms,
			total_mistakes
		]
	)
	
	
	time_label.text = (
		"TOTAL TIME: %.3f s"
		% (total_time_ms / 1000.0)
	)
	
	
	reaction_label.text = (
		"AVG REACTION: %.0f ms"
		% average_reaction_ms
	)
	
	
	score_label.text = (
		"FINAL SCORE: %d"
		% score
	)
	
	
	start_button.text = "PLAY AGAIN"
	start_button.show()


# --------------------------------------------------
# PERFECT EFFECT
# --------------------------------------------------

func play_perfect_effect() -> void:
	
	if not is_instance_valid(perfect_label):
		create_perfect_fx()
	
	
	if not is_instance_valid(perfect_label):
		
		push_error("Perfect FX failed to initialise.")
		return
	
	
	# Sound deliberately DOES NOT happen here.
	#
	# finish_round() decides whether the correct
	# sound is PerfectSound or EndRunSound.
	
	haptic_perfect()
	
	
	var strength: float = min(
		1.0 + perfect_streak * 0.10,
		2.0
	)
	
	
	# --------------------------------------------------
	# PERFECT TEXT
	# --------------------------------------------------
	
	if perfect_streak <= 1:
		
		perfect_label.text = "PERFECT!"
	
	else:
		
		perfect_label.text = (
			"PERFECT ×%d!"
			% perfect_streak
		)
	
	
	perfect_label.modulate = Color.WHITE
	perfect_label.modulate.a = 0.0
	
	
	perfect_label.scale = Vector2(
		0.4,
		0.4
	)
	
	
	perfect_label.pivot_offset = (
		perfect_label.size / 2.0
	)
	
	
	# --------------------------------------------------
	# FULL-SCREEN FLASH
	# --------------------------------------------------
	
	var flash_colours: Array[Color] = [
		Color(1.0, 0.15, 0.35),
		Color(0.1, 0.9, 1.0),
		Color(1.0, 0.9, 0.1),
		Color(0.7, 0.2, 1.0),
		Color(0.1, 1.0, 0.45)
	]
	
	
	perfect_flash.color = flash_colours.pick_random()
	perfect_flash.modulate.a = 0.65
	
	
	var flash_tween := create_tween()
	
	
	flash_tween.tween_property(
		perfect_flash,
		"modulate:a",
		0.0,
		0.25
	)
	
	
	# --------------------------------------------------
	# TEXT PUNCH
	# --------------------------------------------------
	
	var text_tween := create_tween()
	
	text_tween.set_parallel(true)
	
	
	text_tween.tween_property(
		perfect_label,
		"modulate:a",
		1.0,
		0.05
	)
	
	
	text_tween.tween_property(
		perfect_label,
		"scale",
		Vector2(1.15, 1.15),
		0.12
	).set_trans(
		Tween.TRANS_BACK
	)
	
	
	await text_tween.finished
	
	
	var disappear_tween := create_tween()
	
	disappear_tween.set_parallel(true)
	
	
	disappear_tween.tween_property(
		perfect_label,
		"scale",
		Vector2(1.4, 1.4),
		0.35
	)
	
	
	disappear_tween.tween_property(
		perfect_label,
		"modulate:a",
		0.0,
		0.35
	)
	
	
	# --------------------------------------------------
	# PARTICLES
	# --------------------------------------------------
	
	spawn_perfect_particles(
		int(35 * strength)
	)
	
	
	# --------------------------------------------------
	# TILE PULSE
	# --------------------------------------------------
	
	for button in tile_buttons:
		
		button.modulate = Color(
			1.8,
			1.8,
			1.8,
			1.0
		)
		
		
		var tile_tween := create_tween()
		
		
		tile_tween.tween_property(
			button,
			"modulate",
			Color.WHITE,
			0.25
		)


# --------------------------------------------------
# PERFECT PARTICLES
# --------------------------------------------------

func spawn_perfect_particles(amount: int) -> void:
	
	if not is_instance_valid(perfect_fx_layer):
		return
	
	
	var viewport_size: Vector2 = get_viewport_rect().size
	
	var centre: Vector2 = (
		viewport_size / 2.0
	)
	
	
	var colours: Array[Color] = [
		Color(1.0, 0.15, 0.3),
		Color(0.0, 0.9, 1.0),
		Color(1.0, 0.85, 0.0),
		Color(0.65, 0.15, 1.0),
		Color(0.1, 1.0, 0.4),
		Color.WHITE
	]
	
	
	for i in range(amount):
		
		var particle := ColorRect.new()
		
		
		var particle_size: float = randf_range(
			10.0,
			30.0
		)
		
		
		particle.size = Vector2(
			particle_size,
			particle_size
		)
		
		
		particle.position = (
			centre
			- particle.size / 2.0
		)
		
		
		particle.pivot_offset = (
			particle.size / 2.0
		)
		
		
		particle.color = colours.pick_random()
		
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		
		particle.rotation = randf_range(
			0.0,
			TAU
		)
		
		
		perfect_fx_layer.add_child(particle)
		
		
		var angle: float = randf_range(
			0.0,
			TAU
		)
		
		
		var distance: float = randf_range(
			250.0,
			750.0
		)
		
		
		var target_position: Vector2 = (
			centre
			+ Vector2.RIGHT.rotated(angle)
			* distance
			- particle.size / 2.0
		)
		
		
		var tween := create_tween()
		
		tween.set_parallel(true)
		
		
		tween.tween_property(
			particle,
			"position",
			target_position,
			randf_range(0.35, 0.7)
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)
		
		
		tween.tween_property(
			particle,
			"rotation",
			particle.rotation
			+ randf_range(-6.0, 6.0),
			0.6
		)
		
		
		tween.tween_property(
			particle,
			"modulate:a",
			0.0,
			0.6
		)
		
		
		tween.finished.connect(
			particle.queue_free
		)


# --------------------------------------------------
# SEQUENCE FLASH
# --------------------------------------------------

func flash_tile(tile_index: int) -> void:
	
	var button: Button = tile_buttons[tile_index]
	
	
	button.modulate = Color(
		1.8,
		1.8,
		1.8,
		1.0
	)
	
	
	await get_tree().create_timer(
		FLASH_TIME
	).timeout
	
	
	button.modulate = Color.WHITE


# --------------------------------------------------
# CORRECT FLASH
# --------------------------------------------------

func flash_correct(tile_index: int) -> void:
	
	var button: Button = tile_buttons[tile_index]
	
	
	button.modulate = Color(
		0.5,
		1.5,
		0.5,
		1.0
	)
	
	
	var tween := create_tween()
	
	
	tween.tween_property(
		button,
		"modulate",
		Color.WHITE,
		0.10
	)


# --------------------------------------------------
# WRONG FLASH / SHAKE
# --------------------------------------------------

func flash_wrong(tile_index: int) -> void:
	
	var button: Button = tile_buttons[tile_index]
	
	
	button.modulate = Color(
		2.0,
		0.15,
		0.15,
		1.0
	)
	
	
	var original_position: Vector2 = button.position
	
	
	var tween := create_tween()
	
	
	tween.tween_property(
		button,
		"position:x",
		original_position.x - 10.0,
		0.025
	)
	
	
	tween.tween_property(
		button,
		"position:x",
		original_position.x + 10.0,
		0.05
	)
	
	
	tween.tween_property(
		button,
		"position:x",
		original_position.x,
		0.025
	)
	
	
	tween.parallel().tween_property(
		button,
		"modulate",
		Color.WHITE,
		0.15
	)


# --------------------------------------------------
# HAPTICS
# --------------------------------------------------

func haptic_correct() -> void:
	
	Input.vibrate_handheld(
		20,
		0.25
	)


func haptic_wrong() -> void:
	
	Input.vibrate_handheld(
		90,
		0.8
	)


func haptic_perfect() -> void:
	
	Input.vibrate_handheld(
		120,
		1.0
	)
