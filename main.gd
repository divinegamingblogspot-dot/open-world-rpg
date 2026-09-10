extends Node3D

# Neon Isles: Summer Quest
# A self-contained, original, procedural 3D mobile RPG prototype.
# All geometry is generated at runtime, so the repository stays tiny.

const WORLD_SIZE := 150.0
const WATER_Y := -1.0
const PLAYER_SPEED := 7.0
const SPRINT_SPEED := 12.0
const ATTACK_RANGE := 4.2
const ATTACK_DAMAGE := 35
const ENEMY_COUNT := 12

var player: CharacterBody3D
var camera: Camera3D
var enemies: Array[CharacterBody3D] = []
var coins := 0
var crystals := 0
var hp := 100
var stamina := 100.0
var attacking := false
var attack_cooldown := 0.0
var game_time := 0.0
var quest_done := false
var toast_timer := 0.0
var hud: Label
var quest_label: Label
var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var joystick := Vector2.ZERO
var sprint_pressed := false

func _ready() -> void:
    _build_world()
    _build_player()
    _build_camera()
    _build_enemies()
    _build_npcs()
    _build_hud()
    _toast("Welcome to Neon Isles! Collect 5 crystals.")

func _process(delta: float) -> void:
    game_time += delta
    attack_cooldown = max(0.0, attack_cooldown - delta)
    toast_timer = max(0.0, toast_timer - delta)
    _update_player(delta)
    _update_enemies(delta)
    _update_camera(delta)
    _update_hud()
    if toast_timer <= 0.0 and quest_done:
        quest_done = false

func _physics_process(_delta: float) -> void:
    if player and not player.is_on_floor():
        player.velocity.y -= 20.0 * _delta

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#89d7ff")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#d8efff")
    environment.ambient_light_energy = 0.75
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -25, 0)
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    add_child(sun)

    _make_box("Water", Vector3(WORLD_SIZE * 1.8, 0.6, WORLD_SIZE * 1.8), Vector3(0, WATER_Y, 0), Color("#46b8e8"), false)

    # Main island, beach and raised central plateau.
    _make_cylinder("Island", 65.0, 2.0, Vector3(0, 0, 0), Color("#79c85a"))
    _make_cylinder("Beach", 58.0, 0.7, Vector3(0, 0.5, 0), Color("#f4d58a"))
    _make_cylinder("Grass", 51.0, 1.0, Vector3(0, 1.0, 0), Color("#5cab4e"))
    _make_cylinder("Mountain", 24.0, 5.0, Vector3(0, 3.5, -4), Color("#8a9b78"))

    # Ruins / landmarks.
    for i in range(8):
        var angle := float(i) * TAU / 8.0
        var p := Vector3(cos(angle) * 35.0, 2.0, sin(angle) * 35.0)
        _make_box("Ruin", Vector3(2.0, 7.0, 2.0), p, Color("#d6d0bf"), true)
        _make_box("RuinCap", Vector3(3.5, 0.8, 3.5), p + Vector3(0, 3.8, 0), Color("#b7b09f"), false)

    # Palm trees.
    for i in range(18):
        var angle := float(i) * TAU / 18.0 + 0.25
        var radius := 44.0 + float(i % 3) * 3.0
        _make_palm(Vector3(cos(angle) * radius, 1.0, sin(angle) * radius))

    # Crystal pickups.
    for i in range(8):
        var angle := float(i) * TAU / 8.0 + 0.4
        var p := Vector3(cos(angle) * 28.0, 4.0, sin(angle) * 28.0)
        _make_crystal(p)

func _make_box(n: String, size: Vector3, pos: Vector3, color: Color, collision := true) -> Node3D:
    var body: Node3D = StaticBody3D.new() if collision else Node3D.new()
    body.name = n
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = _mat(color)
    body.add_child(mesh)
    if collision:
        var shape := CollisionShape3D.new()
        var cs := BoxShape3D.new()
        cs.size = size
        shape.shape = cs
        body.add_child(shape)
    add_child(body)
    return body

func _make_cylinder(n: String, radius: float, height: float, pos: Vector3, color: Color) -> Node3D:
    var body := StaticBody3D.new()
    body.name = n
    body.position = pos
    var mesh := MeshInstance3D.new()
    var cyl := CylinderMesh.new()
    cyl.top_radius = radius
    cyl.bottom_radius = radius
    cyl.height = height
    cyl.radial_segments = 64
    mesh.mesh = cyl
    mesh.material_override = _mat(color)
    body.add_child(mesh)
    var shape := CollisionShape3D.new()
    var cs := CylinderShape3D.new()
    cs.radius = radius
    cs.height = height
    shape.shape = cs
    body.add_child(shape)
    add_child(body)
    return body

