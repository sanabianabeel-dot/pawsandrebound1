extends CharacterBody2D

@export var stand: Texture2D
@export var jumping: Texture2D

func _physics_process(delta):
    var dir = Input.get_axis("ui_left", "ui_right")
    velocity.x = dir * 230
    velocity.y = min(velocity.y + 1350 * delta, 800)
    if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
        velocity.y = -520
    move_and_slide()

    # tell the tile we are standing on (springs and crumbling tiles react)
    for i in get_slide_collision_count():
        var tile = get_slide_collision(i).get_collider()
        if is_on_floor() and tile.has_method("on_landed"):
            tile.on_landed(self)

    $Sprite2D.texture = stand if is_on_floor() else jumping
    if dir != 0:
        $Sprite2D.flip_h = dir < 0
