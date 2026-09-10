extends Node

func _ready() -> void:
    _add_key_action("move_left", KEY_A, KEY_LEFT)
    _add_key_action("move_right", KEY_D, KEY_RIGHT)
    _add_key_action("move_forward", KEY_W, KEY_UP)
    _add_key_action("move_back", KEY_S, KEY_DOWN)
    _add_key_action("sprint", KEY_SHIFT)
    _add_key_action("attack", KEY_SPACE)
    _add_key_action("left", KEY_A, KEY_LEFT)
    _add_key_action("right", KEY_D, KEY_RIGHT)
    _add_key_action("forward", KEY_W, KEY_UP)
    _add_key_action("back", KEY_S, KEY_DOWN)
    var mouse := InputEventMouseButton.new()
    mouse.button_index = MOUSE_BUTTON_LEFT
    _add_event("attack", mouse)

func _add_key_action(action: String, primary: Key, secondary: Key = KEY_NONE) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var a := InputEventKey.new()
    a.physical_keycode = primary
    _add_event(action, a)
    if secondary != KEY_NONE:
        var b := InputEventKey.new()
        b.physical_keycode = secondary
        _add_event(action, b)

func _add_event(action: String, event: InputEvent) -> void:
    for existing in InputMap.action_get_events(action):
        if existing.as_text() == event.as_text():
            return
    InputMap.action_add_event(action, event)
