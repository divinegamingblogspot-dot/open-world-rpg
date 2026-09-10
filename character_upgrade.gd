extends Node

# Adds polished, original adult anime-style summer character details after the main scene builds NPCs.

func _ready() -> void:
    _wait_for_npcs()

func _wait_for_npcs() -> void:
    for _i in range(120):
        await get_tree().process_frame
        var mira := get_tree().current_scene.get_node_or_null("Mira")
        var aya := get_tree().current_scene.get_node_or_null("Aya")
        if mira:
            _style_character(mira, Color("#ff6fae"), Color("#fff4fa"), true)
        if aya:
            _style_character(aya, Color("#7c68ff"), Color("#fff0a8"), false)
        if mira and aya:
            return

func _style_character(npc: Node3D, hair_color: Color, accent: Color, ribbon: bool) -> void:
    if npc.get_meta("styled", false):
        return
    npc.set_meta("styled", true)

    # Long side hair locks.
    _sphere(npc, "HairLeft", Vector3(-0.48, 2.35, -0.08), Vector3(0.34, 0.95, 0.34), hair_color)
    _sphere(npc, "HairRight", Vector3(0.48, 2.35, -0.08), Vector3(0.34, 0.95, 0.34), hair_color)

    # Anime-style eyes and small smile accent.
    _sphere(npc, "EyeL", Vector3(-0.22, 2.62, -0.52), Vector3(0.075, 0.12, 0.055), Color("#33234d"))
    _sphere(npc, "EyeR", Vector3(0.22, 2.62, -0.52), Vector3(0.075, 0.12, 0.055), Color("#33234d"))
    _sphere(npc, "EyeHighlightL", Vector3(-0.20, 2.67, -0.57), Vector3(0.025, 0.035, 0.018), Color.WHITE)
    _sphere(npc, "EyeHighlightR", Vector3(0.24, 2.67, -0.57), Vector3(0.025, 0.035, 0.018), Color.WHITE)

    # Elegant summer swim outfit details: top, waist band and wrap/skirt.
    _box(npc, "SummerTop", Vector3(1.25, 0.32, 0.52), Vector3(0, 1.72, -0.03), accent)
    _box(npc, "WaistBand", Vector3(1.55, 0.18, 0.70), Vector3(0, 1.38, 0), hair_color)
    _box(npc, "BeachWrap", Vector3(1.75, 0.42, 0.78), Vector3(0, 0.98, 0), accent)

    # Arms with simple bracelets.
    _capsule(npc, "ArmL", Vector3(-0.72, 1.35, 0), 0.14, 1.15, Color("#f0b59d"), Vector3(0, 0, -12))
    _capsule(npc, "ArmR", Vector3(0.72, 1.35, 0), 0.14, 1.15, Color("#f0b59d"), Vector3(0, 0, 12))
    _sphere(npc, "BraceletL", Vector3(-0.80, 1.02, 0), Vector3(0.18, 0.08, 0.18), hair_color)
    _sphere(npc, "BraceletR", Vector3(0.80, 1.02, 0), Vector3(0.18, 0.08, 0.18), hair_color)

    if ribbon:
        _box(npc, "Ribbon", Vector3(0.18, 0.9, 0.12), Vector3(0.62, 2.98, 0), hair_color)
        _sphere(npc, "RibbonKnot", Vector3(0.55, 2.9, 0), Vector3(0.20, 0.20, 0.12), hair_color)
    else:
        _sphere(npc, "SunCharm", Vector3(0.0, 3.02, 0.0), Vector3(0.18, 0.18, 0.10), accent)

func _box(parent: Node3D, n: String, size: Vector3, pos: Vector3, color: Color) -> void:
    var m := MeshInstance3D.new()
    m.name = n
    var mesh := BoxMesh.new()
    mesh.size = size
    m.mesh = mesh
    m.position = pos
    m.material_override = _mat(color)
    parent.add_child(m)

func _sphere(parent: Node3D, n: String, pos: Vector3, scale_value: Vector3, color: Color) -> void:
    var m := MeshInstance3D.new()
    m.name = n
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    m.mesh = mesh
    m.position = pos
    m.scale = scale_value
    m.material_override = _mat(color)
    parent.add_child(m)

func _capsule(parent: Node3D, n: String, pos: Vector3, radius: float, height: float, color: Color, rot: Vector3) -> void:
    var m := MeshInstance3D.new()
    m.name = n
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    m.mesh = mesh
    m.position = pos
    m.rotation_degrees = rot
    m.material_override = _mat(color)
    parent.add_child(m)

func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.48
    return material
