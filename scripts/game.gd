extends Node2D
@onready var sfx_player = $ClickSound
# =================================================
#                    CONSTANTS
# =================================================
const SAVE_SLOTS = [
	"user://save_slot1.save",
	"user://save_slot2.save",
	"user://save_slot3.save"
]


# =================================================
#                     STATE
# =================================================
var has_loaded := false   # prevents saving before loading finishes
var active_slot: int = -1   # which save slot is currently loaded (-1 = none)
var in_game: bool = false   # true when the game panels are visible


# =================================================
#                GAME VARIABLES
# =================================================
var lotan: float = 0.0            # total currency
var amount_per_click: int = 1    # currency per click
var lps: float = 0.0   #lotan per second (passive income)
var show_shop: int = 0          #show shop button
var lotan_skin: int = 0

# =================================================
#              ACHIEVEMENT TRACKING
# =================================================
var total_clicks: int = 0
var play_time: float = 0.0
var achievements_unlocked: Array = []
var achievement_panel: Control = null
var achievement_notification_queue: Array = []
var achievement_notification_active: bool = false   

# ---- Upgrade 1 ----
var upgrade1_cost: int = 15
var upgrade1_level: int = 0

# ---- Upgrade 2 ----
var upgrade2_cost: int = 125
var upgrade2_level: int = 0

# ---- Upgrade 3 ----
var upgrade3_cost: int = 1000
var upgrade3_level: int = 0

# ---- Upgrade 4 ----
var upgrade4_cost: int = 25000
var upgrade4_level: int = 0

# ---- Upgrade 5 ----
var upgrade5_cost: int = 140000
var upgrade5_level: int = 0

# ---- Upgrade 6 ----
var upgrade6_cost: int = 1000000
var upgrade6_level: int = 0

# ---- Shop 1 ----
var shop1_cost = 150
var shop1_bought = 0;
# ---- Shop 2 ----
var shop2_cost = 1250
var shop2_bought = 0;
# ---- Shop 3 ----
var shop3_cost = 10000
var shop3_bought = 0;
# ---- Shop 4 ----
var shop4_cost = 250000
var shop4_bought = 0;
# ---- Shop 5 ----
var shop5_cost = 1400000
var shop5_bought = 0;
# ---- Shop 6 ----
var shop6_cost = 10000000
var shop6_bought = 0;
# ---- Shop 7 ----
var shop7_cost = 100
var shop7_bought = 0

# =================================================
#         PAGE 2 UPGRADE DEFINITIONS
# =================================================
const UPGRADE_PAGE2 = [
	{ "name": "Tzipi Baron",       "cost": 2000000,    "lps": 5000.0,    "icon": "res://icons/tzipi baron.png",        "icon_black": "res://icons/tzipi baron black.png" },
	{ "name": "Ultra Moodi",       "cost": 10000000,   "lps": 20000.0,   "icon": "res://icons/ultra moodi.png",        "icon_black": "res://icons/ultra moodi black.png" },
	{ "name": "Ultra Sveta",       "cost": 50000000,   "lps": 100000.0,  "icon": "res://icons/ultra sveta.png",        "icon_black": "res://icons/ultra sveta black.png" },
	{ "name": "Ultra Lotan",       "cost": 250000000,  "lps": 500000.0,  "icon": "res://icons/ultra lotan.png",        "icon_black": "res://icons/ultra lotan black.png" },
	{ "name": "The Fantastic Four","cost": 1000000000, "lps": 2500000.0, "icon": "res://icons/the fantastic four.png", "icon_black": "res://icons/the fantastic four black.png" },
]

const SHOP_PAGE2 = [
	{ "name": "Golden Diker",     "cost": 15000,      "effect": "golden_half", "amount": 0.5,   "icon": "res://icons/Lotan Golden cookie.png", "desc": "Golden Diker spawns faster" },
	{ "name": "Barone",           "cost": 50000000,   "effect": "double_p2",   "amount": 0.0,   "icon": "res://icons/barone_upgrade.png",       "desc": "Tzipi Baron is doubled",    "target": 0 },
	{ "name": "Narendra Moodi",   "cost": 250000000,  "effect": "double_p2",   "amount": 0.0,   "icon": "res://icons/Narendra Modi.png",        "desc": "Ultra Moodi is doubled",    "target": 1 },
	{ "name": "Gloves",           "cost": 1000000000, "effect": "double_p2",   "amount": 0.0,   "icon": "res://icons/glove_upgrade.png",        "desc": "Ultra Sveta is doubled",    "target": 2 },
	{ "name": "KKK & Jews",       "cost": 5000000000, "effect": "double_p2",   "amount": 0.0,   "icon": "res://icons/kkk.png",                  "desc": "Ultra Lotan is doubled",    "target": 3 },
	{ "name": "The Golden Squad", "cost": 10000000000,"effect": "double_p2",   "amount": 0.0,   "icon": "res://icons/fantastic_four_upgrade.png","desc": "Fantastic Four is doubled", "target": 4 },
]

# Page 2 runtime state
var upgrade_page2_costs: Array = []
var upgrade_page2_levels: Array = []
var shop_page2_bought: Array = []
var upgrade_current_page: int = 1
var shop_current_page: int = 1
var golden_cookie_time_multiplier: float = 1.0


# =================================================
#                GOLDEN COOKIE VARIABLES
# =================================================
var golden_cookie_active := false
var golden_cookie_buff_active := false
var golden_cookie_fade_tween: Tween
var golden_cookie_base_lps: float = 0.0


# =================================================
#                     SIGNALS
# =================================================
signal lotan_change
signal lotan_clicked

# =================================================
#                   LIFECYCLE
# =================================================
func _ready() -> void:
	has_loaded = true
	$BackgroundMusic.play()
	emit_signal("lotan_change", lotan)
	update_ui()
	show_upgrades()
	$Main_Menu/BackButton.hide()
	$Main_Menu/SvetaButton.hide()
	$Main_Menu/LotanButton.hide()
	$Main_Menu/NewGameButton.show()
	$Main_Menu/ContinueButton.show()
	$Main_Menu/ExitButton.show()
	$leftPanel.hide()
	$rightPanel.hide()

	# ---- Achievement setup ----
	_build_achievement_panel()
	_build_achievement_button()

	# ---- Page 2 init ----
	for i in range(UPGRADE_PAGE2.size()):
		upgrade_page2_costs.append(UPGRADE_PAGE2[i]["cost"])
		upgrade_page2_levels.append(0)
	for i in range(SHOP_PAGE2.size()):
		shop_page2_bought.append(0)
	_build_page_buttons()

	# ---- Sound label setup ----
	_setup_sound_label()

	# ---- Save slot UI panels (created at runtime, hidden by default) ----
	_build_slot_picker_ui()

	# ---- Golden Cookie setup ----
	_setup_golden_cookie()

	## DEBUG BUTTON - remove before release!
	#var debug_btn := Button.new()
	#debug_btn.text = "DEBUG: All Achievements"
	#debug_btn.position = Vector2(10, 10)
	#debug_btn.custom_minimum_size = Vector2(200, 40)
	#debug_btn.pressed.connect(func():
		#if active_slot < 0:
			#active_slot = 0
		#for ach in ACHIEVEMENTS:
			#if not ach["id"] in achievements_unlocked:
				#achievements_unlocked.append(ach["id"])
		#save_data()
		#print("All achievements unlocked and saved!")
	#)
	#add_child(debug_btn)
#
	#var debug_clear_btn := Button.new()
	#debug_clear_btn.text = "DEBUG: Clear Achievements"
	#debug_clear_btn.position = Vector2(10, 55)
	#debug_clear_btn.custom_minimum_size = Vector2(200, 40)
	#debug_clear_btn.pressed.connect(func():
		#achievements_unlocked = []
		## Clear from all save slots
		#for i in range(3):
			#var path = SAVE_SLOTS[i]
			#if not FileAccess.file_exists(path):
				#continue
			#var file = FileAccess.open(path, FileAccess.READ)
			#var data = file.get_var()
			#file.close()
			#if typeof(data) == TYPE_DICTIONARY:
				#data["achievements_unlocked"] = []
				#var wfile = FileAccess.open(path, FileAccess.WRITE)
				#wfile.store_var(data)
				#wfile.close()
		#print("All achievements cleared from all slots!")
	#)
	#add_child(debug_clear_btn)
#
	#var debug_reset_btn := Button.new()
	#debug_reset_btn.text = "DEBUG: Full Reset"
	#debug_reset_btn.position = Vector2(10, 100)
	#debug_reset_btn.custom_minimum_size = Vector2(200, 40)
	#debug_reset_btn.pressed.connect(func():
		## Delete all save files
		#for path in SAVE_SLOTS:
			#if FileAccess.file_exists(path):
				#DirAccess.remove_absolute(path)
		## Reset all in-memory state
		#reset()
		#active_slot = -1
		#in_game = false
		## Go back to main menu
		#$leftPanel.hide()
		#$rightPanel.hide()
		#$Main_Menu/NewGameButton.show()
		#$Main_Menu/ContinueButton.show()
		#$Main_Menu/ExitButton.show()
		#$Main_Menu/BackButton.hide()
		#$Main_Menu/SvetaButton.hide()
		#$Main_Menu/LotanButton.hide()
		#print("Full reset done!")
	#)
	#add_child(debug_reset_btn)


func _process(delta: float) -> void:
	lotan += lps * delta
	if in_game:
		play_time += delta
		_check_achievements()
	update_ui()


# =================================================
#                     UI
# =================================================
func _auto_font_size(btn: Button) -> void:
	var l = btn.text.length()
	if l < 40:
		btn.add_theme_font_size_override("font_size", 14)
	elif l < 55:
		btn.add_theme_font_size_override("font_size", 11)
	else:
		btn.add_theme_font_size_override("font_size", 9)


func _auto_font_size_p2(btn: Button) -> void:
	var l = btn.text.length()
	if l < 30:
		btn.add_theme_font_size_override("font_size", 16)
	elif l < 45:
		btn.add_theme_font_size_override("font_size", 13)
	else:
		btn.add_theme_font_size_override("font_size", 11)


