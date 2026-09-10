extends Node
## Astral Tide heroine interaction system.
## Keeps interactions flirty, playful and non-explicit while adding actual gameplay.

var player: Node3D
var heroines: Array[Node3D] = []
var active_heroine: Node3D
var prompt: Label
var panel: Panel
var title_label: Label
var body_label: Label
var stats_label: Label
var affection := {"Mira": 0, "Aya": 0}
var outfit_mode := {"Mira": 0, "Aya": 0}
var pose_time := 0.0
var toast_time := 0.0
var toast: Label

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	player = get_tree().current_scene.get_node_or_null("CharacterBody3D")
	if player == null:
		return
	for node_name in ["Mira", "Aya"]:
		var n := get_tree().current_scene.get_node_or_null(node_name)
		if n is Node3D:
			heroines.append(n)
	_build_ui()
	set_process(true)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HeroineInteractionUI"
	get_tree().current_scene.add_child.call_deferred(layer)
	prompt = Label.new()
	prompt.position = Vector2(34, 620)
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.text = ""
	layer.add_child(prompt)
	panel = Panel.new()
	panel.position = Vector2(34, 430)
	panel.size = Vector2(470, 175)
	panel.visible = false
	layer.add_child(panel)
	title_label = Label.new()
	title_label.position = Vector2(18, 12)
	title_label.add_theme_font_size_override("font_size", 28)
	panel.add_child(title_label)
	body_label = Label.new()
	body_label.position = Vector2(18, 52)
	body_label.size = Vector2(430, 82)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 17)
	panel.add_child(body_label)
	stats_label = Label.new()
	stats_label.position = Vector2(18, 138)
	stats_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(stats_label)
	toast = Label.new()
	toast.position = Vector2(470, 35)
	toast.add_theme_font_size_override("font_size", 20)
	layer.add_child(toast)

func _process(delta: float) -> void:
	if player == null:
		return
	pose_time += delta
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast.text = ""
	var nearest := _nearest_heroine()
	if nearest != null:
		active_heroine = nearest
		var name := nearest.name
		prompt.text = "[E] Talk  [F] Flirty pose  [G] Outfit  •  %s" % name
		if Input.is_key_pressed(KEY_E):
			# Edge-ish guard: opening the panel is harmless even if held.
			if not panel.visible:
				_open_dialogue(name)
		if Input.is_key_pressed(KEY_F) and not panel.visible:
			_pose(name)
		if Input.is_key_pressed(KEY_G) and not panel.visible:
			_cycle_outfit(name)
	else:
		active_heroine = null
		prompt.text = ""
		if panel.visible:
			panel.visible = false

func _nearest_heroine() -> Node3D:
	var best: Node3D
	var best_dist := 3.6
	for h in heroines:
		if not is_instance_valid(h):
			continue
		var d := player.global_position.distance_to(h.global_position)
		if d < best_dist:
			best = h
			best_dist = d
	return best

func _open_dialogue(name: String) -> void:
	affection[name] = mini(affection.get(name, 0) + 1, 100)
	var lines: Array[String]
	if name == "Mira":
		lines = ["Mira: You finally made it. I was starting to think you were lost. ✦", "Mira: Stay a little. The tide is gorgeous tonight.", "Mira: Nice look. Don't get too distracted, captain."]
	else:
		lines = ["Aya: There you are. Want to explore the shrine with me?", "Aya: The sea breeze suits you. Let's make this trip memorable.", "Aya: I saved a little beach route for us. Follow me."]
	var index := affection[name] % lines.size()
	title_label.text = name + "  ✦"
	body_label.text = lines[index]
	stats_label.text = "Bond %d/100   •   [Enter] close   •   [G] change beach style" % affection[name]
	panel.visible = true

func _input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
			panel.visible = false
			get_viewport().set_input_as_handled()

func _pose(name: String) -> void:
	toast.text = name + " strikes a confident beach pose ✦"
	toast_time = 2.2
	# A subtle scale pulse gives feedback without requiring animation assets.
	var h := active_heroine
	if h:
		var original := h.scale
		var tw := create_tween()
		tw.tween_property(h, "scale", original * 1.045, 0.16)
		tw.tween_property(h, "scale", original, 0.24)

func _cycle_outfit(name: String) -> void:
	outfit_mode[name] = (outfit_mode.get(name, 0) + 1) % 3
	var mode: int = outfit_mode[name]
	# Change the accent material on visible mesh pieces. Each mode is a tasteful
	# original beachwear palette; no copyrighted costume is referenced.
	var h := active_heroine
	if h == null:
		return
	var accent := Color("#ff4fa3") if name == "Mira" else Color("#8d6bff")
	if mode == 1:
		accent = Color("#20d7c7")
	elif mode == 2:
		accent = Color("#ffd166")
	_apply_accent(h, accent)
	var labels := ["Default Astral bikini", "Ocean-glow bikini", "Sunset-glow bikini"]
	toast.text = name + " • " + labels[mode]
	toast_time = 2.5

func _apply_accent(root: Node, color: Color) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
			var mat := mesh.material_override
			if mat is StandardMaterial3D:
				var m := (mat as StandardMaterial3D).duplicate()
				m.albedo_color = color
				if m.emission_enabled:
					m.emission = color
				mesh.material_override = m
		_apply_accent_children(root, color)

func _apply_accent_children(root: Node, color: Color) -> void:
	for child in root.get_children():
		if child is Node:
			if child.get_child_count() > 0:
				_apply_accent_children(child, color)
			elif child is MeshInstance3D:
				var mesh := child as MeshInstance3D
				if mesh.material_override is StandardMaterial3D:
					var m := (mesh.material_override as StandardMaterial3D).duplicate()
					m.albedo_color = color
					mesh.material_override = m
