extends SceneTree
## Sprint 18 Automated Adversarial Feature Verification Suite.
## Validates:
## 1. Welcome Onboarding Briefing Controller initialization, visibility, and signals (US-18.1).
## 2. Modal Mutual-Exclusivity Suppression (Welcome vs. Main Menu vs. Tutorial) (US-18.1).
## 3. 5-Step Bootcamp Tutorial Controller flow, lesson sequencing, and demo execution (US-18.2).
## 4. Desktop Command Rig [? BRIEFING] button & 3D Front-Bezel Controls Plaque (US-18.3).

const WelcomeOnboardingControllerScript := preload("res://src/presentation/bunker/welcome_onboarding_controller.gd")
const BunkerMainMenuScript := preload("res://src/presentation/bunker/bunker_main_menu.gd")
const TutorialControllerScript := preload("res://src/presentation/bunker/tutorial_controller.gd")
const CommandBunkerScene := preload("res://src/presentation/bunker/command_bunker.tscn")
const SimDBScript := preload("res://src/autoloads/sim_db.gd")

var total_tests := 0
var passed_tests := 0


func _init() -> void:
	print("==================================================================")
	print("  RUNNING SPRINT 18 FEATURE VERIFICATION SUITE")
	print("==================================================================")

	test_welcome_onboarding_controller()
	test_modal_mutual_exclusivity_and_bunker_rig()
	test_tutorial_controller_progression()

	print("==================================================================")
	print("  SPRINT 18 TEST RESULTS: %d / %d PASSED (%.1f%%)" % [passed_tests, total_tests, float(passed_tests) / float(max(1, total_tests)) * 100.0])
	print("==================================================================")

	if passed_tests == total_tests:
		print(">> ALL SPRINT 18 FEATURES VERIFIED SUCCESSFULLY! <<")
		quit(0)
	else:
		printerr(">> SPRINT 18 TEST FAILURES DETECTED! <<")
		quit(1)


