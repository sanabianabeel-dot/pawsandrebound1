extends AnimatableBody2D

@export_enum("normal", "spring", "crumble", "cloud") var kind := "normal"
@export var tile: Texture2D          # leave empty to pick a random picture
@export var travel := 150.0          # clouds slide this far to the right

const PICTURES = {
	"normal": ["plat_0", "plat_1_o", "plat_2_p", "plat_3", "plat_4_o", "plat_5_p",
			   "plat_0_o", "plat_3_p", "plat_1_p", "plat_5_o"],
	"spring": ["spring"],
	"crumble": ["crumble_a", "crumble_b"],
	"cloud": ["cloud"],
}

var width = 0.0
var start_x = 0.0
var shaking = false

func _ready():
	if tile == null:
		tile = load("res://assets/tiles/" + PICTURES[kind].pick_random() + ".png")
	$Sprite2D.texture = tile
	$Sprite2D.position.y = 0 if kind == "spring" else -3
	width = tile.get_width()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(width - 8, 20)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = Vector2(width / 2, 10)
	start_x = position.x
	sync_to_physics = (kind == "cloud")

func _physics_process(_delta):
	if kind == "cloud":
		var t = Time.get_ticks_msec() / 1000.0
		position.x = start_x + (sin(t * 1.3 - PI / 2) + 1) * travel / 2

func on_landed(player):
	if kind == "spring":
		player.velocity.y = -830
	elif kind == "crumble" and not shaking:
		shaking = true
		var t = create_tween()
		for i in 8:
			t.tween_property($Sprite2D, "position:x", 3 if i % 2 == 0 else -3, 0.06)
		t.tween_callback($CollisionShape2D.set_deferred.bind("disabled", true))
		t.tween_property($Sprite2D, "position:y", 150, 0.5).as_relative()
		t.tween_callback(queue_free)