func update_ui() -> void:
	# ---- Page 2 UI ----
	if upgrade_current_page == 2:
		_update_upgrade_p2_ui()
	if shop_current_page == 2:
		_update_shop_p2_ui()

	# ---- Stats ----
	if lotan_skin ==0:
		$leftPanel/MarginContainer/Stats/Lotans.text = "Lotans: " + str(int(lotan))
		$leftPanel/MarginContainer/Stats/LPS.text = "Lotans per second: " + str(lps)
	else:
		$leftPanel/MarginContainer/Stats/Lotans.text = "Svetas: " + str(int(lotan))
		$leftPanel/MarginContainer/Stats/LPS.text = "Svetas per second: " + str(lps)

	# ---- Upgrade 1 Button ----

	if upgrade1_level == 0:
		$rightPanel/Upgrades/Upgrade1_Button.text = \
		"??? (Cost: " + _format_number(upgrade1_cost) + ") x" + str(upgrade1_level)
	else:
		$rightPanel/Upgrades/Upgrade1_Button.text = \
		"Moodi (Cost: " + _format_number(upgrade1_cost) + ") x" + str(upgrade1_level)
	$rightPanel/Upgrades/Upgrade1_Button.disabled = lotan < upgrade1_cost
	_auto_font_size($rightPanel/Upgrades/Upgrade1_Button)

	# ---- Upgrade 2 Button ----
	if upgrade2_level == 0:
		$rightPanel/Upgrades/Upgrade2_Button.text = \
		"??? (Cost: " + _format_number(upgrade2_cost) + ") x" + str(upgrade2_level)
	else:
		$rightPanel/Upgrades/Upgrade2_Button.text = \
		"Ben Bassat (Cost: " + _format_number(upgrade2_cost) + ") x" + str(upgrade2_level)
	$rightPanel/Upgrades/Upgrade2_Button.disabled = lotan < upgrade2_cost
	_auto_font_size($rightPanel/Upgrades/Upgrade2_Button)
	
		# ---- Upgrade 3 Button ----
	if upgrade3_level == 0:
		$rightPanel/Upgrades/Upgrade3_Button.text = \
		"??? (Cost: " + _format_number(upgrade3_cost) + ") x" + str(upgrade3_level)
	else:
		$rightPanel/Upgrades/Upgrade3_Button.text = \
		"Sharon (Cost: " + _format_number(upgrade3_cost) + ") x" + str(upgrade3_level)
	$rightPanel/Upgrades/Upgrade3_Button.disabled = lotan < upgrade3_cost
	_auto_font_size($rightPanel/Upgrades/Upgrade3_Button)

	# ---- Upgrade 4 Button ----
	if upgrade4_level == 0:
		$rightPanel/Upgrades/Upgrade4_Button.text = \
		"??? (Cost: " + _format_number(upgrade4_cost) + ") x" + str(upgrade4_level)
	else:
		$rightPanel/Upgrades/Upgrade4_Button.text = \
		"Sergei (Cost: " + _format_number(upgrade4_cost) + ") x" + str(upgrade4_level)
	$rightPanel/Upgrades/Upgrade4_Button.disabled = lotan < upgrade4_cost
	_auto_font_size($rightPanel/Upgrades/Upgrade4_Button)
	
		# ---- Upgrade 5 Button ----
	if upgrade5_level == 0:
		$rightPanel/Upgrades/Upgrade5_Button.text = \
		"??? (Cost: " + _format_number(upgrade5_cost) + ") x" + str(upgrade5_level)
	else:
		$rightPanel/Upgrades/Upgrade5_Button.text = \
		"Sveta (Cost: " + _format_number(upgrade5_cost) + ") x" + str(upgrade5_level)
	$rightPanel/Upgrades/Upgrade5_Button.disabled = lotan < upgrade5_cost
	_auto_font_size($rightPanel/Upgrades/Upgrade5_Button)
	
		# ---- Upgrade 6 Button ----
	if upgrade6_level == 0:
		$rightPanel/Upgrades/Upgrade6_Button.text = \
		"??? (Cost: " + _format_number(upgrade6_cost) + ") x" + str(upgrade6_level)
	else:
		$rightPanel/Upgrades/Upgrade6_Button.text = \
		"SLIM LOTAN (Cost: " + _format_number(upgrade6_cost) + ") x" + str(upgrade6_level)
	$rightPanel/Upgrades/Upgrade6_Button.disabled = lotan < upgrade6_cost
	_auto_font_size($rightPanel/Upgrades/Upgrade6_Button)
	
	# ----- Shop 1 Button ----
	$rightPanel/Shops/Shop1_Button.disabled = lotan < shop1_cost
	if show_shop == 0:
		$rightPanel/Shops/Shop1_Icon.hide()
		$rightPanel/Shops/Shop1_Label.hide()
		$rightPanel/Shops/Shop1_Button.hide()
		
	$rightPanel/Shops/Shop1_Button.text = \
		"Moodle\n  Moodi is doubled (Cost: 150)"
	if shop1_bought ==1:
		$rightPanel/Shops/Shop1_Button.disabled = true
		$rightPanel/Shops/Shop1_Button.text = "Purchased"
		
		# ----- Shop 2 Button ----
	$rightPanel/Shops/Shop2_Button.disabled = lotan < shop2_cost
	if show_shop == 0:
		$rightPanel/Shops/Shop2_Icon.hide()
		$rightPanel/Shops/Shop2_Label.hide()
		$rightPanel/Shops/Shop2_Button.hide()
		
	$rightPanel/Shops/Shop2_Button.text = \
		"Basat ear\n  Ben Bassat is doubled (Cost: 1250)"
	if shop2_bought ==1:
		$rightPanel/Shops/Shop2_Button.disabled = true
		$rightPanel/Shops/Shop2_Button.text = "Purchased"
		
	# ----- Shop 3 Button ----
	$rightPanel/Shops/Shop3_Button.disabled = lotan < shop3_cost
	if show_shop == 0:
		$rightPanel/Shops/Shop3_Icon.hide()
		$rightPanel/Shops/Shop3_Label.hide()
		$rightPanel/Shops/Shop3_Button.hide()
		
	$rightPanel/Shops/Shop3_Button.text = \
		"David\n  Sharon is doubled (Cost: 10000)"
	if shop3_bought ==1:
		$rightPanel/Shops/Shop3_Button.disabled = true
		$rightPanel/Shops/Shop3_Button.text = "Purchased"
		
	# ----- Shop 4 Button ----
	$rightPanel/Shops/Shop4_Button.disabled = lotan < shop4_cost
	if show_shop == 0:
		$rightPanel/Shops/Shop4_Icon.hide()
		$rightPanel/Shops/Shop4_Label.hide()
		$rightPanel/Shops/Shop4_Button.hide()
		
	$rightPanel/Shops/Shop4_Button.text = \
		"glassess\n  sergei is doubled (Cost: 250000)"
	if shop4_bought ==1:
		$rightPanel/Shops/Shop4_Button.disabled = true
		$rightPanel/Shops/Shop4_Button.text = "Purchased"
		
	# ----- Shop 5 Button ----
	$rightPanel/Shops/Shop5_Button.disabled = lotan < shop5_cost
	if show_shop == 0:
		$rightPanel/Shops/Shop5_Icon.hide()
		$rightPanel/Shops/Shop5_Label.hide()
		$rightPanel/Shops/Shop5_Button.hide()
		
	$rightPanel/Shops/Shop5_Button.text = \
		"Kefir\n  Sveta is doubled (Cost: 1.4M)"
	if shop5_bought ==1:
		$rightPanel/Shops/Shop5_Button.disabled = true
		$rightPanel/Shops/Shop5_Button.text = "Purchased"
		
	# ----- Shop 6 Button ----
	$rightPanel/Shops/Shop6_Button.disabled = lotan < shop6_cost
	if show_shop == 0:
		$rightPanel/Shops/Shop6_Icon.hide()
		$rightPanel/Shops/Shop6_Label.hide()
		$rightPanel/Shops/Shop6_Button.hide()
		
	$rightPanel/Shops/Shop6_Button.text = \
		"Burger King\n  Slim Lotan is doubled (Cost: 10M)"
	if shop6_bought ==1:
		$rightPanel/Shops/Shop6_Button.disabled = true
		$rightPanel/Shops/Shop6_Button.text = "Purchased"
		
	# ----- Shop 7 Button ----
	$rightPanel/Shops/Shop7_Button.disabled = lotan < shop7_cost
	if show_shop == 0:
		$rightPanel/Shops/Shop7_Icon.hide()
		$rightPanel/Shops/Shop7_Label.hide()
		$rightPanel/Shops/Shop7_Button.hide()
	
	if shop7_bought ==0:
		$rightPanel/Shops/Shop7_Button.text = \
		"Lotan Click \n Lotan is doubled (Cost: 100)"
	if shop7_bought ==1:
		$rightPanel/Shops/Shop7_Icon.texture = preload("res://icons/lotdik2.png")
		$rightPanel/Shops/Shop7_Button.text = \
		"Lotan Click \n Lotan is doubled (Cost: 200)"
	if shop7_bought ==2:
		$rightPanel/Shops/Shop7_Icon.texture = preload("res://icons/lotdik3.png")
		$rightPanel/Shops/Shop7_Button.text = \
		"Lotan Click \n Lotan is doubled (Cost: 400)"
	if shop7_bought ==3:
		$rightPanel/Shops/Shop7_Button.disabled = true
		$rightPanel/Shops/Shop7_Button.text = "Purchased"

func show_upgrades() -> void:
	# ---- Upgrade 1 icon ----
	if upgrade1_level == 0:
		$rightPanel/Upgrades/Upgrade1_Icon.texture = preload("res://icons/moodi_black.png")
	else:
		$rightPanel/Upgrades/Upgrade1_Icon.texture = preload("res://icons/moodi.png")

	# ---- Upgrade 2 icon ----
	if upgrade2_level == 0:
		$rightPanel/Upgrades/Upgrade2_Icon.texture = preload("res://icons/benbasat_black.png")
	else:
		$rightPanel/Upgrades/Upgrade2_Icon.texture = preload("res://icons/benbasat.png")
		
			# ---- Upgrade 3 icon ----
	if upgrade3_level == 0:
		$rightPanel/Upgrades/Upgrade3_Icon.texture = preload("res://icons/sharon_black.png")
	else:
		$rightPanel/Upgrades/Upgrade3_Icon.texture = preload("res://icons/sharon.png")
		
			# ---- Upgrade 4 icon ----
	if upgrade4_level == 0:
		$rightPanel/Upgrades/Upgrade4_Icon.texture = preload("res://icons/sergei_black.png")
	else:
		$rightPanel/Upgrades/Upgrade4_Icon.texture = preload("res://icons/sergei.png")
		
					# ---- Upgrade 5 icon ----
	if upgrade5_level == 0:
		$rightPanel/Upgrades/Upgrade5_Icon.texture = preload("res://icons/sveta_black.png")
	else:
		$rightPanel/Upgrades/Upgrade5_Icon.texture = preload("res://icons/sveta.png")
		