func _make_palm(pos: Vector3) -> void:
    _make_cylinder("PalmTrunk", 0.55, 8.0, pos + Vector3(0, 4, 0), Color("#8b633b"))
    for j in range(7):
        var a := float(j) * TAU / 7.0
        var leaf_pos := pos + Vector3(cos(a) * 2.8, 8.0, sin(a) * 2.8)
        _make_box("PalmLeaf", Vector3(5.5, 0.25, 0.9), leaf_pos, Color("#2d9b54"), false).rotation.y = -a

func _make_crystal(pos: Vector3) -> void:
    var area := Area3D.new()
    area.name = "Crystal"
    area.position = pos
    area.set_meta("collected", false)
    var mesh := MeshInstance3D.new()
    var s := PrismMesh.new()
    s.size = Vector3(1.1, 3.0, 1.1)
    mesh.mesh = s
    mesh.material_override = _mat(Color("#c65cff"), true)
    mesh.rotation_degrees = Vector3(0, 20, 15)
    area.add_child(mesh)
    var shape := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 2.0
    shape.shape = sphere
    area.add_child(shape)
    area.body_entered.connect(func(body):
        if body == player and not area.get_meta("collected"):
            area.set_meta("collected", true)
            crystals += 1
            coins += 25
            area.queue_free()
            if crystals >= 5:
                quest_done = true
                _toast("Quest complete! 5 crystals collected. +125 coins!")
            else:
                _toast("Crystal collected! %d / 5" % crystals)
    )
    add_child(area)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 3.0, 18)
    add_child(player)

    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.55
    capsule.height = 2.6
    shape.shape = capsule
    player.add_child(shape)

    # Original stylized anime-inspired adventurer, adult character.
    var body := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.55
    body_mesh.height = 1.8
    body.mesh = body_mesh
    body.position.y = 1.35
    body.material_override = _mat(Color("#f1b59b"))
    player.add_child(body)

    var outfit := MeshInstance3D.new()
    var outfit_mesh := CylinderMesh.new()
    outfit_mesh.top_radius = 0.78
    outfit_mesh.bottom_radius = 0.95
    outfit_mesh.height = 1.45
    outfit.mesh = outfit_mesh
    outfit.position.y = 1.15
    outfit.material_override = _mat(Color("#2d4cff"))
    player.add_child(outfit)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.58
    head_mesh.height = 1.16
    head.mesh = head_mesh
    head.position.y = 2.65
    head.material_override = _mat(Color("#f1b59b"))
    player.add_child(head)

    var hair := MeshInstance3D.new()
    var hair_mesh := SphereMesh.new()
    hair_mesh.radius = 0.66
    hair_mesh.height = 1.25
    hair.mesh = hair_mesh
    hair.position = Vector3(0, 2.88, -0.13)
    hair.scale = Vector3(1.0, 1.0, 0.78)
    hair.material_override = _mat(Color("#2b173b"))
    player.add_child(hair)

    # Sword.
    var sword := MeshInstance3D.new()
    var sword_mesh := BoxMesh.new()
    sword_mesh.size = Vector3(0.18, 2.5, 0.42)
    sword.mesh = sword_mesh
    sword.position = Vector3(0.9, 1.5, 0.0)
    sword.rotation_degrees = Vector3(0, 0, -18)
    sword.material_override = _mat(Color("#dff6ff"), true)
    player.add_child(sword)

func _build_camera() -> void:
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 68
    add_child(camera)

func _update_camera(_delta: float) -> void:
    if not player:
        return
    var target := player.global_position + Vector3(0, 2.0, 0)
    var desired := target + Vector3(0, 7.5, 11.0)
    camera.global_position = camera.global_position.lerp(desired, 0.12)
    camera.look_at(target, Vector3.UP)

