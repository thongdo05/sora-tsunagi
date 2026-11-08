class_name WorldLoop
extends Resource

## Locked order: Glassfall, Moonheld, Lanternfall, then Glassfall again.
## Adding a world is another entry in this list. Adding a panel is an entry
## on that world's WorldBackdrop.

@export var worlds: Array[WorldBackdrop] = []


func next_after(world: WorldBackdrop) -> WorldBackdrop:
	if worlds.is_empty() or world == null:
		return null
	var at := worlds.find(world)
	if at < 0:
		return worlds[0]
	return worlds[(at + 1) % worlds.size()]


## One placed panel in source pixels. art_x is the left edge along that layer's chain.
func layout(layer: String, index: int) -> Dictionary:
	var empty := {
		"texture": null, "flip": false, "world": null, "reuse": true,
		"art_x": 0.0, "src_w": 1.0, "region": Rect2(0, 0, 1, 1), "full_h": 1.0, "fade": 0.0,
	}
	if index < 0:
		var head := _layout_forward(layer, 0)
		if head.get("texture") == null:
			return empty
		# A finished chain has a real first panel. Do not mirror it back onto itself.
		if not bool(head.get("reuse", true)):
			return empty
		var step := float(head["src_w"]) * 0.82
		return {
			"texture": head["texture"],
			"flip": true,
			"world": head["world"],
			"reuse": true,
			"art_x": float(index) * step,
			"src_w": head["src_w"],
			"region": head["region"],
			"full_h": head["full_h"],
			"fade": 0.2,
		}
	return _layout_forward(layer, index)


func _layout_forward(layer: String, index: int) -> Dictionary:
	var empty := {
		"texture": null, "flip": false, "world": null, "reuse": true,
		"art_x": 0.0, "src_w": 1.0, "region": Rect2(0, 0, 1, 1), "full_h": 1.0, "fade": 0.0,
	}
	if worlds.is_empty():
		return empty
	var world: WorldBackdrop = worlds[0]
	var art_x := 0.0
	var i := 0
	var guard := 0
	while world != null and guard < 16:
		guard += 1
		var panels := world.panels_for(layer)
		if panels.is_empty():
			var nxt := next_after(world)
			if nxt == null or nxt == world or (nxt == worlds[0] and guard > 1):
				return empty
			world = nxt
			continue
		if world.reuses(layer):
			while i <= index:
				var slot := int(posmod(i, panels.size()))
				var tex: Texture2D = panels[slot]
				var src_w := float(tex.get_width())
				var step := src_w * 0.8
				var piece := {
					"texture": tex,
					"flip": int(posmod(i, 2)) == 1,
					"world": world,
					"reuse": true,
					"art_x": art_x,
					"src_w": src_w,
					"region": Rect2(0, 0, src_w, tex.get_height()),
					"full_h": tex.get_height(),
					"fade": 0.2,
				}
				if i == index:
					return piece
				art_x += step
				i += 1
			return empty
		var stride := world.chain_stride_px
		var full := world.chain_full_px
		if stride <= 0:
			stride = int(panels[0].get_width())
			full = stride
		var n := 0
		while n < panels.size():
			var tex: Texture2D = panels[n]
			var src_w := full if n == panels.size() - 1 else stride
			src_w = mini(src_w, int(tex.get_width()))
			var piece := {
				"texture": tex,
				"flip": false,
				"world": world,
				"reuse": false,
				"art_x": art_x,
				"src_w": float(src_w),
				"region": Rect2(0, 0, src_w, tex.get_height()),
				"full_h": tex.get_height(),
				"fade": 0.14 if n == panels.size() - 1 else 0.0,
			}
			if i == index:
				return piece
			art_x += float(src_w)
			i += 1
			n += 1
		var following := next_after(world)
		if following == null or following.panels_for(layer).is_empty():
			var last: Texture2D = panels[panels.size() - 1]
			var hold_w := float(mini(stride, int(last.get_width())))
			while i <= index:
				var step := hold_w * 0.82
				var piece := {
					"texture": last,
					"flip": int(posmod(i, 2)) == 1,
					"world": world,
					"reuse": true,
					"art_x": art_x,
					"src_w": hold_w,
					"region": Rect2(0, 0, hold_w, last.get_height()),
					"full_h": last.get_height(),
					"fade": 0.2,
				}
				if i == index:
					return piece
				art_x += step
				i += 1
			return empty
		world = following
	return empty


## texture, flip, world, reuse. index may be negative behind the start.
func resolve(layer: String, index: int) -> Dictionary:
	var laid := layout(layer, index)
	return {
		"texture": laid.get("texture"),
		"flip": laid.get("flip", false),
		"world": laid.get("world"),
		"reuse": laid.get("reuse", true),
	}

