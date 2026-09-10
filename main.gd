extends Node3D

const SPEED: float = 7.0
const SPRINT: float = 11.0
const ATTACK_RANGE: float = 4.0

var player: CharacterBody3D
var camera: Camera3D
var enemies: Array[CharacterBody3D] = []
var hp: int = 100
var coins: int = 0
var crystals: int = 0
var stamina: float = 100.0
var attacking: bool = false
var attack_cd: float = 0.0
var joystick: Vector2 = Vector2.ZERO
var sprint_down: bool = false
var status_label: Label
var quest_label: Label
var hp_bar: ProgressBar

func _ready() -> void:
    _build_world()
    _build_player()
    _build_camera()
    _build_enemies()
    _build_npcs()
    _build_hud()
    _toast("NEON ISLES • Find 5 crystals")

func _process(delta: float) -> void:
    attack_cd = maxf(0.0, attack_cd - delta)
    _update_player(delta)
    _update_enemies(delta)
    _update_camera()
    _update_hud()

func _physics_process(delta: float) -> void:
    if player and not player.is_on_floor():
        player.velocity.y -= 22.0 * delta

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color("#86d9ff")
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color("#e8f6ff")
    e.ambient_light_energy = 0.8
    env.environment = e
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
    sun.light_energy = 1.4
    sun.shadow_enabled = true
    add_child(sun)
    _box(Vector3(300, 0.5, 300), Vector3(0, -1.2, 0), Color("#35a9d6"), false)
    _cylinder(65.0, 2.0, Vector3.ZERO, Color("#78c957"))
    _cylinder(58.0, 0.8, Vector3(0, 0.7, 0), Color("#f3d48a"))
    _cylinder(50.0, 1.0, Vector3(0, 1.5, 0), Color("#58b34d"))
    _cylinder(22.0, 5.0, Vector3(0, 4.0, -5), Color("#879879"))
    for i in range(12):
        var a: float = float(i) * TAU / 12.0
        _palm(Vector3(cos(a) * 43.0, 1.0, sin(a) * 43.0))
    for i in range(7):
        var a: float = float(i) * TAU / 7.0 + 0.3
        _crystal(Vector3(cos(a) * 27.0, 4.0, sin(a) * 27.0))
    for i in range(8):
        var a: float = float(i) * TAU / 8.0
        _box(Vector3(2.0, 6.0, 2.0), Vector3(cos(a) * 34.0, 2.0, sin(a) * 34.0), Color("#d2ccbd"), true)

func _box(size: Vector3, pos: Vector3, color: Color, collision: bool) -> Node3D:
    var n: Node3D = StaticBody3D.new() if collision else Node3D.new()
    n.position = pos
    var m := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    m.mesh = mesh
    m.material_override = _mat(color)
    n.add_child(m)
    if collision:
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        cs.shape = shape
        n.add_child(cs)
    add_child(n)
    return n

func _cylinder(radius: float, height: float, pos: Vector3, color: Color) -> void:
    var n := StaticBody3D.new()
    n.position = pos
    var m := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 48
    m.mesh = mesh
    m.material_override = _mat(color)
    n.add_child(m)
    var cs := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = radius
    shape.height = height
    cs.shape = shape
    n.add_child(cs)
    add_child(n)

func _palm(pos: Vector3) -> void:
    _box(Vector3(0.8, 8.0, 0.8), pos + Vector3(0, 4, 0), Color("#875d36"), false)
    for j in range(6):
        var a: float = float(j) * TAU / 6.0
        var leaf := _box(Vector3(5.0, 0.22, 0.8), pos + Vector3(cos(a) * 2.5, 8.0, sin(a) * 2.5), Color("#269653"), false)
        leaf.rotation.y = -a

