extends Node

# NEON ISLES CHARACTER OVERHAUL
# Original stylized adult anime heroine models built entirely from Godot primitives.
# Designed to be much richer than the original placeholder capsules while staying mobile-friendly.

var applied: Dictionary = {}

func _ready() -> void:
    _wait_and_upgrade()

func _wait_and_upgrade() -> void:
    for _i in range(180):
        await get_tree().process_frame
        var scene := get_tree().current_scene
        if scene == null:
            continue
        var player := scene.get_node_or_null("CharacterBody3D")
        if player and not applied.has(player.get_instance_id()):
            _upgrade_character(player, Color("#19d9ff"), Color("#14224d"), Color("#f4b8a2"), true)
        for child in scene.get_children():
            if child is Node3D:
                var n := String(child.name)
                if n == "Mira" and not applied.has(child.get_instance_id()):
                    _upgrade_character(child, Color("#ff4fa3"), Color("#291047"), Color("#f5c0aa"), true)
                elif n == "Aya" and not applied.has(child.get_instance_id()):
                    _upgrade_character(child, Color("#8d6bff"), Color("#18254e"), Color("#efb49f"), false)
        if applied.size() >= 3:
            return

func _upgrade_character(root: Node3D, accent: Color, hair: Color, skin: Color, twin_tail: bool) -> void:
    applied[root.get_instance_id()] = true
    root.set_meta("character_overhaul", true)

    # Remove old visual placeholders but preserve CharacterBody3D collision.
    for child in root.get_children():
        if child is MeshInstance3D or child is Label3D or child is OmniLight3D:
            child.queue_free()

    var model := Node3D.new()
    model.name = "AstralHeroineModel"
    root.add_child(model)

    var skin_m := _mat(skin, 0.78, 0.0)
    var hair_m := _mat(hair, 0.34, 0.0)
    var dark_m := _mat(Color("#11172f"), 0.30, 0.15)
    var accent_m := _mat(accent, 0.24, 0.18)
    var white_m := _mat(Color("#f7fbff"), 0.22, 0.0)
    var gold_m := _mat(Color("#ffd86b"), 0.20, 0.65)
    var eye_m := _mat(Color("#6ff4ff"), 0.08, 1.4)
    var eye_dark := _mat(Color("#14234d"), 0.08, 0.05)

    # LEGS / BOOTS
    _capsule(model, "ThighL", Vector3(-0.24, 0.70, 0), 0.205, 1.05, skin_m)
    _capsule(model, "ThighR", Vector3(0.24, 0.70, 0), 0.205, 1.05, skin_m)
    _capsule(model, "CalfL", Vector3(-0.24, 0.22, -0.015), 0.16, 0.85, skin_m)
    _capsule(model, "CalfR", Vector3(0.24, 0.22, -0.015), 0.16, 0.85, skin_m)

    for s in [-1.0, 1.0]:
        _capsule(model, "Boot" + str(s), Vector3(0.24 * s, -0.06, -0.09), 0.225, 0.48, dark_m)
        _box(model, "BootCuff" + str(s), Vector3(0.46, 0.13, 0.42), Vector3(0.24 * s, 0.17, -0.02), accent_m)
        _box(model, "BootSole" + str(s), Vector3(0.52, 0.10, 0.60), Vector3(0.24 * s, -0.28, -0.10), dark_m)
        _box(model, "BootGem" + str(s), Vector3(0.10, 0.10, 0.08), Vector3(0.24 * s, 0.10, -0.26), gold_m)
        _box(model, "BootGlow" + str(s), Vector3(0.30, 0.035, 0.05), Vector3(0.24 * s, 0.20, -0.25), eye_m)

    _box(model, "ThighStrapL", Vector3(0.45, 0.075, 0.08), Vector3(-0.24, 1.06, -0.15), accent_m)
    _box(model, "ThighStrapR", Vector3(0.45, 0.075, 0.08), Vector3(0.24, 1.06, -0.15), accent_m)

    # HIPS / SUMMER BATTLE OUTFIT
    _ellipsoid(model, "HipArmor", Vector3(0, 1.18, 0), Vector3(0.68, 0.34, 0.43), dark_m)
    _box(model, "BikiniBottom", Vector3(0.66, 0.23, 0.42), Vector3(0, 1.23, -0.18), accent_m)
    _box(model, "BottomTrim", Vector3(0.72, 0.075, 0.08), Vector3(0, 1.30, -0.40), gold_m)
    _panel(model, "SkirtL", Vector3(-0.40, 0.95, 0.03), Vector3(0.42, 0.68, 0.08), accent_m, -12.0)
    _panel(model, "SkirtR", Vector3(0.40, 0.95, 0.03), Vector3(0.42, 0.68, 0.08), accent_m, 12.0)
    _box(model, "WaistCore", Vector3(1.10, 0.16, 0.38), Vector3(0, 1.40, -0.02), dark_m)
    _box(model, "WaistGlow", Vector3(0.72, 0.07, 0.10), Vector3(0, 1.41, -0.23), accent_m)
    _sphere(model, "WaistGem", Vector3(0, 1.41, -0.30), Vector3(0.12, 0.12, 0.07), gold_m)

    # TORSO + STRUCTURED BIKINI TOP
    _capsule(model, "Torso", Vector3(0, 1.85, 0), 0.46, 1.05, skin_m)
    _box(model, "ChestPanel", Vector3(0.96, 0.34, 0.18), Vector3(0, 1.90, -0.39), dark_m)
    _ellipsoid(model, "TopL", Vector3(-0.24, 1.90, -0.42), Vector3(0.28, 0.21, 0.11), accent_m)
    _ellipsoid(model, "TopR", Vector3(0.24, 1.90, -0.42), Vector3(0.28, 0.21, 0.11), accent_m)
    _box(model, "TopBand", Vector3(0.88, 0.095, 0.11), Vector3(0, 1.76, -0.43), accent_m)
    _box(model, "TopTrim", Vector3(0.88, 0.055, 0.07), Vector3(0, 1.81, -0.49), gold_m)
    _box(model, "TopCenter", Vector3(0.08, 0.22, 0.07), Vector3(0, 1.91, -0.49), gold_m)
    _capsule_rot(model, "TopStrapL", Vector3(-0.36, 2.15, -0.22), 0.035, 0.72, accent_m, Vector3(0, 0, -23))
    _capsule_rot(model, "TopStrapR", Vector3(0.36, 2.15, -0.22), 0.035, 0.72, accent_m, Vector3(0, 0, 23))

    # SHOULDER ARMOR / COLLAR
    _ellipsoid(model, "ShoulderL", Vector3(-0.56, 2.15, 0), Vector3(0.23, 0.15, 0.24), dark_m)
    _ellipsoid(model, "ShoulderR", Vector3(0.56, 2.15, 0), Vector3(0.23, 0.15, 0.24), dark_m)
    _box(model, "Collar", Vector3(0.50, 0.13, 0.24), Vector3(0, 2.35, -0.02), accent_m)
    _sphere(model, "CollarGem", Vector3(0, 2.35, -0.15), Vector3(0.08, 0.08, 0.05), gold_m)

    # ARMS / GLOVES / BRACERS
    _capsule_rot(model, "ArmL", Vector3(-0.67, 1.78, 0), 0.14, 0.92, skin_m, Vector3(0, 0, 13))
    _capsule_rot(model, "ArmR", Vector3(0.67, 1.78, 0), 0.14, 0.92, skin_m, Vector3(0, 0, -13))
    _capsule(model, "GloveL", Vector3(-0.78, 1.32, -0.03), 0.16, 0.34, dark_m)
    _capsule(model, "GloveR", Vector3(0.78, 1.32, -0.03), 0.16, 0.34, dark_m)
    _box(model, "BracerL", Vector3(0.20, 0.30, 0.25), Vector3(-0.77, 1.50, -0.03), accent_m)
    _box(model, "BracerR", Vector3(0.20, 0.30, 0.25), Vector3(0.77, 1.50, -0.03), accent_m)
    _sphere(model, "GloveGemL", Vector3(-0.80, 1.30, -0.17), Vector3(0.08, 0.08, 0.08), eye_m)
    _sphere(model, "GloveGemR", Vector3(0.80, 1.30, -0.17), Vector3(0.08, 0.08, 0.08), eye_m)

    # HEAD / HAIR
    _capsule(model, "Neck", Vector3(0, 2.45, 0), 0.18, 0.38, skin_m)
    _ellipsoid(model, "Head", Vector3(0, 2.78, -0.01), Vector3(0.53, 0.63, 0.50), skin_m)
    _ellipsoid(model, "Chin", Vector3(0, 2.54, -0.39), Vector3(0.25, 0.18, 0.10), skin_m)
    _ellipsoid(model, "HairCap", Vector3(0, 2.96, 0.02), Vector3(0.60, 0.55, 0.52), hair_m)

    for s in [-1.0, 1.0]:
        _capsule_rot(model, "Bang" + str(s), Vector3(0.18 * s, 2.88, -0.42), 0.12, 0.62, hair_m, Vector3(0, 0, -18 * s))
        _capsule_rot(model, "SideLock" + str(s), Vector3(0.49 * s, 2.56, -0.12), 0.12, 0.95, hair_m, Vector3(0, 0, 12 * s))
        _sphere(model, "HairTip" + str(s), Vector3(0.50 * s, 2.12, 0.02), Vector3(0.16, 0.28, 0.16), hair_m)

    if twin_tail:
        for s in [-1.0, 1.0]:
            _capsule_rot(model, "Tail" + str(s), Vector3(0.50 * s, 2.78, 0.36), 0.18, 1.15, hair_m, Vector3(0, 0, 22 * s))
            _sphere(model, "TailTip" + str(s), Vector3(0.67 * s, 2.23, 0.39), Vector3(0.20, 0.25, 0.20), hair_m)
            _box(model, "Ribbon" + str(s), Vector3(0.26, 0.08, 0.30), Vector3(0.51 * s, 2.76, 0.19), accent_m)
            _sphere(model, "RibbonGem" + str(s), Vector3(0.51 * s, 2.76, 0.02), Vector3(0.07, 0.07, 0.07), gold_m)
    else:
        _capsule_rot(model, "BackHair", Vector3(0, 2.48, 0.38), 0.23, 1.35, hair_m, Vector3(0, 0, 0))
        _box(model, "HairOrnament", Vector3(0.45, 0.09, 0.12), Vector3(0, 2.99, 0.27), accent_m)

    _sphere(model, "EarL", Vector3(-0.51, 2.77, -0.01), Vector3(0.10, 0.15, 0.08), skin_m)
    _sphere(model, "EarR", Vector3(0.51, 2.77, -0.01), Vector3(0.10, 0.15, 0.08), skin_m)

    # EXPRESSIVE FACE: eye whites + irises + pupils + highlights + lashes + brows
    for s in [-1.0, 1.0]:
        _ellipsoid(model, "EyeWhite" + str(s), Vector3(0.20 * s, 2.80, -0.475), Vector3(0.16, 0.20, 0.055), white_m)
        _ellipsoid(model, "Iris" + str(s), Vector3(0.20 * s, 2.80, -0.528), Vector3(0.095, 0.13, 0.028), eye_m)
        _ellipsoid(model, "Pupil" + str(s), Vector3(0.20 * s, 2.80, -0.553), Vector3(0.040, 0.075, 0.018), eye_dark)
        _sphere(model, "EyeHighlightA" + str(s), Vector3(0.17 * s, 2.86, -0.572), Vector3(0.025, 0.032, 0.012), white_m)
        _sphere(model, "EyeHighlightB" + str(s), Vector3(0.24 * s, 2.76, -0.572), Vector3(0.012, 0.016, 0.008), white_m)
        _capsule_rot(model, "Lash" + str(s), Vector3(0.20 * s, 2.94, -0.49), 0.025, 0.32, hair_m, Vector3(0, 0, -12 * s))
        _box(model, "Brow" + str(s), Vector3(0.25, 0.035, 0.025), Vector3(0.20 * s, 3.02, -0.44), hair_m)

    _sphere(model, "Nose", Vector3(0, 2.68, -0.50), Vector3(0.035, 0.045, 0.025), skin_m)
    _sphere(model, "BlushL", Vector3(-0.34, 2.68, -0.48), Vector3(0.10, 0.045, 0.018), _mat(Color("#ff8f9e"), 0.65, 0.0))
    _sphere(model, "BlushR", Vector3(0.34, 2.68, -0.48), Vector3(0.10, 0.045, 0.018), _mat(Color("#ff8f9e"), 0.65, 0.0))
    _box(model, "Mouth", Vector3(0.15, 0.025, 0.018), Vector3(0, 2.58, -0.505), _mat(Color("#8c3556"), 0.45, 0.0))
    _sphere(model, "EarringL", Vector3(-0.54, 2.67, -0.05), Vector3(0.055, 0.10, 0.055), gold_m)
    _sphere(model, "EarringR", Vector3(0.54, 2.67, -0.05), Vector3(0.055, 0.10, 0.055), gold_m)

    # ASTRAL BLADE
    var weapon := Node3D.new()
    weapon.name = "AstralBlade"
    weapon.position = Vector3(0.92, 1.28, -0.08)
    weapon.rotation_degrees = Vector3(0, 0, -28)
    model.add_child(weapon)
    _box(weapon, "Grip", Vector3(0.11, 0.55, 0.11), Vector3(0, -0.18, 0), dark_m)
    _box(weapon, "Guard", Vector3(0.36, 0.08, 0.12), Vector3(0, 0.10, 0), gold_m)
    _box(weapon, "Blade", Vector3(0.12, 1.18, 0.055), Vector3(0, 0.68, 0), accent_m)
    _box(weapon, "BladeEdge", Vector3(0.035, 1.05, 0.025), Vector3(0.07, 0.68, -0.01), eye_m)
    _sphere(weapon, "Pommel", Vector3(0, -0.48, 0), Vector3(0.09, 0.09, 0.09), gold_m)
    _sphere(weapon, "BladeCore", Vector3(0, 0.70, -0.04), Vector3(0.055, 0.45, 0.035), eye_m)

    # AURA + FLOATING MOTES
    var light := OmniLight3D.new()
    light.name = "HeroGlow"
    light.position = Vector3(0, 2.2, 0)
    light.light_color = accent
    light.light_energy = 0.55
    light.omni_range = 4.0
    root.add_child(light)
    for s in [-1.0, 1.0]:
        var mote := MeshInstance3D.new()
        mote.name = "Mote" + str(s)
        var sm := SphereMesh.new()
        sm.radius = 0.055
        sm.height = 0.11
        mote.mesh = sm
        mote.position = Vector3(0.86 * s, 2.12, 0)
        mote.material_override = eye_m
        model.add_child(mote)

