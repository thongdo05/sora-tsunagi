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


## texture, flip, world, reuse. index may be negative behind the start.
func resolve(layer: String, index: int) -> Dictionary:
	var empty := {"texture": null, "flip": false, "world": null, "reuse": true}
	if worlds.is_empty():
		return empty
	var world: WorldBackdrop = worlds[0]
	var guard := 0
	var cursor := index
	while world != null and guard < 12:
		guard += 1
		var panels := world.panels_for(layer)
		if panels.is_empty():
			var nxt := next_after(world)
			if nxt == null or nxt == world or nxt == worlds[0] and guard > 1:
				return empty
			world = nxt
			continue
		if world.reuses(layer):
			var slot := int(posmod(cursor, panels.size()))
			return {
				"texture": panels[slot],
				"flip": int(posmod(cursor, 2)) == 1,
				"world": world,
				"reuse": true,
			}
		if cursor < 0:
			return {
				"texture": panels[0],
				"flip": false,
				"world": world,
				"reuse": false,
			}
		if cursor < panels.size():
			return {
				"texture": panels[cursor],
				"flip": false,
				"world": world,
				"reuse": false,
			}
		cursor -= panels.size()
		var following := next_after(world)
		if following == null or following.panels_for(layer).is_empty():
			return {
				"texture": panels[panels.size() - 1],
				"flip": int(posmod(cursor, 2)) == 1,
				"world": world,
				"reuse": true,
			}
		world = following
	return empty
