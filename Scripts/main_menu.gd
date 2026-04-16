extends Control

@onready var start_button: Button = $VBoxContainer/Start
@onready var options_button: Button = $VBoxContainer/Options
@onready var exit_button: Button = $VBoxContainer/Exit

var buttons: Array[Button] = []
var current_index: int = 0
var using_keyboard := false
var is_pressing := false

# Controller stick control
var stick_deadzone := 0.5
var stick_ready := true


func _ready() -> void:
	buttons = [start_button, options_button, exit_button]

	for i in range(buttons.size()):
		var button = buttons[i]
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_entered.connect(_on_button_mouse_entered.bind(i))

	_set_current_button(0)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	print("Controllers connected:", Input.get_connected_joypads())


func _input(event: InputEvent) -> void:
	# =========================
	# MOUSE
	# =========================
	if event is InputEventMouseMotion:
		if using_keyboard:
			using_keyboard = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	# =========================
	# KEYBOARD
	# =========================
	if event is InputEventKey and event.pressed and not event.echo:
		# Up
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			using_keyboard = true
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			_move_selection(-1)
			return

		# Down
		if event.keycode == KEY_S or event.keycode == KEY_DOWN:
			using_keyboard = true
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			_move_selection(1)
			return

		# Accept
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			using_keyboard = true
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			_press_current_button()
			return

		# =========================
		# DEBUG CONTROLLER SIMULATION
		# =========================
		if event.keycode == KEY_I:
			print("DEBUG: DPAD UP")
			_move_selection(-1)
			return

		if event.keycode == KEY_K:
			print("DEBUG: DPAD DOWN")
			_move_selection(1)
			return

		if event.keycode == KEY_J:
			print("DEBUG: A BUTTON")
			_press_current_button()
			return

	# =========================
	# CONTROLLER BUTTONS
	# =========================
	if event is InputEventJoypadButton and event.pressed:
		using_keyboard = true
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

		print("Controller button:", event.button_index)

		# D-pad up
		if event.button_index == JOY_BUTTON_DPAD_UP:
			_move_selection(-1)
			return

		# D-pad down
		if event.button_index == JOY_BUTTON_DPAD_DOWN:
			_move_selection(1)
			return

		# Confirm (A / Cross) → use index 0 for compatibility
		if event.button_index == 0:
			_press_current_button()
			return

	# =========================
	# CONTROLLER STICK
	# =========================
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		using_keyboard = true
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

		print("Stick:", event.axis_value)

		if stick_ready:
			if event.axis_value > stick_deadzone:
				stick_ready = false
				_move_selection(1)
				return
			elif event.axis_value < -stick_deadzone:
				stick_ready = false
				_move_selection(-1)
				return
		else:
			if abs(event.axis_value) < 0.2:
				stick_ready = true


# =========================
# MENU LOGIC
# =========================

func _move_selection(direction: int) -> void:
	if is_pressing:
		return

	var new_index := current_index + direction

	if new_index < 0:
		new_index = buttons.size() - 1
	elif new_index >= buttons.size():
		new_index = 0

	_set_current_button(new_index)


func _set_current_button(index: int) -> void:
	current_index = index

	for i in range(buttons.size()):
		var button = buttons[i]

		if i == current_index:
			_apply_selected_style(button)
		else:
			_apply_normal_style(button)


# =========================
# STYLES
# =========================

func _apply_normal_style(button: Button) -> void:
	button.modulate = Color(0.72, 0.72, 0.72, 1.0)
	button.scale = Vector2(1.0, 1.0)


func _apply_selected_style(button: Button) -> void:
	button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	button.scale = Vector2(1.03, 1.03)


func _apply_pressed_style(button: Button) -> void:
	button.modulate = Color(0.9, 0.9, 0.9, 1.0)
	button.scale = Vector2(0.97, 0.97)


# =========================
# PRESS HANDLING
# =========================

func _press_current_button() -> void:
	if is_pressing:
		return

	is_pressing = true
	var button := buttons[current_index]

	_apply_pressed_style(button)

	await get_tree().create_timer(0.08).timeout

	_set_current_button(current_index)
	is_pressing = false

	match current_index:
		0:
			_on_start_pressed()
		1:
			_on_options_pressed()
		2:
			_on_exit_pressed()


# =========================
# MOUSE SYNC
# =========================

func _on_button_mouse_entered(index: int) -> void:
	if is_pressing:
		return

	using_keyboard = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_current_button(index)


# =========================
# BUTTON ACTIONS
# =========================

func _on_start_pressed() -> void:
	print("START")
	get_tree().change_scene_to_file("res://Scenes/Levels/Lobby.tscn")


func _on_options_pressed() -> void:
	print("OPTIONS")


func _on_exit_pressed() -> void:
	print("EXIT")
	get_tree().quit()
