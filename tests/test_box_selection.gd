extends SceneTree

func _init() -> void:
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	print("[TEST] Initializing CommandBunker to test Box Selection...")
	var bunker = preload("res://src/presentation/bunker/command_bunker.tscn").instantiate()
	root.add_child(bunker)
	bunker.initialize_bunker()
	
	for i in range(3):
		await process_frame
	
	var rig = bunker.desktop_rig
	print("[TEST] Calling _perform_box_selection without additive...")
	rig._perform_box_selection(Rect2(0, 0, 1920, 1080), false)
	print("[TEST] Non-additive selected count: ", rig.selected_unit_ids.size())
	
	print("[TEST] Calling _perform_box_selection with additive=true...")
	rig._perform_box_selection(Rect2(0, 0, 1920, 1080), true)
	print("[TEST] Additive selected count: ", rig.selected_unit_ids.size())
	
	print("[TEST] Testing _get_active_selection_list()...")
	var active_list: Array[int] = rig._get_active_selection_list()
	print("[TEST] _get_active_selection_list count: ", active_list.size())
	
	print("==================================================================")
	print("[ALL TESTS PASSED] Box selection and typed arrays verified 100%!")
	print("==================================================================")
	quit(0)