func _update_player(delta: float) -> void:
    if not player:
        return
    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if joystick.length() > 0.05:
        input_vec = joystick
    var speed := SPRINT_SPEED if sprint_pressed or Input.is_action_pressed("sprint") else PLAYER_SPEED
    if input_vec.length() > 0.05:
        var dir := Vector3(input_vec.x, 0, input_vec.y)
        # Camera-relative movement.
        var basis := camera.global_transform.basis
        var forward := -basis.z
        var right := basis.x
        forward.y = 0
        right.y = 0
        forward = forward.normalized()
        right = right.normalized()
        var world_dir := (right * dir.x + forward * dir.z).normalized()
        player.velocity.x = world_dir.x * speed
        player.velocity.z = world_dir.z * speed
        player.look_at(player.global_position + Vector3(world_dir.x, 0, world_dir.z), Vector3.UP)
    else:
        player.velocity.x = move_toward(player.velocity.x, 0, 35 * delta)
        player.velocity.z = move_toward(player.velocity.z, 0, 35 * delta)
    if Input.is_action_just_pressed("attack"):
        _attack()
    if Input.is_action_just_pressed("sprint") and player.is_on_floor():
        player.velocity.y = 8.5
    player.move_and_slide()
    stamina = move_toward(stamina, 100.0, 18.0 * delta)

func _attack() -> void:
    if attack_cooldown > 0.0 or attacking:
        return
    attacking = true
    attack_cooldown = 0.55
    var closest: CharacterBody3D = null
    var closest_dist := ATTACK_RANGE
    for enemy in enemies:
        if is_instance_valid(enemy):
            var d := player.global_position.distance_to(enemy.global_position)
            if d < closest_dist:
                closest_dist = d
                closest = enemy
    if closest:
        var enemy_hp: int = int(closest.get_meta("hp", 100))
        enemy_hp -= ATTACK_DAMAGE
        closest.set_meta("hp", enemy_hp)
        coins += 5
        _toast("Slash! +5 coins")
        if enemy_hp <= 0:
            coins += 50
            _toast("Enemy defeated! +50 coins")
            enemies.erase(closest)
            closest.queue_free()
    await get_tree().create_timer(0.22).timeout
    attacking = false

func _build_enemies() -> void:
    for i in range(ENEMY_COUNT):
        var angle := float(i) * TAU / ENEMY_COUNT
        var radius := 22.0 + float(i % 4) * 7.0
        _spawn_enemy(Vector3(cos(angle) * radius, 2.3, sin(angle) * radius))

func _spawn_enemy(pos: Vector3) -> void:
    var enemy := CharacterBody3D.new()
    enemy.name = "Shade"
    enemy.position = pos
    enemy.set_meta("hp", 100)
    enemy.set_meta("hit_timer", 0.0)
    add_child(enemy)
    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.65
    capsule.height = 2.2
    shape.shape = capsule
    enemy.add_child(shape)
    var body := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.65
    mesh.height = 2.2
    body.mesh = mesh
    body.material_override = _mat(Color("#47265f"), true)
    body.position.y = 1.2
    enemy.add_child(body)
    var eye := MeshInstance3D.new()
    var eye_mesh := SphereMesh.new()
    eye_mesh.radius = 0.18
    eye_mesh.height = 0.36
    eye.mesh = eye_mesh
    eye.position = Vector3(0, 1.7, -0.58)
    eye.material_override = _mat(Color("#ff4f85"), true)
    enemy.add_child(eye)
    enemies.append(enemy)