# ---- Upgrade 6 icon ----
	if upgrade6_level == 0:
		$rightPanel/Upgrades/Upgrade6_Icon.texture = preload("res://icons/slim_lotan_black.png")
	else:
		$rightPanel/Upgrades/Upgrade6_Icon.texture = preload("res://icons/slim_lotan.png")


# =================================================
#                  SAVE / LOAD
# =================================================
func save_data() -> void:
	if not has_loaded:
		return   # never save before loading finishes
	if active_slot < 0:
		return   # no slot selected yet

	var data = {
		"lotan": lotan,
		"lps": lps,
		"upgrade1_cost": upgrade1_cost,
		"upgrade1_level": upgrade1_level,
		"upgrade2_cost": upgrade2_cost,
		"upgrade2_level": upgrade2_level,
		"upgrade3_cost": upgrade3_cost,
		"upgrade3_level": upgrade3_level,
		"upgrade4_cost": upgrade4_cost,
		"upgrade4_level": upgrade4_level,
		"upgrade5_cost": upgrade5_cost,
		"upgrade5_level": upgrade5_level,
		"upgrade6_cost": upgrade6_cost,
		"upgrade6_level": upgrade6_level,
		"shop1_bought": shop1_bought,
		"shop2_bought": shop2_bought,
		"shop3_bought": shop3_bought,
		"shop4_bought": shop4_bought,
		"shop5_bought": shop5_bought,
		"shop6_bought": shop6_bought,
		"shop7_bought": shop7_bought,
		"shop7_cost": shop7_cost,
		"amount_per_click": amount_per_click,
		"last_played": Time.get_unix_time_from_system(),
		"lotan_skin" : lotan_skin,
		"total_clicks": total_clicks,
		"play_time": play_time,
		"golden_cookies_clicked": golden_cookies_clicked,
		"achievements_unlocked": achievements_unlocked,
		"upgrade_page2_costs": upgrade_page2_costs,
		"upgrade_page2_levels": upgrade_page2_levels,
		"shop_page2_bought": shop_page2_bought,
		"golden_cookie_time_multiplier": golden_cookie_time_multiplier
	}

	var file = FileAccess.open(SAVE_SLOTS[active_slot], FileAccess.WRITE)
	file.store_var(data)
	file.close()


func load_data(slot: int) -> void:
	active_slot = slot
	var path = SAVE_SLOTS[slot]
	if not FileAccess.file_exists(path):
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	file.close()

	if typeof(data) == TYPE_DICTIONARY:
		lotan = data.get("lotan", 0.0)
		lps = data.get("lps", 0.0)

		upgrade1_cost = data.get("upgrade1_cost", 15)
		upgrade1_level = data.get("upgrade1_level", 0)

		upgrade2_cost = data.get("upgrade2_cost", 125)
		upgrade2_level = data.get("upgrade2_level", 0)
		
		upgrade3_cost = data.get("upgrade3_cost", 1000)
		upgrade3_level = data.get("upgrade3_level", 0)
		
		upgrade4_cost = data.get("upgrade4_cost", 25000)
		upgrade4_level = data.get("upgrade4_level", 0)
		
		upgrade5_cost = data.get("upgrade5_cost", 140000)
		upgrade5_level = data.get("upgrade5_level", 0)
		
		upgrade6_cost = data.get("upgrade6_cost", 1000000)
		upgrade6_level = data.get("upgrade6_level", 0)
		
		shop1_bought = int(data.get("shop1_bought", 0))
		shop2_bought = int(data.get("shop2_bought", 0))
		shop3_bought = int(data.get("shop3_bought", 0))
		shop4_bought = int(data.get("shop4_bought", 0))
		shop5_bought = int(data.get("shop5_bought", 0))
		shop6_bought = int(data.get("shop6_bought", 0))
		shop7_bought = int(data.get("shop7_bought", 0))
		shop7_cost = int(data.get("shop7_cost", 100))
		amount_per_click = data.get("amount_per_click",1)
		lotan_skin = int(data.get("lotan_skin", 1))
		total_clicks = int(data.get("total_clicks", 0))
		play_time = float(data.get("play_time", 0.0))
		golden_cookies_clicked = int(data.get("golden_cookies_clicked", 0))
		achievements_unlocked = data.get("achievements_unlocked", [])
		upgrade_page2_costs = data.get("upgrade_page2_costs", [])
		upgrade_page2_levels = data.get("upgrade_page2_levels", [])
		shop_page2_bought = data.get("shop_page2_bought", [])
		golden_cookie_time_multiplier = data.get("golden_cookie_time_multiplier", 1.0)
		# Fill defaults if arrays are wrong size
		while upgrade_page2_costs.size() < UPGRADE_PAGE2.size():
			upgrade_page2_costs.append(UPGRADE_PAGE2[upgrade_page2_costs.size()]["cost"])
		while upgrade_page2_levels.size() < UPGRADE_PAGE2.size():
			upgrade_page2_levels.append(0)
		while shop_page2_bought.size() < SHOP_PAGE2.size():
			shop_page2_bought.append(0)


		
		# Offline progress
		var last_played = data.get("last_played", Time.get_unix_time_from_system())
		var time_passed = Time.get_unix_time_from_system() - last_played
		if time_passed > 0:
			var offline_gain = lps * time_passed *0.01
			lotan += offline_gain
			print("Gained ", offline_gain, " Lotans while offline!")
	else:
		# corrupted save → rewrite
		save_data()


# =================================================
#                PLAYER INPUT
# =================================================
func _on_click_button_button_down() -> void:
	lotan += amount_per_click
	total_clicks += 1
	emit_signal("lotan_change", lotan)
	emit_signal("lotan_clicked", amount_per_click)
	sfx_player.play()
	save_data()
	 


# =================================================
#                 UPGRADE 1
# =================================================
func _on_upgrade_button_pressed() -> void:
	sfx_player.play()
	if lotan < upgrade1_cost:
		return

	lotan -= upgrade1_cost

	# Upgrade effect
	if shop1_bought==0:
		lps += 0.1
	else:
		lps += 0.2
	upgrade1_level += 1

	# Cost scaling
	upgrade1_cost = int(upgrade1_cost * 1.2)

	save_data()
	show_upgrades()
	update_ui()


# =================================================
#                 UPGRADE 2
# =================================================
func _on_upgrade2_button_pressed() -> void:
	sfx_player.play()
	if lotan < upgrade2_cost:
		return

	lotan -= upgrade2_cost

	# Upgrade effect
	if shop2_bought==0:
		lps += 1
	else:
		lps += 2
	upgrade2_level += 1

	# Cost scaling
	upgrade2_cost = int(upgrade2_cost * 1.2)

	save_data()
	show_upgrades()
	update_ui()
	
# =================================================
#                 UPGRADE 3
# =================================================
func _on_upgrade3_button_pressed() -> void:
	sfx_player.play()
	if lotan < upgrade3_cost:
		return

	lotan -= upgrade3_cost

	# Upgrade effect
	if shop3_bought==0:
		lps += 5
	else:
		lps += 10
	upgrade3_level += 1

	# Cost scaling
	upgrade3_cost = int(upgrade3_cost * 1.2)

	save_data()
	show_upgrades()
	update_ui()

# =================================================
#                 UPGRADE 4
# =================================================
func _on_upgrade4_button_pressed() -> void:
	sfx_player.play()
	if lotan < upgrade4_cost:
		return

	lotan -= upgrade4_cost

	# Upgrade effect
	if shop4_bought==0:
		lps += 50
	else:
		lps += 100
	upgrade4_level += 1

	# Cost scaling
	upgrade4_cost = int(upgrade4_cost * 1.2)

	save_data()
	show_upgrades()
	update_ui()
	
	# =================================================
#                 UPGRADE 5
# =================================================
func _on_upgrade5_button_pressed() -> void:
	sfx_player.play()
	if lotan < upgrade5_cost:
		return

	lotan -= upgrade5_cost

		# Upgrade effect
	if shop5_bought==0:
		lps += 250
	else:
		lps += 500
	upgrade5_level += 1

	# Cost scaling
	upgrade5_cost = int(upgrade5_cost * 1.7)

	save_data()
	show_upgrades()
	update_ui()
	
	
	# =================================================
#                 UPGRADE 6
# =================================================
func _on_upgrade6_button_pressed() -> void:
	sfx_player.play()
	if lotan < upgrade6_cost:
		return

	lotan -= upgrade6_cost

		# Upgrade effect
	if shop6_bought==0:
		lps += 1250
	else:
		lps += 3000
	upgrade6_level += 1

	# Cost scaling
	upgrade6_cost = int(upgrade6_cost * 1.2)

	save_data()
	show_upgrades()
	update_ui()
	

	# =================================================
#                 SHOP 1
# =================================================
func _on_shop1_button_pressed() -> void:
	sfx_player.play()
	if lotan < shop1_cost:
		return
	lotan -= shop1_cost
	lps = lps + (upgrade1_level*0.1)
	shop1_bought=1
	save_data()
	show_upgrades()
	update_ui()
	
	# =================================================
#                 SHOP 2
# =================================================
func _on_shop2_button_pressed() -> void:
	sfx_player.play()
	if lotan < shop2_cost:
		return
	lotan -= shop2_cost
	lps = lps + (upgrade2_level*1)
	shop2_bought=1
	save_data()
	show_upgrades()
	update_ui()
	
		# =================================================
#                 SHOP 3
# =================================================
func _on_shop3_button_pressed() -> void:
	sfx_player.play()
	if lotan < shop3_cost:
		return
	lotan -= shop3_cost
	lps = lps + (upgrade3_level*5)
	shop3_bought=1
	save_data()
	show_upgrades()
	update_ui()
	
			# =================================================
#                 SHOP 4
# =================================================
func _on_shop4_button_pressed() -> void:
	sfx_player.play()
	if lotan < shop4_cost:
		return
	lotan -= shop4_cost
	lps = lps + (upgrade4_level*50)
	shop4_bought=1
	save_data()
	show_upgrades()
	update_ui()
	
	
			# =================================================
#                 SHOP 5
# =================================================
func _on_shop5_button_pressed() -> void:
	sfx_player.play()
	if lotan < shop5_cost:
		return
	lotan -= shop5_cost
	lps = lps + (upgrade5_level*250)
	shop5_bought=1
	save_data()
	show_upgrades()
	update_ui()
	
			# =================================================
#                 SHOP 6
# =================================================
func _on_shop6_button_pressed() -> void:
	sfx_player.play()
	if lotan < shop6_cost:
		return
	lotan -= shop6_cost
	lps = lps + (upgrade6_level*1250)
	shop6_bought=1
	save_data()
	show_upgrades()
	update_ui()
		# =================================================
	#                 SHOP 7