func _crystal(pos: Vector3) -> void:
    var area := Area3D.new()
    area.position = pos
    var m := MeshInstance3D.new()
    var mesh := PrismMesh.new()
    mesh.size = Vector3(1.2, 3.0, 1.2)
    m.mesh = mesh
    m.material_override = _mat(Color("#cf55ff"), true)
    m.rotation_degrees = Vector3(0, 25, 15)
    area.add_child(m)
    var cs := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 1.8
    cs.shape = shape
    area.add_child(cs)
    area.body_entered.connect(func(body: Node3D) -> void:
        if body == player and is_instance_valid(area):
            crystals += 1
            coins += 25
            area.queue_free()
            _toast("Crystal %d / 5  •  +25 coins" % crystals)
    )
    add_child(area)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.position = Vector3(0, 3, 18)
    add_child(player)
    var cs := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.55
    shape.height = 2.6
    cs.shape = shape
    player.add_child(cs)
    _character_visual(player, Color("#35d7ff"), Color("#f3b49f"), Color("#18275f"))

func _character_visual(root: Node3D, outfit: Color, skin: Color, hair: Color) -> void:
    # Stylized adult anime heroine: summer-bikini battle outfit, long hair, boots and accessories.
    var torso := MeshInstance3D.new()
    var tm := CapsuleMesh.new()
    tm.radius = 0.46
    tm.height = 1.15
    torso.mesh = tm
    torso.position = Vector3(0, 1.65, 0)
    torso.material_override = _mat(skin)
    root.add_child(torso)

    # Bikini top.
    for side in [-1.0, 1.0]:
        var cup := MeshInstance3D.new()
        var cm := SphereMesh.new()
        cm.radius = 0.28
        cm.height = 0.48
        cup.mesh = cm
        cup.scale = Vector3(1.0, 0.72, 0.48)
        cup.position = Vector3(0.23 * side, 1.72, -0.38)
        cup.material_override = _mat(outfit)
        root.add_child(cup)
    var top_band := MeshInstance3D.new()
    var band_mesh := BoxMesh.new()
    band_mesh.size = Vector3(0.78, 0.10, 0.12)
    top_band.mesh = band_mesh
    top_band.position = Vector3(0, 1.62, -0.39)
    top_band.material_override = _mat(outfit)
    root.add_child(top_band)

    # Bikini bottom.
    var bottom := MeshInstance3D.new()
    var bottom_mesh := BoxMesh.new()
    bottom_mesh.size = Vector3(0.62, 0.22, 0.34)
    bottom.mesh = bottom_mesh
    bottom.position = Vector3(0, 1.12, -0.10)
    bottom.material_override = _mat(outfit)
    root.add_child(bottom)

    # Long anime-style legs.
    for side in [-1.0, 1.0]:
        var leg := MeshInstance3D.new()
        var lm := CapsuleMesh.new()
        lm.radius = 0.19
        lm.height = 1.45
        leg.mesh = lm
        leg.position = Vector3(0.23 * side, 0.52, 0)
        leg.material_override = _mat(skin)
        root.add_child(leg)
        var boot := MeshInstance3D.new()
        var bm := CapsuleMesh.new()
        bm.radius = 0.23
        bm.height = 0.55
        boot.mesh = bm
        boot.position = Vector3(0.23 * side, 0.05, -0.07)
        boot.rotation_degrees.x = -12
        boot.material_override = _mat(Color("#25284f"))
        root.add_child(boot)

    # Arms with gloves.
    for side in [-1.0, 1.0]:
        var arm := MeshInstance3D.new()
        var am := CapsuleMesh.new()
        am.radius = 0.14
        am.height = 1.05
        arm.mesh = am
        arm.position = Vector3(0.62 * side, 1.55, 0)
        arm.rotation_degrees.z = -12.0 * side
        arm.material_override = _mat(skin)
        root.add_child(arm)
        var glove := MeshInstance3D.new()
        var gm := SphereMesh.new()
        gm.radius = 0.18
        gm.height = 0.36
        glove.mesh = gm
        glove.position = Vector3(0.68 * side, 1.03, -0.02)
        glove.material_override = _mat(Color("#25284f"))
        root.add_child(glove)

    # Head and face.
    var head := MeshInstance3D.new()
    var hm := SphereMesh.new()
    hm.radius = 0.56
    hm.height = 1.12
    head.mesh = hm
    head.position = Vector3(0, 2.65, 0)
    head.material_override = _mat(skin)
    root.add_child(head)

    # Hair cap + side locks + ponytails.
    var hair_cap := MeshInstance3D.new()
    var hh := SphereMesh.new()
    hh.radius = 0.65
    hh.height = 1.28
    hair_cap.mesh = hh
    hair_cap.position = Vector3(0, 2.78, 0.08)
    hair_cap.scale = Vector3(1.05, 1.05, 0.82)
    hair_cap.material_override = _mat(hair)
    root.add_child(hair_cap)
    for side in [-1.0, 1.0]:
        var lock := MeshInstance3D.new()
        var lock_mesh := CapsuleMesh.new()
        lock_mesh.radius = 0.14
        lock_mesh.height = 1.15
        lock.mesh = lock_mesh
        lock.position = Vector3(0.53 * side, 2.42, -0.02)
        lock.rotation_degrees.z = 14.0 * side
        lock.material_override = _mat(hair)
        root.add_child(lock)
        var pony := MeshInstance3D.new()
        var pony_mesh := CapsuleMesh.new()
        pony_mesh.radius = 0.20
        pony_mesh.height = 0.95
        pony.mesh = pony_mesh
        pony.position = Vector3(0.52 * side, 2.60, 0.34)
        pony.rotation_degrees.z = 24.0 * side
        pony.material_override = _mat(hair)
        root.add_child(pony)

    # Large stylized anime eyes.
    for side in [-1.0, 1.0]:
        var eye := MeshInstance3D.new()
        var em := SphereMesh.new()
        em.radius = 0.105
        em.height = 0.21
        eye.mesh = em
        eye.position = Vector3(0.20 * side, 2.67, -0.505)
        eye.scale = Vector3(1.0, 1.35, 0.45)
        eye.material_override = _mat(Color("#7eecff"), true)
        root.add_child(eye)

    # Hair ribbon and glowing shoulder accents.
    for side in [-1.0, 1.0]:
        var ribbon := MeshInstance3D.new()
        var rm := BoxMesh.new()
        rm.size = Vector3(0.28, 0.08, 0.18)
        ribbon.mesh = rm
        ribbon.position = Vector3(0.49 * side, 2.86, 0.32)
        ribbon.material_override = _mat(outfit, true)
        root.add_child(ribbon)