func assert_true(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		printerr("  [FAIL] %s" % test_name)


func test_welcome_onboarding_controller() -> void:
	print("\n--- Test Suite 1: Welcome Onboarding Controller (US-18.1) ---")
	var welcome = WelcomeOnboardingControllerScript.new()
	root.add_child(welcome)
	welcome._ready()

	assert_true(welcome != null, "WelcomeOnboardingController instantiated")
	assert_true(welcome.modal_root != null, "Modal root PanelContainer created")
	assert_true(welcome._title_label != null, "Title label created")
	assert_true(welcome._briefing_text != null, "Briefing doctrine RichTextLabel created")
	assert_true(welcome._controls_text != null, "Controls RichTextLabel created")
	assert_true(welcome._btn_tutorial != null, "Bootcamp Tutorial button created")
	assert_true(welcome._btn_play != null, "Play/Enter War Room button created")
	assert_true(welcome._btn_campaign != null, "Campaign & Theaters button created")
	assert_true(welcome._btn_manual != null, "Field Manual button created")

	# Test initial visibility & open/close toggle
	welcome.set_visible_briefing(true)
	assert_true(welcome.is_briefing_open() == true, "Welcome modal opens on set_visible_briefing(true)")
	welcome.set_visible_briefing(false)
	assert_true(welcome.is_briefing_open() == false, "Welcome modal closes on set_visible_briefing(false)")

	# Test signal emission on button presses
	var flags := {
		"tutorial": false,
		"play": false,
		"campaign": false,
		"manual": false
	}
	welcome.start_tutorial_requested.connect(func(): flags["tutorial"] = true)
	welcome.welcome_dismissed.connect(func(): flags["play"] = true)
	welcome.open_campaign_requested.connect(func(): flags["campaign"] = true)
	welcome.open_manual_requested.connect(func(): flags["manual"] = true)

	welcome.set_visible_briefing(true)
	welcome._btn_tutorial.pressed.emit()
	assert_true(flags["tutorial"], "Tutorial button emits start_tutorial_requested signal")
	assert_true(welcome.is_briefing_open() == false, "Tutorial button automatically closes welcome modal")

	welcome.set_visible_briefing(true)
	welcome._btn_play.pressed.emit()
	assert_true(flags["play"], "Play button emits welcome_dismissed signal")
	assert_true(welcome.is_briefing_open() == false, "Play button automatically closes welcome modal")

	welcome.set_visible_briefing(true)
	welcome._btn_campaign.pressed.emit()
	assert_true(flags["campaign"], "Campaign button emits open_campaign_requested signal")

	welcome.set_visible_briefing(true)
	welcome._btn_manual.pressed.emit()
	assert_true(flags["manual"], "Manual button emits open_manual_requested signal")

	welcome.queue_free()


func test_modal_mutual_exclusivity_and_bunker_rig() -> void:
	print("\n--- Test Suite 2: Bunker Rig & Modal Suppression (US-18.1 / US-18.3) ---")
	var bunker = CommandBunkerScene.instantiate()
	root.add_child(bunker)
	bunker.initialize_bunker()

	assert_true(bunker.welcome_controller != null, "CommandBunker has initialized WelcomeOnboardingController")
	assert_true(bunker.main_menu != null, "CommandBunker has initialized BunkerMainMenu")
	assert_true(bunker.tutorial_controller != null, "CommandBunker has initialized TutorialController")
	assert_true(bunker.desktop_rig != null, "DesktopCommandRig initialized in CommandBunker")
	assert_true(bunker.desktop_rig._briefing_top_btn != null, "DesktopCommandRig has [? BRIEFING & CONTROLS] button")

	# 1. Opening Welcome Briefing should be active
	bunker.welcome_controller.set_visible_briefing(true)
	assert_true(bunker.welcome_controller.is_briefing_open(), "Welcome modal is active")

	# 2. Opening Main Menu must dismiss Welcome Modal
	bunker.main_menu.set_menu_visible(true)
	assert_true(bunker.main_menu.is_menu_open, "Main menu opened")
	assert_true(!bunker.welcome_controller.is_briefing_open(), "Opening Main Menu automatically closed Welcome modal")

	# 3. Starting Bootcamp Tutorial must dismiss Main Menu and Welcome
	bunker.tutorial_controller.start_bootcamp(true)
	assert_true(bunker.tutorial_controller.is_active, "Tutorial is now active")
	assert_true(!bunker.main_menu.is_menu_open, "Starting Tutorial closed Main Menu")
	assert_true(!bunker.welcome_controller.is_briefing_open(), "Starting Tutorial closed Welcome modal")

	# 4. Reopening Welcome Briefing must dismiss Tutorial
	bunker.welcome_controller.set_visible_briefing(true)
	assert_true(bunker.welcome_controller.is_briefing_open(), "Welcome modal reopened")
	assert_true(!bunker.tutorial_controller.is_active, "Reopening Welcome modal dismissed active Tutorial")

	# 5. Test briefing toggle request from desktop rig
	var briefing_initial: bool = bunker.welcome_controller.is_briefing_open()
	bunker.desktop_rig._briefing_top_btn.pressed.emit()
	var briefing_toggled: bool = bunker.welcome_controller.is_briefing_open()
	assert_true(briefing_toggled != briefing_initial, "[? BRIEFING] button toggles Welcome Briefing visibility")

	# 6. Test 3D controls plaque on war table bezel
	assert_true(bunker.controls_plaque != null, "3D Controls Plaque Label3D exists on War Table bezel")
	assert_true(bunker.controls_plaque.text.contains("COMMAND CONTROLS") and bunker.controls_plaque.text.contains("BOOTCAMP"), "3D Controls Plaque text contains tactical command directives")

	bunker.queue_free()


func test_tutorial_controller_progression() -> void:
	print("\n--- Test Suite 3: 5-Step Bootcamp Tutorial Progression (US-18.2) ---")
	var sim_db = SimDBScript.new()
	sim_db.load_database()

	var tutorial = TutorialControllerScript.new()
	root.add_child(tutorial)
	tutorial._ready()
	tutorial.setup(sim_db, null, null, null)

	assert_true(tutorial != null, "TutorialController instantiated")
	assert_true(tutorial.steps.size() == 5, "Tutorial contains exactly 5 MIL-SPEC Bootcamp lessons from SimDB")

	# Check lesson topics
	assert_true(String(tutorial.steps[0].get("title", "")).contains("Zoom") or String(tutorial.steps[0].get("title", "")).contains("Echelon"), "Lesson 1 covers Zoom & Echelon scaling")
	assert_true(String(tutorial.steps[1].get("title", "")).contains("Sensors") or String(tutorial.steps[1].get("title", "")).contains("Radar") or String(tutorial.steps[1].get("title", "")).contains("IADS"), "Lesson 2 covers Sensor overlays / IADS")
	assert_true(String(tutorial.steps[2].get("title", "")).contains("Robot") or String(tutorial.steps[2].get("title", "")).contains("Dog") or String(tutorial.steps[2].get("title", "")).contains("Unmanned"), "Lesson 3 covers Quadruped Robot Dogs & swarms")
	assert_true(String(tutorial.steps[3].get("title", "")).contains("Wikipedia") or String(tutorial.steps[3].get("title", "")).contains("Photo") or String(tutorial.steps[3].get("title", "")).contains("Recon"), "Lesson 4 covers Recon Intelligence Dossiers")
	assert_true(String(tutorial.steps[4].get("title", "")).contains("Alpha Strike") or String(tutorial.steps[4].get("title", "")).contains("DEFCON"), "Lesson 5 covers Strategic Alpha Strike Salvo")

	tutorial.start_bootcamp(true)
	assert_true(tutorial.is_active, "Tutorial started and marked active")
	assert_true(tutorial.current_step_index == 0, "Tutorial starts at Step 0")

	# Step forward through lessons
	tutorial.advance_step()
	assert_true(tutorial.current_step_index == 1, "advance_step() advanced to Step 1")
	tutorial.advance_step()
	assert_true(tutorial.current_step_index == 2, "advance_step() advanced to Step 2")

	# Step backward
	tutorial.prev_step()
	assert_true(tutorial.current_step_index == 1, "prev_step() returned to Step 1")

	# Dismiss tutorial
	tutorial.stop_bootcamp()
	assert_true(!tutorial.is_active, "stop_bootcamp() successfully set tutorial inactive")

	tutorial.queue_free()
