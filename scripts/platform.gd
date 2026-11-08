class_name GlassPlatform
extends StaticBody2D

## Moonheld S3 pieces. The node origin is the left end of the walking surface.
## Art above that line (posts, rings) is visual only.

const VIS_BELOW := 156.0

const TEX_SEAWALL := preload("res://assets/worlds/moonheld/seawall.webp")
const TEX_CORAL := preload("res://assets/worlds/moonheld/coral.webp")
const TEX_ROCK := preload("res://assets/worlds/moonheld/rock.webp")
const TEX_PLANK := preload("res://assets/worlds/moonheld/plank.webp")
const TEX_BUOY := preload("res://assets/worlds/moonheld/buoy.webp")

# walk_y is the walking surface in texture pixels, measured from the top.
const PIECES := {
	"seawall": {"tex": TEX_SEAWALL, "walk": 104},
	"coral": {"tex": TEX_CORAL, "walk": 10},
	"rock": {"tex": TEX_ROCK, "walk": 7},
	"plank": {"tex": TEX_PLANK, "walk": 47},
	"buoy": {"tex": TEX_BUOY, "walk": 6},
}

var width: float = 480.0
var thickness: float = 58.0
var kind: String = "rock"


func setup(platform_width: float, platform_thickness: float) -> void:
	width = platform_width
	thickness = platform_thickness
	kind = _kind_for(width)
	collision_layer = 1
	collision_mask = 0
	z_index = 1
	var deck := 34.0
	var side := 8.0 if kind != "buoy" else width * 0.16
	var shape := RectangleShape2D.new()
	shape.size = Vector2(maxf(width - side * 2.0, 36.0), deck)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(width * 0.5, deck * 0.5)
	collision.one_way_collision = true
	collision.one_way_collision_margin = 10.0
	add_child(collision)
	_build_art()


func _kind_for(platform_width: float) -> String:
	if platform_width < 270.0:
		return "buoy"
	if platform_width < 460.0:
		return "plank"
	if platform_width < 700.0:
		return "rock"
	if platform_width < 1080.0:
		return "coral"
	return "seawall"


func _build_art() -> void:
	var spec: Dictionary = PIECES[kind]
	var texture: Texture2D = spec["tex"]
	var walk := float(spec["walk"])
	var tex_size := texture.get_size()
	var below := maxf(tex_size.y - walk, 1.0)
	var preferred := VIS_BELOW / below
	var natural := tex_size.x * preferred
	if width <= natural * 1.04:
		_add_slice(texture, walk, Rect2(0, 0, tex_size.x, tex_size.y), width / tex_size.x, width / tex_size.x, 0.0)
		return
	# One piece. End caps keep their shape; only the middle stretches, so a long dock does not show a repeated seam.
	var cap_frac := 0.27
	var cap_src := tex_size.x * cap_frac
	var cap_px := cap_src * preferred
	if cap_px * 2.0 > width - 24.0:
		var fit := width / tex_size.x
		_add_slice(texture, walk, Rect2(0, 0, tex_size.x, tex_size.y), fit, fit, 0.0)
		return
	var mid_src := tex_size.x - cap_src * 2.0
	var mid_px := width - cap_px * 2.0
	_add_slice(texture, walk, Rect2(0, 0, cap_src, tex_size.y), preferred, preferred, 0.0)
	_add_slice(texture, walk, Rect2(cap_src, 0, mid_src, tex_size.y), mid_px / mid_src, preferred, cap_px)
	_add_slice(texture, walk, Rect2(cap_src + mid_src, 0, cap_src, tex_size.y), preferred, preferred, width - cap_px)


func _add_slice(texture: Texture2D, walk: float, region: Rect2, scale_x: float, scale_y: float, x: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.scale = Vector2(scale_x, scale_y)
	sprite.position = Vector2(x, -walk * scale_y)
	add_child(sprite)