# =================================================
func _on_shop7_button_pressed() -> void:
	sfx_player.play()
	if lotan < shop7_cost && shop7_bought<3:
		return
	lotan -= shop7_cost
	if shop7_bought==0:
		amount_per_click=2
	if shop7_bought==1:
		amount_per_click=4
	if shop7_bought==2:
		amount_per_click=8
	shop7_bought+=1
	shop7_cost*=2
	
	save_data()
	show_upgrades()
	update_ui()
		# =================================================
#                 SHOP
# =================================================
	
func _on_shop_button_pressed() -> void:
	sfx_player.play()
	if show_shop == 0:
		$rightPanel/Upgrades/Shop_Label.text = \
		"SECRET UPGRADES"
		# ---- Upgrade 1 ----
		$rightPanel/Upgrades/Upgrade1_Icon.hide()
		$rightPanel/Upgrades/Upgrade1_Label.hide()
		$rightPanel/Upgrades/Upgrade1_Button.hide()
		$rightPanel/Shops/Shop1_Icon.show()
		$rightPanel/Shops/Shop1_Label.show()
		$rightPanel/Shops/Shop1_Button.show()
		$rightPanel/Shops/Shop2_Icon.show()
		$rightPanel/Shops/Shop2_Label.show()
		$rightPanel/Shops/Shop2_Button.show()
		$rightPanel/Shops/Shop3_Icon.show()
		$rightPanel/Shops/Shop3_Label.show()
		$rightPanel/Shops/Shop3_Button.show()
		$rightPanel/Shops/Shop4_Icon.show()
		$rightPanel/Shops/Shop4_Label.show()
		$rightPanel/Shops/Shop4_Button.show()
		$rightPanel/Shops/Shop5_Icon.show()
		$rightPanel/Shops/Shop5_Label.show()
		$rightPanel/Shops/Shop5_Button.show()
		$rightPanel/Shops/Shop6_Icon.show()
		$rightPanel/Shops/Shop6_Label.show()
		$rightPanel/Shops/Shop6_Button.show()
		$rightPanel/Shops/Shop7_Icon.show()
		$rightPanel/Shops/Shop7_Label.show()
		$rightPanel/Shops/Shop7_Button.show()

		# ---- Upgrade 2 ----
		$rightPanel/Upgrades/Upgrade2_Icon.hide()
		$rightPanel/Upgrades/Upgrade2_Label.hide()
		$rightPanel/Upgrades/Upgrade2_Button.hide()

		# ---- Upgrade 3 ----
		$rightPanel/Upgrades/Upgrade3_Icon.hide()
		$rightPanel/Upgrades/Upgrade3_Label.hide()
		$rightPanel/Upgrades/Upgrade3_Button.hide()

		# ---- Upgrade 4 ----
		$rightPanel/Upgrades/Upgrade4_Icon.hide()
		$rightPanel/Upgrades/Upgrade4_Label.hide()
		$rightPanel/Upgrades/Upgrade4_Button.hide()

		# ---- Upgrade 5 ----
		$rightPanel/Upgrades/Upgrade5_Icon.hide()
		$rightPanel/Upgrades/Upgrade5_Label.hide()
		$rightPanel/Upgrades/Upgrade5_Button.hide()

		# ---- Upgrade 6 ----
		$rightPanel/Upgrades/Upgrade6_Icon.hide()
		$rightPanel/Upgrades/Upgrade6_Label.hide()
		$rightPanel/Upgrades/Upgrade6_Button.hide()

		show_shop = 1
		# Show shop page button, hide upgrade page button, reset to page 1
		var spb = $rightPanel.get_node_or_null("ShopPageBtn")
		if spb: spb.visible = true
		var upb = $rightPanel.get_node_or_null("UpgradePageBtn")
		if upb: upb.visible = false
		shop_current_page = 1
	else:
		$rightPanel/Upgrades/Shop_Label.text = \
		"UPGRADES"
		# Hide shop page button, show upgrade page button, reset both to page 1
		var spb = $rightPanel.get_node_or_null("ShopPageBtn")
		if spb: spb.visible = false
		var upb = $rightPanel.get_node_or_null("UpgradePageBtn")
		if upb: upb.visible = true
		shop_current_page = 1
		upgrade_current_page = 1
		_refresh_upgrade_pages()
		# ---- Upgrade 1 ----
		$rightPanel/Upgrades/Upgrade1_Icon.show()
		$rightPanel/Upgrades/Upgrade1_Label.show()
		$rightPanel/Upgrades/Upgrade1_Button.show()
		$rightPanel/Shops/Shop1_Icon.hide()
		$rightPanel/Shops/Shop1_Label.hide()
		$rightPanel/Shops/Shop1_Button.hide()
		$rightPanel/Shops/Shop2_Icon.hide()
		$rightPanel/Shops/Shop2_Label.hide()
		$rightPanel/Shops/Shop2_Button.hide()
		$rightPanel/Shops/Shop3_Icon.hide()
		$rightPanel/Shops/Shop3_Label.hide()
		$rightPanel/Shops/Shop3_Button.hide()
		$rightPanel/Shops/Shop4_Icon.hide()
		$rightPanel/Shops/Shop4_Label.hide()
		$rightPanel/Shops/Shop4_Button.hide()
		$rightPanel/Shops/Shop5_Icon.hide()
		$rightPanel/Shops/Shop5_Label.hide()
		$rightPanel/Shops/Shop5_Button.hide()
		$rightPanel/Shops/Shop6_Icon.hide()
		$rightPanel/Shops/Shop6_Label.hide()
		$rightPanel/Shops/Shop6_Button.hide()
		$rightPanel/Shops/Shop7_Icon.hide()
		$rightPanel/Shops/Shop7_Label.hide()
		$rightPanel/Shops/Shop7_Button.hide()

		# ---- Upgrade 2 ----
		$rightPanel/Upgrades/Upgrade2_Icon.show()
		$rightPanel/Upgrades/Upgrade2_Label.show()
		$rightPanel/Upgrades/Upgrade2_Button.show()

		# ---- Upgrade 3 ----
		$rightPanel/Upgrades/Upgrade3_Icon.show()
		$rightPanel/Upgrades/Upgrade3_Label.show()
		$rightPanel/Upgrades/Upgrade3_Button.show()

		# ---- Upgrade 4 ----
		$rightPanel/Upgrades/Upgrade4_Icon.show()
		$rightPanel/Upgrades/Upgrade4_Label.show()
		$rightPanel/Upgrades/Upgrade4_Button.show()

		# ---- Upgrade 5 ----
		$rightPanel/Upgrades/Upgrade5_Icon.show()
		$rightPanel/Upgrades/Upgrade5_Label.show()
		$rightPanel/Upgrades/Upgrade5_Button.show()

		# ---- Upgrade 6 ----
		$rightPanel/Upgrades/Upgrade6_Icon.show()
		$rightPanel/Upgrades/Upgrade6_Label.show()
		$rightPanel/Upgrades/Upgrade6_Button.show()

		show_shop = 0


# =================================================
#                  AUTO SAVE
# =================================================
func _on_auto_save_timer_timeout() -> void:
	save_data()
	show_upgrades()
	
func reset() -> void:
	lotan = 0 #amount of lotan
	amount_per_click = 1
	lps = 0.0 #Lotan per second
	upgrade1_cost=15
	upgrade1_level =0
	upgrade2_cost=125
	upgrade2_level =0
	upgrade3_cost=1000
	upgrade3_level =0
	upgrade4_cost=25000
	upgrade4_level =0
	upgrade5_cost=140000
	upgrade5_level =0
	upgrade6_cost=1000000
	upgrade6_level =0
	shop1_bought=0
	shop2_bought=0
	shop3_bought=0
	shop4_bought=0
	shop5_bought=0
	shop6_bought=0
	shop7_bought=0
	shop7_cost=100
	total_clicks = 0
	play_time = 0.0
	golden_cookies_clicked = 0
	achievements_unlocked = []
	upgrade_page2_costs = []
	upgrade_page2_levels = []
	shop_page2_bought = []
	golden_cookie_time_multiplier = 1.0
	for i in range(UPGRADE_PAGE2.size()):
		upgrade_page2_costs.append(UPGRADE_PAGE2[i]["cost"])
		upgrade_page2_levels.append(0)
	for i in range(SHOP_PAGE2.size()):
		shop_page2_bought.append(0)
	# Also cancel any active golden cookie buff on reset
	_cancel_golden_cookie_buff()
	

func _on_reset_button_pressed() -> void:
	sfx_player.play()
	in_game = false
	active_slot = -1
	slot_picker_panel.hide()
	$Main_Menu/BackButton.hide()
	$Main_Menu/SvetaButton.hide()
	$Main_Menu/LotanButton.hide()
	$Main_Menu/NewGameButton.show()
	$Main_Menu/ContinueButton.show()
	$Main_Menu/ExitButton.show()
	$leftPanel.hide()
	$rightPanel.hide()
 	




func _on_new_game_button_pressed() -> void:
	sfx_player.play()
	_show_slot_picker("new")

func _on_back_button_pressed() -> void:
	sfx_player.play()
	slot_picker_panel.hide()
	$Main_Menu/BackButton.hide()
	$Main_Menu/SvetaButton.hide()
	$Main_Menu/LotanButton.hide()
	$Main_Menu/NewGameButton.show()
	$Main_Menu/ContinueButton.show()
	$Main_Menu/ExitButton.show()


func _on_exit_button_pressed() -> void:
	sfx_player.play()
	if OS.has_feature("web"):
		# A web page can't force-close its own tab/window (browser security
		# restriction) — get_tree().quit() would just halt the engine loop
		# and freeze the last frame instead. Best-effort close (works for an
		# installed standalone PWA window in some browsers) and otherwise
		# just leave the app running at the menu instead of freezing it.
		JavaScriptBridge.eval("window.close();")
	else:
		get_tree().quit()


func _on_lotan_button_pressed() -> void:
	sfx_player.play()
	reset()
	lotan_skin = 0
	_start_game()
	
	
func _on_sveta_button_pressed() -> void:
	sfx_player.play()
	reset()
	lotan_skin = 1
	_start_game()


func _on_continue_button_pressed() -> void:
	sfx_player.play()
	_show_slot_picker("continue")
	
	
	
	
	

	
var sound_level: int = 4  # 0=mute, 1=25%, 2=50%, 3=75%, 4=100%
var sound_label: Label = null

