extends Node2D

@export var platform_scene: PackedScene
@export var star_scene: PackedScene

var next_x = 460.0        # where the next platform goes
var last_y = 440.0
var last_kind = "normal"
var score = 0
var saves = 3
var over = false
var can_restart = false

@onready var player = $Player
@onready var camera = $Camera2D

func _ready():
    update_hud()

func _process(_delta):
    if can_restart and Input.is_action_just_pressed("ui_accept"):
        get_tree().reload_current_scene()

func _physics_process(_delta):
    camera.position.x = max(camera.position.x, player.position.x + 60)   # never scrolls back
    $LeftWall.position.x = camera.position.x - 470
    while next_x < camera.position.x + 900:
        spawn_platform()
    for thing in $Platforms.get_children() + $Stars.get_children():
        if thing.position.x < camera.position.x - 700:
            thing.queue_free()
    if player.position.y > 505 and not over:
        fall()

func spawn_platform():
    var hard = clampf(next_x / 10000.0, 0.0, 1.0)    # gets harder the further you go
    var kind = "normal"
    var roll = randf()
    if roll < 0.15 + 0.1 * hard:
        kind = "crumble"
    elif roll < 0.30 + 0.1 * hard:
        kind = "cloud"
    elif roll < 0.40 + 0.1 * hard and last_y > 330:
        kind = "spring"

    var y = clampf(last_y + randf_range(-70, 70), 180, 440)
    if last_kind == "spring":
        y = clampf(last_y - randf_range(120, 190), 170, 440)

    var p = platform_scene.instantiate()
    p.kind = kind
    p.position = Vector2(next_x, y)
    $Platforms.add_child(p)

    if kind != "spring" and randf() < 0.5:
        var s = star_scene.instantiate()
        s.position = Vector2(next_x + p.width / 2, y - 45)
        s.body_entered.connect(star_taken.bind(s))
        $Stars.add_child(s)

    next_x += p.width + randf_range(70, 100 + 35 * hard)
    if kind == "cloud":
        next_x += p.travel
    last_y = y
    last_kind = kind

func star_taken(body, star):
    if body == player:
        score += 10
        star.queue_free()
        update_hud()

func update_hud():
    $Camera2D/Text.text = "Score: %d     Comebacks: %d" % [score, saves]

func fall():
    if saves > 0:
        saves -= 1
        update_hud()
        player.velocity.y = -950              # the paw launches you back up
        $Paw.position = Vector2(player.position.x, 530)
        $Paw.show()
        await get_tree().create_timer(0.6).timeout
        $Paw.hide()
    else:
        over = true
        player.set_physics_process(false)
        $Camera2D/Text.text = "GAME OVER     Score: %d" % score
        await get_tree().create_timer(1.0).timeout
        $Camera2D/Text.text += "     (press SPACE)"
        can_restart = true
