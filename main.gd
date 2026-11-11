
extends Node3D

const CAR_SCRIPT = preload("res://car.gd")

var road_material: StandardMaterial3D
var ground_material: StandardMaterial3D
var line_material: StandardMaterial3D
var barrier_material: StandardMaterial3D


func _ready():
    create_materials()
    create_environment()
    create_track()
    create_car()


func create_materials():
    road_material = StandardMaterial3D.new()
    road_material.albedo_color = Color(0.045, 0.055, 0.075)
    road_material.roughness = 0.35
    road_material.metallic = 0.25

    ground_material = StandardMaterial3D.new()
    ground_material.albedo_color = Color(0.012, 0.018, 0.028)

    line_material = StandardMaterial3D.new()
    line_material.albedo_color = Color(0.0, 0.75, 1.0)
    line_material.emission_enabled = true
    line_material.emission = Color(0.0, 0.4, 1.0)

    barrier_material = StandardMaterial3D.new()
    barrier_material.albedo_color = Color(0.08, 0.12, 0.19)
    barrier_material.metallic = 0.65
    barrier_material.roughness = 0.3


func create_environment():
    var world = WorldEnvironment.new()
    var environment = Environment.new()

    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.008, 0.012, 0.035)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.35, 0.42, 0.65)
    environment.ambient_light_energy = 0.7

    world.environment = environment
    add_child(world)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.light_energy = 0.8
    add_child(sun)

    for p in [
        Vector3(-35, 7, -30),
        Vector3(35, 7, -30),
        Vector3(-35, 7, 30),
        Vector3(35, 7, 30)
    ]:
        var lamp = OmniLight3D.new()
        lamp.position = p
        lamp.light_color = Color(0.0, 0.35, 1.0)
        lamp.light_energy = 2.0
        lamp.omni_range = 30
        add_child(lamp)


func create_track():
    # Ground
    add_static_box(
        "Ground",
        Vector3(0, -0.6, 0),
        Vector3(180, 1, 180),
        ground_material
    )

    # Four connected road sections
    add_static_box(
        "North Road",
        Vector3(0, 0, -35),
        Vector3(90, 0.4, 14),
        road_material
    )

    add_static_box(
        "South Road",
        Vector3(0, 0, 35),
        Vector3(90, 0.4, 14),
        road_material
    )

    add_static_box(
        "East Road",
        Vector3(38, 0, 0),
        Vector3(14, 0.4, 70),
        road_material
    )

    add_static_box(
        "West Road",
        Vector3(-38, 0, 0),
        Vector3(14, 0.4, 70),
        road_material
    )

    # Neon road markings
    for z in range(-65, 66, 5):
        add_visual_box(
            "Road Marking",
            Vector3(0, 0.23, z),
            Vector3(0.15, 0.04, 2),
            line_material
        )

    # Track barriers
    add_static_box(
        "North Barrier",
        Vector3(0, 0.8, -43),
        Vector3(95, 1.6, 0.7),
        barrier_material
    )

    add_static_box(
        "South Barrier",
        Vector3(0, 0.8, 43),
        Vector3(95, 1.6, 0.7),
        barrier_material
    )

    add_static_box(
        "East Barrier",
        Vector3(46, 0.8, 0),
        Vector3(0.7, 1.6, 85),
        barrier_material
    )

    add_static_box(
        "West Barrier",
        Vector3(-46, 0.8, 0),
        Vector3(0.7, 1.6, 85),
        barrier_material
    )


func add_static_box(
    box_name: String,
    pos: Vector3,
    dimensions: Vector3,
    material: Material
):
    var body = StaticBody3D.new()
    body.name = box_name
    body.position = pos

    var mesh_instance = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = dimensions
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material

    body.add_child(mesh_instance)

    var collision = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape

    body.add_child(collision)
    add_child(body)


func add_visual_box(
    box_name: String,
    pos: Vector3,
    dimensions: Vector3,
    material: Material
):
    var instance = MeshInstance3D.new()
    instance.name = box_name
    instance.position = pos

    var mesh = BoxMesh.new()
    mesh.size = dimensions

    instance.mesh = mesh
    instance.material_override = material

    add_child(instance)


func create_car():
    var car = CharacterBody3D.new()
    car.name = "PlayerCar"
    car.set_script(CAR_SCRIPT)

    add_child(car)
    car.position = Vector3(0, 0.8, 34)
