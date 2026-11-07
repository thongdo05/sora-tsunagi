extends SceneTree

## Saves a short run / jump / dash sequence for the pull request.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/run.tscn")
	var run: RunRoot = packed.instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	await physics_frame
	run.start_run()
	var dir := OS.get_environment("SORA_FRAME_DIR")
	if dir == "":
		dir = "/tmp/parkour_frames"
	DirAccess.make_dir_recursive_absolute(dir)
	var frame := 0
	for i in 180:
		if i == 18:
			run.controls.dash_pressed = true
		if i == 70:
			run.controls.jump_pressed = true
			run.controls.jump_held = true
		if i == 100:
			run.controls.jump_held = false
		await physics_frame
		if i % 2 == 0:
			await RenderingServer.frame_post_draw
			var image := root.get_viewport().get_texture().get_image()
			if image != null:
				var crop := image.get_region(Rect2i(180, 180, 760, 420))
				crop.save_png("%s/f%03d.png" % [dir, frame])
				frame += 1
		if i == 10 or i == 28 or i == 88:
			await RenderingServer.frame_post_draw
			var full := root.get_viewport().get_texture().get_image()
			if full != null:
				var name := "glassfall-run"
				if i == 88:
					name = "glassfall-jump"
				elif i == 28:
					name = "glassfall-dash"
				full.save_png("/opt/cursor/artifacts/%s.png" % name)
	print("FRAMES", frame)
	quit(0)