func _setup_sound_label() -> void:
	sound_label = Label.new()
	sound_label.name = "SoundLabel"
	sound_label.text = "100%"
	var btn = $Main_Menu/SoundButton
	sound_label.position = Vector2(btn.position.x, btn.position.y + btn.size.y + 4)
	sound_label.size.x = btn.size.x
	sound_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Match font from existing buttons
	var ref_btn = $Main_Menu/NewGameButton
	if ref_btn.has_theme_font("font"):
		sound_label.add_theme_font_override("font", ref_btn.get_theme_font("font"))
	if ref_btn.has_theme_font_size("font_size"):
		sound_label.add_theme_font_size_override("font_size", ref_btn.get_theme_font_size("font_size") / 2)
	$Main_Menu.add_child(sound_label)

func _on_sound_button_pressed() -> void:
	sfx_player.play()
	sound_level = (sound_level + 1) % 5
	var volumes = [0.0, 0.25, 0.5, 0.75, 1.0]
	var labels  = ["0%", "25%", "50%", "75%", "100%"]
	$BackgroundMusic.volume_db = linear_to_db(volumes[sound_level])
	if sound_level == 0:
		$BackgroundMusic.stop()
		$Main_Menu/SoundButton.texture_normal = preload("res://icons/sound_off.png")
	else:
		if not $BackgroundMusic.playing:
			$BackgroundMusic.play()
		$Main_Menu/SoundButton.texture_normal = preload("res://icons/sound.png")
	if sound_label:
		sound_label.text = labels[sound_level]


# =================================================
#              SAVE SLOT PICKER UI
# =================================================
# We build a simple overlay panel at runtime so no scene edits are needed.

var slot_picker_panel: PanelContainer
var slot_picker_mode: String = ""   # "new" or "continue"

func _build_slot_picker_ui() -> void:
	# PanelContainer only supports ONE child — use margin directly as that child
	slot_picker_panel = PanelContainer.new()
	slot_picker_panel.name = "SlotPickerPanel"
	slot_picker_panel.custom_minimum_size = Vector2(500, 400)
	slot_picker_panel.z_index = 200
	slot_picker_panel.anchor_left = 0.5
	slot_picker_panel.anchor_top = 0.5
	slot_picker_panel.anchor_right = 0.5
	slot_picker_panel.anchor_bottom = 0.5
	slot_picker_panel.offset_left = -330
	slot_picker_panel.offset_top = -100
	slot_picker_panel.offset_right = 170
	slot_picker_panel.offset_bottom = 300
	slot_picker_panel.hide()
	var slot_canvas := CanvasLayer.new()
	slot_canvas.name = "SlotCanvas"
	add_child(slot_canvas)
	slot_canvas.add_child(slot_picker_panel)

	# margin → inner vbox → title + slot buttons + cancel
	var margin := MarginContainer.new()
	margin.name = "SlotMargin"
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	slot_picker_panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.name = "SlotInner"
	inner.add_theme_constant_override("separation", 12)
	margin.add_child(inner)

	var title := Label.new()
	title.name = "SlotTitle"
	title.text = ""
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.visible = false
	inner.add_child(title)

	for i in range(3):
		var btn := Button.new()
		btn.name = "SlotButton" + str(i + 1)
		btn.custom_minimum_size = Vector2(460, 110)
		btn.text = _get_slot_label(i)
		btn.pressed.connect(_on_slot_button_pressed.bind(i))
		btn.add_theme_color_override("font_color", Color(0, 0, 0))
		inner.add_child(btn)

	var cancel_btn := Button.new()
	cancel_btn.name = "SlotCancelButton"
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(460, 110)
	cancel_btn.pressed.connect(_on_slot_cancel_pressed)
	inner.add_child(cancel_btn)

	# Copy the exact theme from the existing menu buttons
	var ref_btn: Button = $Main_Menu/NewGameButton
	slot_picker_panel.theme = ref_btn.theme

	# Copy normal/hover/pressed styleboxes and font from the reference button
	var inner_vbox: VBoxContainer = slot_picker_panel.get_node("SlotMargin/SlotInner")
	for child in inner_vbox.get_children():
		if child is Button:
			if ref_btn.has_theme_stylebox("normal"):
				child.add_theme_stylebox_override("normal", ref_btn.get_theme_stylebox("normal"))
			if ref_btn.has_theme_stylebox("hover"):
				child.add_theme_stylebox_override("hover", ref_btn.get_theme_stylebox("hover"))
			if ref_btn.has_theme_stylebox("pressed"):
				child.add_theme_stylebox_override("pressed", ref_btn.get_theme_stylebox("pressed"))
			if ref_btn.has_theme_stylebox("disabled"):
				child.add_theme_stylebox_override("disabled", ref_btn.get_theme_stylebox("disabled"))
			if ref_btn.has_theme_font("font"):
				child.add_theme_font_override("font", ref_btn.get_theme_font("font"))
			if ref_btn.has_theme_font_size("font_size"):
				child.add_theme_font_size_override("font_size", ref_btn.get_theme_font_size("font_size"))
			if ref_btn.has_theme_color("font_color"):
				child.add_theme_color_override("font_color", ref_btn.get_theme_color("font_color"))

	# Copy the panel background style from the Main_Menu node
	# Transparent background - no panel box
	var bg := StyleBoxEmpty.new()
	slot_picker_panel.add_theme_stylebox_override("panel", bg)



func _format_number(n: int) -> String:
	if n >= 1000000000:
		return "%.1fB" % (n / 1000000000.0)
	elif n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	return str(n)


func _get_slot_label(slot: int) -> String:
	var path = SAVE_SLOTS[slot]
	if not FileAccess.file_exists(path):
		return "Slot " + str(slot + 1) + "  —  [Empty]"

	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		return "Slot " + str(slot + 1) + "  —  [Corrupted]"

	var currency = "Svetas" if data.get("lotan_skin", 0) == 1 else "Lotans"
	var lotans = int(data.get("lotan", 0))
	var ts = int(data.get("last_played", 0))
	var dt = Time.get_datetime_dict_from_unix_time(ts)
	var date_str = "%02d/%02d/%04d" % [dt.day, dt.month, dt.year]
	return "Slot %d  |  %s %s  |  %s" % [slot + 1, _format_number(lotans), currency, date_str]


func _refresh_slot_labels() -> void:
	var inner: VBoxContainer = slot_picker_panel.get_node("SlotMargin/SlotInner")
	if inner == null:
		return
	for i in range(3):
		var btn: Button = inner.get_node("SlotButton" + str(i + 1))
		if btn:
			btn.text = _get_slot_label(i)
			# Disable empty slots when continuing (can't load what doesn't exist)
			if slot_picker_mode == "continue":
				btn.disabled = not FileAccess.file_exists(SAVE_SLOTS[i])
			else:
				btn.disabled = false


func _show_slot_picker(mode: String) -> void:
	slot_picker_mode = mode
	_refresh_slot_labels()
	var title_label: Label = slot_picker_panel.get_node("SlotMargin/SlotInner/SlotTitle")
	if title_label:
		title_label.text = "New Game – Choose Slot" if mode == "new" else "Continue – Choose Slot"
	$Main_Menu/NewGameButton.hide()
	$Main_Menu/ContinueButton.hide()
	$Main_Menu/ExitButton.hide()
	slot_picker_panel.show()


func _on_slot_button_pressed(slot: int) -> void:
	sfx_player.play()
	slot_picker_panel.hide()
	if slot_picker_mode == "new":
		# Set slot now so saves work when the game starts
		active_slot = slot
		reset()
		$Main_Menu/NewGameButton.hide()
		$Main_Menu/SvetaButton.show()
		$Main_Menu/LotanButton.show()
		$Main_Menu/BackButton.show()
	else:
		# Continue: load that slot and start playing
		reset()
		load_data(slot)
		_start_game()


func _on_slot_cancel_pressed() -> void:
	sfx_player.play()
	slot_picker_panel.hide()
	$Main_Menu/NewGameButton.show()
	$Main_Menu/ContinueButton.show()
	$Main_Menu/ExitButton.show()


# Shared helper: enter game view
func _start_game() -> void:
	in_game = true
	has_loaded = true
	$Main_Menu/BackButton.hide()
	$Main_Menu/SvetaButton.hide()
	$Main_Menu/LotanButton.hide()
	$Main_Menu/NewGameButton.hide()
	$Main_Menu/ContinueButton.hide()
	$Main_Menu/ExitButton.hide()
	$leftPanel.show()
	$rightPanel.show()
	update_ui()
	show_upgrades()
	if lotan_skin == 1:
		$leftPanel/MarginContainer/CenterContainer/ClickButton.texture_normal = preload("res://icons/Sveta sveta eater.png")
	else:
		$leftPanel/MarginContainer/CenterContainer/ClickButton.texture_normal = preload("res://icons/Lotan Sveta eater.png")


# =================================================
#              GOLDEN COOKIE
# =================================================

# ---- Internal setup ----
# Creates the golden cookie Button node and all required timers at runtime.
# This means you do NOT need to add them manually in the editor.

func _setup_golden_cookie() -> void:
	# --- Spawn timer: fires every 5 minutes ---
	var spawn_timer := Timer.new()
	spawn_timer.name = "GoldenCookieSpawnTimer"
	spawn_timer.wait_time = randf_range(240.0, 300.0) * golden_cookie_time_multiplier
	spawn_timer.one_shot = false
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_golden_cookie_spawn_timer_timeout)

	# --- Life timer: cookie disappears after 15 seconds if not clicked ---
	var life_timer := Timer.new()
	life_timer.name = "GoldenCookieLifeTimer"
	life_timer.wait_time = 15.0
	life_timer.one_shot = true
	life_timer.autostart = false
	add_child(life_timer)
	life_timer.timeout.connect(_on_golden_cookie_life_timer_timeout)

	# --- Buff timer: x2 LPS lasts 30 seconds ---
	var buff_timer := Timer.new()
	buff_timer.name = "GoldenCookieBuffTimer"
	buff_timer.wait_time = 30.0
	buff_timer.one_shot = true
	buff_timer.autostart = false
	add_child(buff_timer)
	buff_timer.timeout.connect(_on_golden_cookie_buff_timer_timeout)

	# --- The golden cookie reuses the existing TextureRect node in the scene ---
	var cookie: TextureRect = $GoldenCookie
	cookie.custom_minimum_size = Vector2(80, 80)
	cookie.size = Vector2(80, 80)
	cookie.mouse_filter = Control.MOUSE_FILTER_STOP
	cookie.hide()
	cookie.z_index = 100   # render on top of everything
	cookie.gui_input.connect(_on_golden_cookie_gui_input)


# ---- Spawn ----
func _on_golden_cookie_spawn_timer_timeout() -> void:
	if not in_game:
		return
	if golden_cookie_active:
		return
	# Randomize next spawn time between 4 and 5 minutes
	$GoldenCookieSpawnTimer.wait_time = randf_range(240.0, 300.0) * golden_cookie_time_multiplier
	_spawn_golden_cookie()


