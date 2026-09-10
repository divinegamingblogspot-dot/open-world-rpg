extends Node

var scene: Node3D
var player: Node3D
var sun: DirectionalLight3D
var time := 0.0

func _ready() -> void:
    await get_tree().process_frame
    scene = get_tree().current_scene
    if scene == null: return
    player = scene.get_node_or_null("CharacterBody3D")
    _environment()
    _beacon()
    _shrines()
    _motes()

func _process(delta: float) -> void:
    time += delta
    if sun:
        sun.rotation_degrees.x = -55.0 + sin(time * 0.025) * 15.0
        sun.rotation_degrees.y = -25.0 + cos(time * 0.018) * 10.0
    if player:
        var model = player.get_node_or_null("AstralHeroineModel")
        if model:
            model.rotation.y = sin(time * 0.65) * 0.025
            for s in [-1.0, 1.0]:
                var mote = model.get_node_or_null("Mote" + str(s))
                if mote: mote.position.y = 2.12 + sin(time * 2.2 + s) * 0.16

func _environment() -> void:
    var we := scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if we == null:
        we = WorldEnvironment.new()
        we.name = "WorldEnvironment"
        scene.add_child(we)
    var env := we.environment
    if env == null:
        env = Environment.new()
        we.environment = env
    env.ambient_light_energy = 1.0
    env.glow_enabled = true
    env.glow_intensity = 0.9
    env.glow_bloom = 0.18
    env.glow_strength = 1.05
    env.fog_enabled = true
    env.fog_light_color = Color("#b7e8ff")
    env.fog_density = 0.004
    sun = scene.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
    if sun: sun.light_energy = 1.55

func _beacon() -> void:
    var root := Node3D.new()
    root.name = "AstralBeacon"
    root.position = Vector3(0, 7, -5)
    scene.add_child(root)
    _cyl(root, 5.0, 12.0, Color("#26345b"))
    _ring(root, 5.5, 0.18, Vector3(0, 4.5, 0), Color("#62f4ff"))
    _ring(root, 4.2, 0.14, Vector3(0, 8.0, 0), Color("#ff68c7"))
    _sphere(root, Vector3(0, 13, 0), Vector3(1.1,1.1,1.1), Color("#7cf7ff"), true)
    var l := OmniLight3D.new()
    l.position.y = 13
    l.light_color = Color("#62f4ff")
    l.light_energy = 3.0
    l.omni_range = 18.0
    root.add_child(l)

func _shrines() -> void:
    for i in range(4):
        var a := float(i) * TAU / 4.0 + 0.3
        var root := Node3D.new()
        root.name = "Shrine_%d" % i
        root.position = Vector3(cos(a)*17.0, 2.7, sin(a)*17.0)
        scene.add_child(root)
        _cyl(root, 3.0, 0.7, Color("#d5d7e3"))
        _cyl(root, 1.8, 1.0, Color("#6f7595"))
        _box(root, Vector3(0.45,2.8,0.45), Vector3(-1.2,1.8,0), Color("#303957"))
        _box(root, Vector3(0.45,2.8,0.45), Vector3(1.2,1.8,0), Color("#303957"))
        _ring(root, 2.5, 0.10, Vector3(0,1.2,0), Color("#8e6dff"))
        _sphere(root, Vector3(0,3.2,0), Vector3(0.4,0.85,0.4), Color("#d85cff"), true)

func _motes() -> void:
    var p := GPUParticles3D.new()
    p.name = "AstralMotes"
    p.amount = 90
    p.lifetime = 7.0
    p.visibility_aabb = AABB(Vector3(-70,0,-70), Vector3(140,35,140))
    var pm := ParticleProcessMaterial.new()
    pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    pm.emission_box_extents = Vector3(55,14,55)
    pm.direction = Vector3(0,1,0)
    pm.spread = 180.0
    pm.gravity = Vector3(0,0.04,0)
    pm.initial_velocity_min = 0.15
    pm.initial_velocity_max = 0.55
    pm.scale_min = 0.025
    pm.scale_max = 0.065
    p.process_material = pm
    var s := SphereMesh.new()
    s.radius = 0.045
    s.height = 0.09
    s.material = _glow(Color("#9df8ff"), 1.5)
    p.draw_pass_1 = s
    scene.add_child(p)

func _cyl(parent: Node3D, radius: float, height: float, color: Color) -> void:
    var m := MeshInstance3D.new()
    var x := CylinderMesh.new()
    x.top_radius = radius
    x.bottom_radius = radius
    x.height = height
    x.radial_segments = 32
    m.mesh = x
    m.material_override = _mat(color)
    parent.add_child(m)

func _ring(parent: Node3D, outer: float, thickness: float, pos: Vector3, color: Color) -> void:
    var m := MeshInstance3D.new()
    var x := TorusMesh.new()
    x.inner_radius = outer-thickness
    x.outer_radius = outer
    x.rings = 32
    x.ring_segments = 8
    m.mesh = x
    m.position = pos
    m.material_override = _glow(color, 1.5)
    parent.add_child(m)

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
    var m := MeshInstance3D.new()
    var x := BoxMesh.new()
    x.size = size
    m.mesh = x
    m.position = pos
    m.material_override = _mat(color)
    parent.add_child(m)

func _sphere(parent: Node3D, pos: Vector3, scale_value: Vector3, color: Color, glow: bool) -> void:
    var m := MeshInstance3D.new()
    var x := SphereMesh.new()
    x.radius = 1.0
    x.height = 2.0
    m.mesh = x
    m.position = pos
    m.scale = scale_value
    m.material_override = _glow(color,1.8) if glow else _mat(color)
    parent.add_child(m)

func _mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.48
    return m

func _glow(color: Color, energy: float) -> StandardMaterial3D:
    var m := _mat(color)
    m.emission_enabled = true
    m.emission = color
    m.emission_energy_multiplier = energy
    return m