func _mat(color: Color, roughness: float, emission_energy: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    m.metallic = 0.12
    if emission_energy > 0.0:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = emission_energy
    return m

func _capsule(parent: Node3D, n: String, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
    return _capsule_rot(parent, n, pos, radius, height, mat, Vector3.ZERO)

func _capsule_rot(parent: Node3D, n: String, pos: Vector3, radius: float, height: float, mat: Material, rot: Vector3) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    m.name = n
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    mesh.radial_segments = 12
    mesh.rings = 4
    m.mesh = mesh
    m.position = pos
    m.rotation_degrees = rot
    m.material_override = mat
    parent.add_child(m)
    return m

func _sphere(parent: Node3D, n: String, pos: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    m.name = n
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    mesh.radial_segments = 16
    mesh.rings = 8
    m.mesh = mesh
    m.position = pos
    m.scale = scale_value
    m.material_override = mat
    parent.add_child(m)
    return m

func _ellipsoid(parent: Node3D, n: String, pos: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
    return _sphere(parent, n, pos, scale_value, mat)

func _box(parent: Node3D, n: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    m.name = n
    var mesh := BoxMesh.new()
    mesh.size = size
    m.mesh = mesh
    m.position = pos
    m.material_override = mat
    parent.add_child(m)
    return m

func _panel(parent: Node3D, n: String, pos: Vector3, size: Vector3, mat: Material, tilt: float) -> void:
    var m := _box(parent, n, size, pos, mat)
    m.rotation_degrees.z = tilt