func _on_golden_cookie_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_golden_cookie_clicked()


func _spawn_golden_cookie() -> void:
	var cookie: TextureRect = $GoldenCookie
	var viewport_size: Vector2 = get_viewport_rect().size
	var cookie_size: Vector2 = cookie.size

	var margin := 20.0
	var rand_x := randf_range(margin, viewport_size.x - cookie_size.x - margin)
	var rand_y := randf_range(margin, viewport_size.y - cookie_size.y - margin)
	cookie.position = Vector2(rand_x, rand_y)

	# Reset modulate and rotation
	cookie.modulate = Color(1, 1, 1, 1)
	cookie.pivot_offset = cookie.size / 2.0
	cookie.rotation = 0.0
	cookie.show()
	golden_cookie_active = true

	# Gentle wobble — 15 degrees left and right, slower
	var spin_tween = create_tween()
	spin_tween.set_loops()
	spin_tween.tween_property(cookie, "rotation_degrees", 15.0, 1.2).set_ease(Tween.EASE_IN_OUT)
	spin_tween.tween_property(cookie, "rotation_degrees", -15.0, 1.2).set_ease(Tween.EASE_IN_OUT)

	# Gentle grow and shrink
	var scale_tween = create_tween()
	scale_tween.set_loops()
	scale_tween.tween_property(cookie, "scale", Vector2(1.15, 1.15), 1.0).set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property(cookie, "scale", Vector2(1.0, 1.0), 1.0).set_ease(Tween.EASE_IN_OUT)

	$GoldenCookieLifeTimer.start()


# ---- Player clicks the cookie ----
func _on_golden_cookie_clicked() -> void:
	if not golden_cookie_active:
		return

	golden_cookies_clicked += 1

	# Cancel the fade-out life timer
	$GoldenCookieLifeTimer.stop()

	# Kill any in-progress fade tween
	if golden_cookie_fade_tween != null and golden_cookie_fade_tween.is_valid():
		golden_cookie_fade_tween.kill()

	# Hide immediately
	$GoldenCookie.hide()
	golden_cookie_active = false

	# Apply the x2 LPS buff
	_apply_golden_cookie_buff()


# ---- Buff logic ----
func _apply_golden_cookie_buff() -> void:
	if golden_cookie_buff_active:
		_cancel_golden_cookie_buff()

	golden_cookie_base_lps = lps   # remember real LPS before doubling
	lps *= 2.0
	golden_cookie_buff_active = true
	$GoldenCookieBuffTimer.start()


func _on_golden_cookie_buff_timer_timeout() -> void:
	_cancel_golden_cookie_buff()


func _cancel_golden_cookie_buff() -> void:
	if not golden_cookie_buff_active:
		return
	$GoldenCookieBuffTimer.stop()
	# Any LPS gained during the buff is the difference above the doubled base.
	# Add that difference back onto the real base LPS.
	var gained_during_buff = lps - (golden_cookie_base_lps * 2.0)
	lps = golden_cookie_base_lps + gained_during_buff
	golden_cookie_buff_active = false
	golden_cookie_base_lps = 0.0


# ---- Cookie expires (not clicked in time) ----
func _on_golden_cookie_life_timer_timeout() -> void:
	if not golden_cookie_active:
		return
	# Slowly fade out over 3 seconds using a Tween
	if golden_cookie_fade_tween != null and golden_cookie_fade_tween.is_valid():
		golden_cookie_fade_tween.kill()

	golden_cookie_fade_tween = create_tween()
	golden_cookie_fade_tween.tween_property(
		$GoldenCookie,
		"modulate:a",
		0.0,
		3.0
	).set_ease(Tween.EASE_IN)
	golden_cookie_fade_tween.finished.connect(_on_golden_cookie_fade_finished)


func _on_golden_cookie_fade_finished() -> void:
	$GoldenCookie.hide()
	$GoldenCookie.modulate = Color(1, 1, 1, 1)
	$GoldenCookie.rotation = 0.0
	$GoldenCookie.scale = Vector2(1.0, 1.0)
	golden_cookie_active = false


# =================================================
#                 ACHIEVEMENTS
# =================================================

const ACHIEVEMENTS = [
	# --- Lotan milestones ---
	{ "id": "lotan_100",      "name": "First Steps",       "desc": "Reach 100 Lotans",                  "texture": "res://icons/lotan 100.png" },
	{ "id": "lotan_1k",       "name": "Getting Somewhere", "desc": "Reach 1,000 Lotans",                "texture": "res://icons/lotan 1k.png" },
	{ "id": "lotan_10k",      "name": "Big Spender",       "desc": "Reach 10,000 Lotans",               "texture": "res://icons/lotan 10k.png" },
	{ "id": "lotan_100k",     "name": "Lotan Millionaire", "desc": "Reach 100,000 Lotans",              "texture": "res://icons/lotan 100k.png" },
	{ "id": "lotan_1m",       "name": "Lotan God",         "desc": "Reach 1,000,000 Lotans",            "texture": "res://icons/lotan 1m.png" },
	# --- Clicking ---
	{ "id": "clicks_100",     "name": "Fast Fingers",      "desc": "Click 100 times",                   "texture": "res://icons/lotdik1.png" },
	{ "id": "clicks_1000",    "name": "Click Master",      "desc": "Click 1,000 times",                 "texture": "res://icons/lotdik2.png" },
	{ "id": "clicks_10000",   "name": "Unstoppable",       "desc": "Click 10,000 times",                "texture": "res://icons/lotdik3.png" },
	# --- Page 1 Upgrades ---
	{ "id": "upgrade_first",       "name": "First Upgrade",     "desc": "Buy your first upgrade",            "texture": "res://icons/moodi.png" },
	{ "id": "upgrade_moodi",       "name": "Moodi Fan",         "desc": "Buy Moodi 5 times",                 "texture": "res://icons/moodi.png" },
	{ "id": "upgrade_benbasat",    "name": "Ben Bassat Fan",    "desc": "Buy Ben Bassat 5 times",            "texture": "res://icons/benbasat.png" },
	{ "id": "upgrade_sharon",      "name": "Sharon Fan",        "desc": "Buy Sharon 5 times",                "texture": "res://icons/sharon.png" },
	{ "id": "upgrade_sergei",      "name": "Sergei Fan",        "desc": "Buy Sergei 5 times",                "texture": "res://icons/sergei.png" },
	{ "id": "upgrade_sveta",       "name": "Sveta Fan",         "desc": "Buy Sveta 5 times",                 "texture": "res://icons/sveta.png" },
	{ "id": "upgrade_slim_lotan",  "name": "Slim Lotan Fan",    "desc": "Buy Slim Lotan 5 times",            "texture": "res://icons/slim_lotan.png" },
	# --- Page 2 Upgrades ---
	{ "id": "upgrade_tzipi",       "name": "Tzipi Baron Fan",   "desc": "Buy Tzipi Baron 5 times",           "texture": "res://icons/tzipi baron.png" },
	{ "id": "upgrade_ultra_moodi", "name": "Ultra Moodi Fan",   "desc": "Buy Ultra Moodi 5 times",           "texture": "res://icons/ultra moodi.png" },
	{ "id": "upgrade_ultra_sveta", "name": "Ultra Sveta Fan",   "desc": "Buy Ultra Sveta 5 times",           "texture": "res://icons/ultra sveta.png" },
	{ "id": "upgrade_ultra_lotan", "name": "Ultra Lotan Fan",   "desc": "Buy Ultra Lotan 5 times",           "texture": "res://icons/ultra lotan.png" },
	{ "id": "upgrade_fantastic",   "name": "Fantastic Fan",     "desc": "Buy The Fantastic Four 5 times",    "texture": "res://icons/the fantastic four.png" },
	{ "id": "upgrade_all_p2",      "name": "Page 2 Collector",  "desc": "Buy all page 2 upgrades at least once", "texture": "res://icons/the fantastic four.png" },
	# --- Shop ---
	{ "id": "shop_first",     "name": "Secret Found",      "desc": "Buy your first secret upgrade",     "texture": "res://icons/moodle.png" },
	{ "id": "shop_all",       "name": "Big Shopper",       "desc": "Buy all secret upgrades",           "texture": "res://icons/fantastic_four_upgrade.png" },
	# --- Golden Diker ---
	{ "id": "golden_first",   "name": "Golden Diker",      "desc": "Click your first Golden Diker",     "texture": "res://icons/Lotan Golden cookie.png" },
	{ "id": "golden_5",       "name": "Golden Diker Fan",  "desc": "Click 5 Golden Dikers",             "texture": "res://icons/Lotan Golden cookie.png" },
]

var golden_cookies_clicked: int = 0


func _unlock_achievement(id: String) -> void:
	if id in achievements_unlocked:
		return
	achievements_unlocked.append(id)
	save_data()
	# Find achievement data
	for ach in ACHIEVEMENTS:
		if ach["id"] == id:
			achievement_notification_queue.append(ach)
			if not achievement_notification_active:
				_show_next_notification()
			break


func _check_achievements() -> void:
	# Lotan milestones
	if lotan >= 100:       _unlock_achievement("lotan_100")
	if lotan >= 1000:      _unlock_achievement("lotan_1k")
	if lotan >= 10000:     _unlock_achievement("lotan_10k")
	if lotan >= 100000:    _unlock_achievement("lotan_100k")
	if lotan >= 1000000:   _unlock_achievement("lotan_1m")
	# Clicks
	if total_clicks >= 100:   _unlock_achievement("clicks_100")
	if total_clicks >= 1000:  _unlock_achievement("clicks_1000")
	if total_clicks >= 10000: _unlock_achievement("clicks_10000")
	# Upgrades
	if upgrade1_level + upgrade2_level + upgrade3_level + upgrade4_level + upgrade5_level + upgrade6_level >= 1:
		_unlock_achievement("upgrade_first")
	if upgrade1_level >= 5: _unlock_achievement("upgrade_moodi")
	if upgrade2_level >= 5: _unlock_achievement("upgrade_benbasat")
	if upgrade3_level >= 5: _unlock_achievement("upgrade_sharon")
	if upgrade4_level >= 5: _unlock_achievement("upgrade_sergei")
	if upgrade5_level >= 5: _unlock_achievement("upgrade_sveta")
	if upgrade6_level >= 5: _unlock_achievement("upgrade_slim_lotan")
	if upgrade_page2_levels[0] >= 5: _unlock_achievement("upgrade_tzipi")
	if upgrade_page2_levels[1] >= 5: _unlock_achievement("upgrade_ultra_moodi")
	if upgrade_page2_levels[2] >= 5: _unlock_achievement("upgrade_ultra_sveta")
	if upgrade_page2_levels[3] >= 5: _unlock_achievement("upgrade_ultra_lotan")
	if upgrade_page2_levels[4] >= 5: _unlock_achievement("upgrade_fantastic")
	if upgrade_page2_levels[0] >= 1 and upgrade_page2_levels[1] >= 1 and upgrade_page2_levels[2] >= 1 and upgrade_page2_levels[3] >= 1 and upgrade_page2_levels[4] >= 1:
		_unlock_achievement("upgrade_all_p2")
	# Shop
	if shop1_bought + shop2_bought + shop3_bought + shop4_bought + shop5_bought + shop6_bought + shop7_bought >= 1:
		_unlock_achievement("shop_first")
	if shop1_bought >= 1 and shop2_bought >= 1 and shop3_bought >= 1 and shop4_bought >= 1 and shop5_bought >= 1 and shop6_bought >= 1:
		_unlock_achievement("shop_all")
	# Golden cookie
	if golden_cookies_clicked >= 1: _unlock_achievement("golden_first")
	if golden_cookies_clicked >= 5: _unlock_achievement("golden_5")