func _update_enemies(delta: float) -> void:
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
            continue
        var dist := enemy.global_position.distance_to(player.global_position)
        var hit_timer := float(enemy.get_meta("hit_timer", 0.0))
        hit_timer -= delta
        enemy.set_meta("hit_timer", hit_timer)
        if dist < 24.0 and dist > 2.5:
            var dir := (player.global_position - enemy.global_position).normalized()
            enemy.velocity.x = dir.x * 2.5
            enemy.velocity.z = dir.z * 2.5
            enemy.look_at(enemy.global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
            enemy.move_and_slide()
        else:
            enemy.velocity.x = 0
            enemy.velocity.z = 0
        if dist < 2.6 and hit_timer <= 0.0:
            hp = max(0, hp - 8)
            enemy.set_meta("hit_timer", 1.2)
            _toast("Ouch! Shade attack -8 HP")
            if hp <= 0:
                hp = 100
                player.position = Vector3(0, 3, 18)
                coins = max(0, coins - 25)
                _toast("You were knocked out. -25 coins")

func _build_npcs() -> void:
    # Adult NPCs with original anime-inspired styling and summer outfits.
    _spawn_npc(Vector3(8, 2, 25), "Mira", Color("#ff6fae"), Color("#ffe6ef"), "Summer beach skin")
    _spawn_npc(Vector3(-12, 2, 26), "Aya", Color("#7c68ff"), Color("#fff0a8"), "Island guide")

func _spawn_npc(pos: Vector3, npc_name: String, hair_color: Color, outfit_color: Color, title: String) -> void:
    var npc := Node3D.new()
    npc.name = npc_name
    npc.position = pos
    add_child(npc)
    var body := MeshInstance3D.new()
    var bm := CapsuleMesh.new()
    bm.radius = 0.58
    bm.height = 1.8
    body.mesh = bm
    body.position.y = 1.25
    body.material_override = _mat(Color("#f0b59d"))
    npc.add_child(body)
    var outfit := MeshInstance3D.new()
    var om := CylinderMesh.new()
    om.top_radius = 0.72
    om.bottom_radius = 0.9
    om.height = 1.25
    outfit.mesh = om
    outfit.position.y = 1.1
    outfit.material_override = _mat(outfit_color)
    npc.add_child(outfit)
    var head := MeshInstance3D.new()
    var hm := SphereMesh.new()
    hm.radius = 0.58
    hm.height = 1.16
    head.mesh = hm
    head.position.y = 2.55
    head.material_override = _mat(Color("#f0b59d"))
    npc.add_child(head)
    var hair := MeshInstance3D.new()
    var h := SphereMesh.new()
    h.radius = 0.66
    h.height = 1.25
    hair.mesh = h
    hair.position = Vector3(0, 2.75, -0.1)
    hair.scale = Vector3(1.05, 1.0, 0.8)
    hair.material_override = _mat(hair_color)
    npc.add_child(hair)
    var label := Label3D.new()
    label.text = npc_name + "\n" + title
    label.position.y = 3.8
    label.font_size = 28
    label.modulate = Color.WHITE
    npc.add_child(label)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)

    hud = Label.new()
    hud.position = Vector2(24, 20)
    hud.add_theme_font_size_override("font_size", 28)
    layer.add_child(hud)

    quest_label = Label.new()
    quest_label.position = Vector2(24, 105)
    quest_label.add_theme_font_size_override("font_size", 22)
    quest_label.text = "QUEST: Collect 5 crystals"
    layer.add_child(quest_label)

    hp_bar = ProgressBar.new()
    hp_bar.position = Vector2(24, 68)
    hp_bar.size = Vector2(300, 24)
    hp_bar.max_value = 100
    hp_bar.value = hp
    layer.add_child(hp_bar)

    stamina_bar = ProgressBar.new()
    stamina_bar.position = Vector2(24, 95)
    stamina_bar.size = Vector2(300, 12)
    stamina_bar.max_value = 100
    stamina_bar.value = stamina
    layer.add_child(stamina_bar)

    _button(layer, "◀", Vector2(34, 560), Vector2(78, 78), func(): joystick.x = -1)
    _button(layer, "▶", Vector2(210, 560), Vector2(78, 78), func(): joystick.x = 1)
    _button(layer, "▲", Vector2(122, 515), Vector2(78, 78), func(): joystick.y = -1)
    _button(layer, "▼", Vector2(122, 605), Vector2(78, 78), func(): joystick.y = 1)
    _button(layer, "ATTACK", Vector2(1030, 530), Vector2(190, 90), func(): _attack())
    _button(layer, "SPRINT", Vector2(900, 620), Vector2(160, 65), func(): sprint_pressed = true)

func _button(layer: CanvasLayer, text: String, pos: Vector2, size: Vector2, pressed: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = size
    b.modulate = Color(1, 1, 1, 0.82)
    b.add_theme_font_size_override("font_size", 24)
    b.button_down.connect(pressed)
    b.button_up.connect(func():
        joystick = Vector2.ZERO
        sprint_pressed = false
    )
    layer.add_child(b)

func _update_hud() -> void:
    if not hud:
        return
    hud.text = "NEON ISLES\n❤ %d/100    ✦ %d    ◆ %d" % [hp, coins, crystals]
    hp_bar.value = hp
    stamina_bar.value = stamina
    if quest_done:
        quest_label.text = "QUEST COMPLETE! Explore the island."
    else:
        quest_label.text = "QUEST: Collect 5 crystals (%d/5)" % crystals

func _toast(message: String) -> void:
    toast_timer = 3.0
    if not hud:
        return
    var old := hud.text
    hud.text = old + "\n\n" + message
    await get_tree().create_timer(2.7).timeout
    if is_instance_valid(hud) and toast_timer <= 0.3:
        _update_hud()

func _mat(color: Color, glow := false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.65
    if glow:
        m.emission_enabled = true
        m.emission = color * 0.65
        m.emission_energy_multiplier = 1.8
    return m
