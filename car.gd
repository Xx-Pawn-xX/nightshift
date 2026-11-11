
extends CharacterBody3D

# NIGHTSHIFT - Vehicle Controller v0.1

@export var acceleration: float = 30.0
@export var brake_power: float = 48.0
@export var max_speed: float = 55.0
@export var reverse_speed: float = 12.0
@export var steering_rate: float = 1.65
@export var normal_grip: float = 8.5
@export var drift_grip: float = 2.0
@export var coast_drag: float = 3.0

var touch_gas = false
var touch_brake = false
var touch_left = false
var touch_right = false
var touch_handbrake = false

var camera: Camera3D
var speed_label: Label


func _ready():
    create_car_model()
    create_camera()
    create_controls()


func create_car_model():
    # Main chassis
    var body_mesh = MeshInstance3D.new()
    var body = BoxMesh.new()
    body.size = Vector3(1.9, 0.65, 3.8)

    body_mesh.mesh = body
    body_mesh.position.y = 0.65

    var paint = StandardMaterial3D.new()
    paint.albedo_color = Color(0.015, 0.12, 0.23)
    paint.metallic = 0.85
    paint.roughness = 0.2

    body_mesh.material_override = paint
    add_child(body_mesh)

    # Roof
    var roof_mesh = MeshInstance3D.new()
    var roof = BoxMesh.new()
    roof.size = Vector3(1.45, 0.55, 1.8)

    roof_mesh.mesh = roof
    roof_mesh.position = Vector3(0, 1.18, -0.1)

    var glass = StandardMaterial3D.new()
    glass.albedo_color = Color(0.015, 0.025, 0.055)
    glass.metallic = 0.7

    roof_mesh.material_override = glass
    add_child(roof_mesh)

    # Four wheels
    for x in [-0.98, 0.98]:
        for z in [-1.25, 1.25]:
            var wheel_mesh = MeshInstance3D.new()
            var wheel = CylinderMesh.new()

            wheel.top_radius = 0.42
            wheel.bottom_radius = 0.42
            wheel.height = 0.34

            wheel_mesh.mesh = wheel
            wheel_mesh.position = Vector3(x, 0.4, z)
            wheel_mesh.rotation_degrees.z = 90

            var rubber = StandardMaterial3D.new()
            rubber.albedo_color = Color(0.012, 0.012, 0.018)
            wheel_mesh.material_override = rubber

            add_child(wheel_mesh)

    # Collision
    var collision = CollisionShape3D.new()
    var shape = BoxShape3D.new()

    shape.size = Vector3(1.9, 1.1, 3.8)
    collision.shape = shape
    collision.position.y = 0.65

    add_child(collision)


func create_camera():
    camera = Camera3D.new()

    camera.position = Vector3(0, 5, 10)
    camera.fov = 75
    camera.current = true

    add_child(camera)


func create_controls():
    var layer = CanvasLayer.new()
    add_child(layer)

    speed_label = Label.new()
    speed_label.text = "000 KM/H"

    speed_label.position = Vector2(25, 25)
    speed_label.add_theme_font_size_override("font_size", 30)
    speed_label.add_theme_color_override(
        "font_color",
        Color(0.0, 0.8, 1.0)
    )

    layer.add_child(speed_label)

    # Steering
    add_hold_button(
        layer, "LEFT",
        Vector4(25, -115, 125, -25),
        "left"
    )

    add_hold_button(
        layer, "RIGHT",
        Vector4(135, -115, 235, -25),
        "right"
    )

    # Acceleration and braking
    add_hold_button(
        layer, "BRAKE",
        Vector4(-245, -115, -135, -25),
        "brake"
    )

    add_hold_button(
        layer, "GAS",
        Vector4(-125, -115, -25, -25),
        "gas"
    )

    add_hold_button(
        layer, "DRIFT",
        Vector4(-185, -215, -85, -125),
        "handbrake"
    )


func add_hold_button(
    layer: CanvasLayer,
    button_text: String,
    offsets: Vector4,
    action: String
):
    var button = Button.new()

    button.text = button_text
    button.anchor_left = 1.0 if action in [
        "gas", "brake", "handbrake"
    ] else 0.0
    button.anchor_right = button.anchor_left
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0

    button.offset_left = offsets.x
    button.offset_top = offsets.y
    button.offset_right = offsets.z
    button.offset_bottom = offsets.w

    button.add_theme_font_size_override("font_size", 17)
    button.add_theme_color_override(
        "font_color",
        Color.WHITE
    )

    layer.add_child(button)

    button.button_down.connect(
        _set_touch.bind(action, true)
    )

    button.button_up.connect(
        _set_touch.bind(action, false)
    )


func _set_touch(action: String, pressed: bool):
    match action:
        "gas":
            touch_gas = pressed
        "brake":
            touch_brake = pressed
        "left":
            touch_left = pressed
        "right":
            touch_right = pressed
        "handbrake":
            touch_handbrake = pressed


func _physics_process(delta):
    # Keyboard + touchscreen input
    var gas = touch_gas or Input.is_key_pressed(KEY_W)
    var brake = touch_brake or Input.is_key_pressed(KEY_S)

    var left = touch_left or Input.is_key_pressed(KEY_A)
    var right = touch_right or Input.is_key_pressed(KEY_D)

    var handbrake = (
        touch_handbrake or Input.is_key_pressed(KEY_SPACE)
    )

    var steer = float(right) - float(left)

    # Current vehicle direction
    var forward = -global_basis.z
    var sideways = global_basis.x

    var forward_speed = velocity.dot(forward)
    var lateral_speed = velocity.dot(sideways)

    # Acceleration
    if gas:
        forward_speed = move_toward(
            forward_speed,
            max_speed,
            acceleration * delta
        )

    # Braking and reverse
    elif brake:
        if forward_speed > 1.0:
            forward_speed = move_toward(
                forward_speed,
                0.0,
                brake_power * delta
            )
        else:
            forward_speed = move_toward(
                forward_speed,
                -reverse_speed,
                acceleration * 0.55 * delta
            )

    else:
        forward_speed = move_toward(
            forward_speed,
            0.0,
            coast_drag * delta
        )

    # Steering depends on speed
    if abs(forward_speed) > 0.5:
        var steering_strength = clamp(
            abs(forward_speed) / 8.0,
            0.15,
            1.0
        )

        var steering_multiplier = (
            0.55 if handbrake else 1.0
        )

        rotate_y(
            -steer
            * steering_rate
            * steering_strength
            * steering_multiplier
            * sign(forward_speed)
            * delta
        )

    # Simcade lateral grip
    var grip = drift_grip if handbrake else normal_grip

    lateral_speed += (
        steer * abs(forward_speed) * 0.22 * delta
    )

    lateral_speed *= exp(-grip * delta)

    # Recalculate direction after steering
    forward = -global_basis.z
    sideways = global_basis.x

    velocity.x = (
        forward.x * forward_speed
        + sideways.x * lateral_speed
    )

    velocity.z = (
        forward.z * forward_speed
        + sideways.z * lateral_speed
    )

    # Gravity
    if not is_on_floor():
        velocity.y -= 9.8 * delta
    else:
        velocity.y = 0.0

    move_and_slide()

    # Speedometer
    if speed_label:
        var kmh = int(abs(forward_speed) * 3.6)
        speed_label.text = "%03d KM/H" % kmh


func _process(delta):
    if camera:
        camera.position = camera.position.lerp(
            Vector3(0, 5, 10),
            delta * 4.0
        )

        camera.look_at(
            global_position + Vector3(0, 1, 0),
            Vector3.UP
        )