# =================================================
#           ACHIEVEMENT NOTIFICATION
# =================================================
func _show_next_notification() -> void:
	if achievement_notification_queue.is_empty():
		achievement_notification_active = false
		return
	achievement_notification_active = true
	var ach = achievement_notification_queue.pop_front()

	var notif := PanelContainer.new()
	notif.z_index = 300
	notif.custom_minimum_size = Vector2(300, 60)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	bg.border_width_top = 2
	bg.border_width_bottom = 2
	bg.border_width_left = 2
	bg.border_width_right = 2
	bg.border_color = Color(1, 0.85, 0.0)
	notif.add_theme_stylebox_override("panel", bg)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	notif.add_child(margin)
	margin.add_child(hbox)

	if ach["texture"] != "":
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(36, 36)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = load(ach["texture"])
		hbox.add_child(icon_rect)
	else:
		var unk_lbl := Label.new()
		unk_lbl.text = "???"
		unk_lbl.custom_minimum_size = Vector2(36, 36)
		hbox.add_child(unk_lbl)

	var vbox := VBoxContainer.new()
	hbox.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "Achievement Unlocked!"
	title_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.0))
	title_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(title_lbl)

	var name_lbl := Label.new()
	name_lbl.text = ach["name"] + " — " + ach["desc"]
	name_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name_lbl)

	# Position bottom-right
	var vp = get_viewport_rect().size
	notif.position = Vector2(vp.x - 320, vp.y - 80)
	add_child(notif)

	# Slide in, wait, slide out
	var tween = create_tween()
	tween.tween_property(notif, "position:y", vp.y - 80, 0.3).from(vp.y)
	tween.tween_interval(2.5)
	tween.tween_property(notif, "position:y", vp.y, 0.3)
	tween.finished.connect(func():
		notif.queue_free()
		_show_next_notification()
	)


# =================================================
#           ACHIEVEMENT WINDOW
# =================================================
func _build_achievement_panel() -> void:
	achievement_panel = PanelContainer.new()
	achievement_panel.name = "AchievementPanel"
	achievement_panel.z_index = 200
	achievement_panel.anchor_left = 0.0
	achievement_panel.anchor_top = 0.0
	achievement_panel.anchor_right = 1.0
	achievement_panel.anchor_bottom = 1.0
	achievement_panel.offset_left = 0
	achievement_panel.offset_top = 0
	achievement_panel.offset_right = 0
	achievement_panel.offset_bottom = 0
	achievement_panel.hide()

	# Match the teal game style
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.53, 0.53)
	bg.corner_radius_top_left = 12
	bg.corner_radius_top_right = 12
	bg.corner_radius_bottom_left = 12
	bg.corner_radius_bottom_right = 12
	achievement_panel.add_theme_stylebox_override("panel", bg)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	achievement_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Title — using game font
	var title := Label.new()
	title.text = "Achievements"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", $Main_Menu/NewGameButton.get_theme_font("font"))
	title.add_theme_font_size_override("font_size", 42)
	title.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vbox.add_child(title)

	# Scroll container
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "AchievementList"
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	# Close button — styled like game buttons
	var ref = $Main_Menu/NewGameButton
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.custom_minimum_size = Vector2(0, 70)
	if ref.has_theme_font("font"):
		close_btn.add_theme_font_override("font", ref.get_theme_font("font"))
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.theme = $Main_Menu/NewGameButton.theme
	if ref.has_theme_stylebox("normal"):
		close_btn.add_theme_stylebox_override("normal", ref.get_theme_stylebox("normal"))
	if ref.has_theme_stylebox("hover"):
		close_btn.add_theme_stylebox_override("hover", ref.get_theme_stylebox("hover"))
	if ref.has_theme_stylebox("pressed"):
		close_btn.add_theme_stylebox_override("pressed", ref.get_theme_stylebox("pressed"))
	if ref.has_theme_font("font"):
		close_btn.add_theme_font_override("font", ref.get_theme_font("font"))
	close_btn.pressed.connect(func():
		sfx_player.play()
		achievement_panel.hide()
	)
	close_btn.add_theme_color_override("font_color", Color(0, 0, 0))
	vbox.add_child(close_btn)

	var canvas := CanvasLayer.new()
	canvas.name = "AchievementCanvas"
	add_child(canvas)
	canvas.add_child(achievement_panel)


func _refresh_achievement_panel() -> void:
	var all_unlocked = _get_all_achievements()
	var list: VBoxContainer = achievement_panel.get_node("AchievementPanel/AchievementList") if achievement_panel.has_node("AchievementPanel/AchievementList") else null
	# Navigate correctly
	var margin = achievement_panel.get_child(0)
	var vbox = margin.get_child(0)
	var scroll = vbox.get_child(1)
	list = scroll.get_child(0)
	if list == null:
		return

	# Clear existing entries
	for child in list.get_children():
		child.queue_free()

	var unlocked_count = 0
	for ach in ACHIEVEMENTS:
		var is_unlocked = ach["id"] in all_unlocked
		if is_unlocked:
			unlocked_count += 1

		var row := PanelContainer.new()
		var row_bg := StyleBoxFlat.new()
		# Unlocked = white like game buttons, locked = darker teal
		row_bg.bg_color = Color(1.0, 1.0, 1.0) if is_unlocked else Color(0.0, 0.35, 0.35)
		row_bg.corner_radius_top_left = 8
		row_bg.corner_radius_top_right = 8
		row_bg.corner_radius_bottom_left = 8
		row_bg.corner_radius_bottom_right = 8
		row.add_theme_stylebox_override("panel", row_bg)
		row.custom_minimum_size = Vector2(0, 90)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 20)
		row_margin.add_theme_constant_override("margin_right", 20)
		row_margin.add_theme_constant_override("margin_top", 10)
		row_margin.add_theme_constant_override("margin_bottom", 10)
		row.add_child(row_margin)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)
		row_margin.add_child(hbox)

		# Icon
		if is_unlocked and ach["texture"] != "":
			var icon_rect := TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(64, 64)
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_rect.texture = load(ach["texture"])
			hbox.add_child(icon_rect)
		else:
			var unk_lbl := Label.new()
			unk_lbl.text = "???" if not is_unlocked else "   "
			unk_lbl.custom_minimum_size = Vector2(64, 64)
			unk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			unk_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			unk_lbl.add_theme_font_size_override("font_size", 20)
			unk_lbl.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0) if is_unlocked else Color(0.6, 0.6, 0.6))
			hbox.add_child(unk_lbl)

		var text_vbox := VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(text_vbox)

		var ref_btn = $Main_Menu/NewGameButton
		var name_lbl := Label.new()
		name_lbl.text = ach["name"] if is_unlocked else "???"
		if ref_btn.has_theme_font("font"):
			name_lbl.add_theme_font_override("font", ref_btn.get_theme_font("font"))
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0) if is_unlocked else Color(0.7, 0.7, 0.7))
		name_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		text_vbox.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = ach["desc"] if is_unlocked else "???"
		if ref_btn.has_theme_font("font"):
			desc_lbl.add_theme_font_override("font", ref_btn.get_theme_font("font"))
		desc_lbl.add_theme_font_size_override("font_size", 16)
		desc_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3) if is_unlocked else Color(0.5, 0.5, 0.5))
		desc_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		text_vbox.add_child(desc_lbl)

		list.add_child(row)

	# Update title with count
	var title_margin = achievement_panel.get_child(0)
	var title_vbox = title_margin.get_child(0)
	var title = title_vbox.get_child(0)
	title.text = "Achievements  (%d / %d)" % [unlocked_count, ACHIEVEMENTS.size()]


func _build_achievement_button() -> void:
	var btn := TextureButton.new()
	btn.name = "AchievementButton"
	btn.texture_normal = preload("res://icons/trophy.png")
	btn.scale = Vector2(2.5, 2.0)
	# Place it next to the sound button (which is at roughly 4, 580)
	btn.position = Vector2(80, 580)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.pressed.connect(_on_achievement_button_pressed)
	$Main_Menu.add_child(btn)


func _get_all_achievements() -> Array:
	# Merge unlocked achievements from all 3 save slots
	var merged: Array = []
	for path in SAVE_SLOTS:
		if not FileAccess.file_exists(path):
			continue
		var file = FileAccess.open(path, FileAccess.READ)
		var data = file.get_var()
		file.close()
		if typeof(data) != TYPE_DICTIONARY:
			continue
		var slot_achievements = data.get("achievements_unlocked", [])
		for id in slot_achievements:
			if not id in merged:
				merged.append(id)
	return merged


func _on_achievement_button_pressed() -> void:
	sfx_player.play()
	_refresh_achievement_panel()
	achievement_panel.show()


# =================================================
#              DEBUG COMMANDS
# =================================================
func unlock_all_achievements() -> void:
	for ach in ACHIEVEMENTS:
		_unlock_achievement(ach["id"])
	print("All achievements unlocked!")


# =================================================
#            PAGE 2 UPGRADES / SHOP
# =================================================

