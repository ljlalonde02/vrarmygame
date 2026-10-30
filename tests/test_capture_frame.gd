extends SceneTree

func _init() -> void:
	process_frame.connect(_on_frame, CONNECT_ONE_SHOT)

func _on_frame() -> void:
	print("Testing frame capture...")
	var bunker := CommandBunker.new()
	root.add_child(bunker)
	bunker.initialize_bunker()

	for i in range(5):
		await process_frame

	var img := root.get_texture().get_image()
	if img != null:
		var err := img.save_png("c:/dev/vrarmygame/test_shot.png")
		print("Image captured, size: ", img.get_size(), " format: ", img.get_format(), " err: ", err)
	else:
		print("Image was null!")
	quit(0)
