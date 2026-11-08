class_name WorldBackdrop
extends Resource

## One world in the locked loop (Glassfall, Moonheld, Lanternfall).
##
## To add a background panel, drop the image under assets/worlds/<world>/ and append
## it to far_panels, mid_panels, and near_panels in that world's .tres.
## Keep the three lists in the same order. near_panels may stay empty.
## While a layer has fewer than reuse_until panels, the game mirrors and crossfades
## that layer instead of moving on. At reuse_until (4) or more, panels play in order
## and the layer crossfades into the next world in world_loop.tres.

@export var world_id: String = ""
@export var sky_color: Color = Color(0.04, 0.08, 0.16, 1)
## Shown in the editor. The first playable plate can differ from world_id.
@export_multiline var art_note: String = ""
@export var far_panels: Array[Texture2D] = []
@export var mid_panels: Array[Texture2D] = []
@export var near_panels: Array[Texture2D] = []
## Unique panels required before this world plays through and hands off.
@export var reuse_until: int = 4
## Authored chain. 0 means each texture is its own full width.
## Moonheld panels are 2816 wide with a 2304 stride (512px hand-off already in the art).
@export var chain_stride_px: int = 0
@export var chain_full_px: int = 0


func panels_for(layer: String) -> Array[Texture2D]:
	match layer:
		"far":
			return far_panels
		"mid":
			return mid_panels
		"near":
			return near_panels
		_:
			return []


func reuses(layer: String) -> bool:
	var panels := panels_for(layer)
	return panels.is_empty() or panels.size() < reuse_until