func _build_page_buttons() -> void:
	# Guard - only build once
	if $rightPanel.get_node_or_null("UpgradePageBtn") != null:
		return
	var empty_style := StyleBoxEmpty.new()

	# --- Upgrade page button ---
	var upg_next := Button.new()
	upg_next.name = "UpgradePageBtn"
	upg_next.text = "Next Page >"
	upg_next.position = Vector2(108, 618)
	upg_next.custom_minimum_size = Vector2(160, 56)
	upg_next.add_theme_font_override("font", $Main_Menu/NewGameButton.get_theme_font("font"))
	upg_next.add_theme_font_size_override("font_size", 16)
	upg_next.add_theme_color_override("font_color", Color(1, 1, 1))
	upg_next.add_theme_stylebox_override("normal", empty_style)
	upg_next.add_theme_stylebox_override("hover", empty_style)
	upg_next.add_theme_stylebox_override("pressed", empty_style)
	upg_next.add_theme_stylebox_override("focus", empty_style)
	upg_next.flat = true
	upg_next.pressed.connect(_on_upgrade_page_btn_pressed)
	$rightPanel.add_child(upg_next)

	# --- Shop page button — hidden until shop is open ---
	var shop_next := Button.new()
	shop_next.name = "ShopPageBtn"
	shop_next.text = "Next Page >"
	shop_next.position = Vector2(108, 618)
	shop_next.custom_minimum_size = Vector2(160, 56)
	shop_next.add_theme_font_override("font", $Main_Menu/NewGameButton.get_theme_font("font"))
	shop_next.add_theme_font_size_override("font_size", 16)
	shop_next.add_theme_color_override("font_color", Color(1, 1, 1))
	shop_next.add_theme_stylebox_override("normal", empty_style)
	shop_next.add_theme_stylebox_override("hover", empty_style)
	shop_next.add_theme_stylebox_override("pressed", empty_style)
	shop_next.add_theme_stylebox_override("focus", empty_style)
	shop_next.flat = true
	shop_next.visible = false
	shop_next.pressed.connect(_on_shop_page_btn_pressed)
	$rightPanel.add_child(shop_next)

	# Build page 2 upgrade buttons
	for i in range(UPGRADE_PAGE2.size()):
		var data = UPGRADE_PAGE2[i]
		var btn := Button.new()
		btn.name = "UpgradeP2_" + str(i)
		btn.custom_minimum_size = Vector2(278, 70)
		btn.offset_left = 52.0
		btn.offset_top = 20.0 + i * 120
		btn.offset_right = 330.0
		btn.offset_bottom = 100.0 + i * 120
		btn.theme = $Main_Menu/NewGameButton.theme
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_font_override("font", $Main_Menu/NewGameButton.get_theme_font("font"))
		btn.add_theme_font_size_override("font_size", 17)
		btn.visible = false
		btn.pressed.connect(_on_upgrade_p2_pressed.bind(i))
		$rightPanel/Upgrades.add_child(btn)

		var icon := TextureRect.new()
		icon.name = "UpgradeP2_Icon_" + str(i)
		icon.texture = load(data["icon_black"])
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.offset_left = 5.0
		icon.offset_top = 20.0 + i * 120
		icon.offset_right = 55.0
		icon.offset_bottom = 100.0 + i * 120
		icon.visible = false
		$rightPanel/Upgrades.add_child(icon)

	# Tzipi Baron icon is a bit smaller
	var tzipi_icon = $rightPanel/Upgrades.get_node_or_null("UpgradeP2_Icon_0")
	if tzipi_icon:
		tzipi_icon.offset_left = 5.0
		tzipi_icon.offset_right = 55.0

	# Golden Diker icon moved 15px right
	var golden_icon = $rightPanel/Shops.get_node_or_null("ShopP2_Icon_0")
	if golden_icon:
		golden_icon.offset_left = -80.0
		golden_icon.offset_right = -30.0

	# Build page 2 shop buttons
	for i in range(SHOP_PAGE2.size()):
		var data = SHOP_PAGE2[i]
		var btn := Button.new()
		btn.name = "ShopP2_" + str(i)
		btn.custom_minimum_size = Vector2(278, 70)
		btn.offset_left = 52.0
		btn.offset_top = 20.0 + i * 110
		btn.offset_right = 330.0
		btn.offset_bottom = 100.0 + i * 110
		btn.theme = $Main_Menu/NewGameButton.theme
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_font_override("font", $Main_Menu/NewGameButton.get_theme_font("font"))
		btn.add_theme_font_size_override("font_size", 17)
		btn.visible = false
		btn.pressed.connect(_on_shop_p2_pressed.bind(i))
		$rightPanel/Shops.add_child(btn)

		var icon := TextureRect.new()
		icon.name = "ShopP2_Icon_" + str(i)
		icon.texture = load(data["icon"])
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if i == 0:  # Golden Diker
			icon.offset_left = -5.0
			icon.offset_right = 25.0
		else:
			icon.offset_left = 5.0
			icon.offset_right = 55.0
		icon.offset_top = 20.0 + i * 110
		icon.offset_bottom = 100.0 + i * 110
		icon.visible = false
		$rightPanel/Shops.add_child(icon)


func _on_upgrade_page_btn_pressed() -> void:
	sfx_player.play()
	upgrade_current_page = 2 if upgrade_current_page == 1 else 1
	_refresh_upgrade_pages()


func _on_shop_page_btn_pressed() -> void:
	sfx_player.play()
	shop_current_page = 2 if shop_current_page == 1 else 1
	_refresh_shop_pages()


func _refresh_upgrade_pages() -> void:
	var on_p1 = upgrade_current_page == 1
	# Show/hide page 1 nodes
	for node_name in ["Upgrade1_Button","Upgrade1_Icon","Upgrade1_Label",
					   "Upgrade2_Button","Upgrade2_Icon","Upgrade2_Label",
					   "Upgrade3_Button","Upgrade3_Icon","Upgrade3_Label",
					   "Upgrade4_Button","Upgrade4_Icon","Upgrade4_Label",
					   "Upgrade5_Button","Upgrade5_Icon","Upgrade5_Label",
					   "Upgrade6_Button","Upgrade6_Icon","Upgrade6_Label",
					   "Shop_Button","Shop_Label"]:
		var n = $rightPanel/Upgrades.get_node_or_null(node_name)
		if n: n.visible = on_p1

	# Show/hide page 2 nodes
	for i in range(UPGRADE_PAGE2.size()):
		var btn = $rightPanel/Upgrades.get_node_or_null("UpgradeP2_" + str(i))
		var icon = $rightPanel/Upgrades.get_node_or_null("UpgradeP2_Icon_" + str(i))
		if btn: btn.visible = not on_p1
		if icon: icon.visible = not on_p1

	# Update page button label
	var page_btn = $rightPanel.get_node_or_null("UpgradePageBtn")
	if page_btn:
		page_btn.text = "Next Page >" if on_p1 else "< Back"

	# Update p2 button texts
	if not on_p1:
		_update_upgrade_p2_ui()


func _refresh_shop_pages() -> void:
	var on_p1 = shop_current_page == 1
	# Show/hide page 1 nodes
	for node_name in ["Shop1_Button","Shop1_Icon","Shop1_Label",
					   "Shop2_Button","Shop2_Icon","Shop2_Label",
					   "Shop3_Button","Shop3_Icon","Shop3_Label",
					   "Shop4_Button","Shop4_Icon","Shop4_Label",
					   "Shop5_Button","Shop5_Icon","Shop5_Label",
					   "Shop6_Button","Shop6_Icon","Shop6_Label",
					   "Shop7_Button","Shop7_Icon","Shop7_Label"]:
		var n = $rightPanel/Shops.get_node_or_null(node_name)
		if n: n.visible = on_p1

	# Hide the secret shop toggle button when on page 2
	var shop_toggle = $rightPanel/Upgrades.get_node_or_null("Shop_Button")
	if shop_toggle: shop_toggle.visible = on_p1
	var shop_label = $rightPanel/Upgrades.get_node_or_null("Shop_Label")
	if shop_label: shop_label.visible = on_p1

	# Show/hide page 2 nodes
	for i in range(SHOP_PAGE2.size()):
		var btn = $rightPanel/Shops.get_node_or_null("ShopP2_" + str(i))
		var icon = $rightPanel/Shops.get_node_or_null("ShopP2_Icon_" + str(i))
		if btn: btn.visible = not on_p1
		if icon: icon.visible = not on_p1

	# Update page button label
	var page_btn = $rightPanel.get_node_or_null("ShopPageBtn")
	if page_btn:
		page_btn.text = "Next Page >" if on_p1 else "< Back"

	if not on_p1:
		_update_shop_p2_ui()


func _update_upgrade_p2_ui() -> void:
	for i in range(UPGRADE_PAGE2.size()):
		var btn = $rightPanel/Upgrades.get_node_or_null("UpgradeP2_" + str(i))
		if btn == null: continue
		var data = UPGRADE_PAGE2[i]
		var lvl = upgrade_page2_levels[i]
		var cost = upgrade_page2_costs[i]
		if lvl == 0:
			btn.text = "???\n(Cost: %s) x0" % _format_number(cost)
		else:
			btn.text = "%s\n(Cost: %s) x%d" % [data["name"], _format_number(cost), lvl]
		btn.disabled = lotan < cost
		_auto_font_size_p2(btn)
		# Swap icon colour
		var icon = $rightPanel/Upgrades.get_node_or_null("UpgradeP2_Icon_" + str(i))
		if icon:
			icon.texture = load(data["icon"] if lvl > 0 else data["icon_black"])


func _update_shop_p2_ui() -> void:
	for i in range(SHOP_PAGE2.size()):
		var btn = $rightPanel/Shops.get_node_or_null("ShopP2_" + str(i))
		if btn == null: continue
		var data = SHOP_PAGE2[i]
		var bought = shop_page2_bought[i]
		if bought == 1:
			btn.text = "Purchased"
			btn.disabled = true
		else:
			btn.text = "%s\n%s (Cost: %s)" % [data["name"], data["desc"], _format_number(int(data["cost"]))]
			btn.disabled = lotan < data["cost"]
		_auto_font_size_p2(btn)


func _on_upgrade_p2_pressed(i: int) -> void:
	sfx_player.play()
	var cost = upgrade_page2_costs[i]
	if lotan < cost: return
	lotan -= cost
	upgrade_page2_levels[i] += 1
	upgrade_page2_costs[i] = int(cost * 1.2)
	lps += UPGRADE_PAGE2[i]["lps"]
	save_data()
	_update_upgrade_p2_ui()


func _on_shop_p2_pressed(i: int) -> void:
	sfx_player.play()
	var data = SHOP_PAGE2[i]
	if lotan < data["cost"]: return
	if shop_page2_bought[i] == 1: return
	lotan -= data["cost"]
	shop_page2_bought[i] = 1
	# Apply effect
	if data["effect"] == "lps_boost":
		lps += data["amount"]
	elif data["effect"] == "golden_half":
		golden_cookie_time_multiplier = 0.5
	elif data["effect"] == "double_p2":
		# Double the LPS contribution of the target page 2 upgrade
		var target = data["target"]
		var lvl = upgrade_page2_levels[target]	
		lps += UPGRADE_PAGE2[target]["lps"] * lvl
	save_data()
	_update_shop_p2_ui()	