func _build_camera() -> void:
    camera = Camera3D.new()
    camera.fov = 68.0
    camera.current = true
    camera.position = Vector3(0, 7, 29)
    add_child(camera)

func _update_camera() -> void:
    if player:
        var target := player.global_position + Vector3(0, 1.8, 0)
        var desired := target + Vector3(0, 7.0, 11.0)
        camera.global_position = camera.global_position.lerp(desired, 0.12)
        camera.look_at(target, Vector3.UP)

func _update_player(delta: float) -> void:
    var v := Input.get_vector("left", "right", "forward", "back")
    if joystick.length() > 0.05:
        v = joystick
    var speed: float = SPRINT if sprint_down else SPEED
    if v.length() > 0.05:
        var forward := -camera.global_transform.basis.z
        var right := camera.global_transform.basis.x
        forward.y = 0
        right.y = 0
        var dir := (right.normalized() * v.x + forward.normalized() * v.y).normalized()
        player.velocity.x = dir.x * speed
        player.velocity.z = dir.z * speed
        player.look_at(player.global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
    else:
        player.velocity.x = move_toward(player.velocity.x, 0, 30.0 * delta)
        player.velocity.z = move_toward(player.velocity.z, 0, 30.0 * delta)
    if Input.is_action_just_pressed("attack"):
        _attack()
    player.move_and_slide()

func _attack() -> void:
    if attack_cd > 0.0 or attacking:
        return
    attacking = true
    attack_cd = 0.5
    var target: CharacterBody3D = null
    var best: float = ATTACK_RANGE
    for enemy in enemies:
        if is_instance_valid(enemy):
            var d: float = player.global_position.distance_to(enemy.global_position)
            if d < best:
                best = d
                target = enemy
    if target:
        var ehp: int = int(target.get_meta("hp", 100)) - 50
        target.set_meta("hp", ehp)
        coins += 5
        if ehp <= 0:
            enemies.erase(target)
            target.queue_free()
            coins += 50
            _toast("Enemy defeated! +55 coins")
        else:
            _toast("Slash! +5 coins")
    await get_tree().create_timer(0.2).timeout
    attacking = false

func _build_enemies() -> void:
    for i in range(8):
        var a: float = float(i) * TAU / 8.0
        _spawn_enemy(Vector3(cos(a) * 25.0, 3.0, sin(a) * 25.0))

func _spawn_enemy(pos: Vector3) -> void:
    var e := CharacterBody3D.new()
    e.position = pos
    e.set_meta("hp", 100)
    add_child(e)
    var cs := CollisionShape3D.new()
    var sh := CapsuleShape3D.new()
    sh.radius = 0.65
    sh.height = 2.4
    cs.shape = sh
    e.add_child(cs)
    var m := MeshInstance3D.new()
    var mm := CapsuleMesh.new()
    mm.radius = 0.65
    mm.height = 2.4
    m.mesh = mm
    m.position.y = 1.2
    m.material_override = _mat(Color("#43215e"), true)
    e.add_child(m)
    enemies.append(e)

func _update_enemies(delta: float) -> void:
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
            continue
        var dist: float = enemy.global_position.distance_to(player.global_position)
        if dist < 22.0 and dist > 2.5:
            var dir: Vector3 = (player.global_position - enemy.global_position).normalized()
            enemy.velocity.x = dir.x * 2.2
            enemy.velocity.z = dir.z * 2.2
            enemy.move_and_slide()
        else:
            enemy.velocity.x = 0
            enemy.velocity.z = 0
        if dist < 2.6:
            hp = maxi(0, hp - int(8.0 * delta))

func _build_npcs() -> void:
    _spawn_npc(Vector3(8, 2.2, 25), "Mira", Color("#ff72ad"), Color("#f7c1a8"), Color("#351452"), "SUMMER HERO")
    _spawn_npc(Vector3(-10, 2.2, 25), "Aya", Color("#7468ff"), Color("#f1b49d"), Color("#291b55"), "ISLAND GUIDE")

func _spawn_npc(pos: Vector3, name_text: String, outfit: Color, skin: Color, hair: Color, title: String) -> void:
    var npc := Node3D.new()
    npc.position = pos
    add_child(npc)
    _character_visual(npc, outfit, skin, hair)
    var label := Label3D.new()
    label.text = name_text + "\n" + title
    label.position.y = 4.0
    label.font_size = 30
    npc.add_child(label)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    status_label = Label.new()
    status_label.position = Vector2(28, 22)
    status_label.add_theme_font_size_override("font_size", 26)
    layer.add_child(status_label)
    hp_bar = ProgressBar.new()
    hp_bar.position = Vector2(28, 78)
    hp_bar.size = Vector2(300, 24)
    hp_bar.max_value = 100
    layer.add_child(hp_bar)
    quest_label = Label.new()
    quest_label.position = Vector2(28, 112)
    quest_label.add_theme_font_size_override("font_size", 20)
    layer.add_child(quest_label)
    _button(layer, "◀", Vector2(35, 565), Vector2(75, 75), func(): joystick.x = -1)
    _button(layer, "▶", Vector2(205, 565), Vector2(75, 75), func(): joystick.x = 1)
    _button(layer, "▲", Vector2(120, 515), Vector2(75, 75), func(): joystick.y = -1)
    _button(layer, "▼", Vector2(120, 620), Vector2(75, 75), func(): joystick.y = 1)
    _button(layer, "ATTACK", Vector2(1020, 535), Vector2(210, 90), func(): _attack())
    _button(layer, "SPRINT", Vector2(890, 625), Vector2(150, 60), func(): sprint_down = true)

func _button(layer: CanvasLayer, text: String, pos: Vector2, size: Vector2, action: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = size
    b.add_theme_font_size_override("font_size", 22)
    b.button_down.connect(action)
    b.button_up.connect(func() -> void:
        joystick = Vector2.ZERO
        sprint_down = false
    )
    layer.add_child(b)

func _update_hud() -> void:
    status_label.text = "NEON ISLES\n❤ %d/100    ✦ %d    ◆ %d" % [hp, coins, crystals]
    hp_bar.value = hp
    quest_label.text = "QUEST  •  Collect 5 crystals  (%d/5)" % crystals

func _toast(text: String) -> void:
    if status_label:
        status_label.text = "NEON ISLES\n" + text

func _mat(color: Color, glow: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    if glow:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 1.8
    return m
