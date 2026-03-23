extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var coin_label: Label = $CoinLabel
@onready var heart_container: HBoxContainer = $HeartContainer
@onready var start_panel: PanelContainer = $StartPanel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var leaderboard_panel: PanelContainer = $LeaderboardPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var final_coins_label: Label = $GameOverPanel/VBoxContainer/FinalCoinsLabel
@onready var wallet_label: Label = $GameOverPanel/VBoxContainer/WalletLabel

var _return_to_panel: PanelContainer


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.hearts_changed.connect(_on_hearts_changed)
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over.connect(_on_game_over)
	GameManager.wallet_changed.connect(_on_wallet_changed)
	_build_shop()
	_build_leaderboard()
	_show_start_screen()


func _hide_all_panels() -> void:
	start_panel.visible = false
	game_over_panel.visible = false
	shop_panel.visible = false
	leaderboard_panel.visible = false
	score_label.visible = false
	coin_label.visible = false
	heart_container.visible = false


func _show_start_screen() -> void:
	_hide_all_panels()
	start_panel.visible = true


func _on_game_started() -> void:
	_hide_all_panels()
	score_label.visible = true
	coin_label.visible = true
	heart_container.visible = true
	_update_hearts(0)
	score_label.text = "0"
	coin_label.text = "0"


func _on_game_over() -> void:
	_hide_all_panels()
	game_over_panel.visible = true
	final_score_label.text = "Score: " + str(GameManager.score)
	final_coins_label.text = "Coins earned: +" + str(GameManager.coins)
	wallet_label.text = "Wallet: " + str(GameManager.wallet)


func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)


func _on_coins_changed(new_coins: int) -> void:
	coin_label.text = str(new_coins)


func _on_hearts_changed(count: int) -> void:
	_update_hearts(count)


func _on_wallet_changed(_amount: int) -> void:
	wallet_label.text = "Wallet: " + str(GameManager.wallet)


func _update_hearts(count: int) -> void:
	for child in heart_container.get_children():
		child.queue_free()
	for i in range(count):
		var icon := _create_heart_icon()
		heart_container.add_child(icon)


func _create_heart_icon() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(28, 28)
	var left := ColorRect.new()
	left.color = Color(1.0, 0.15, 0.25, 1)
	left.position = Vector2(2, 2)
	left.size = Vector2(12, 12)
	container.add_child(left)
	var right := ColorRect.new()
	right.color = Color(1.0, 0.15, 0.25, 1)
	right.position = Vector2(14, 2)
	right.size = Vector2(12, 12)
	container.add_child(right)
	var bottom := ColorRect.new()
	bottom.color = Color(1.0, 0.15, 0.25, 1)
	bottom.position = Vector2(4, 10)
	bottom.size = Vector2(20, 14)
	bottom.rotation = 0.785
	bottom.pivot_offset = Vector2(10, 0)
	container.add_child(bottom)
	return container


# ── Shop ──

var shop_wallet_label: Label

func _build_shop() -> void:
	var vbox: VBoxContainer = $ShopPanel/VBoxContainer

	# Title
	var title := Label.new()
	title.text = "SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	# Wallet
	shop_wallet_label = Label.new()
	shop_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_wallet_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	shop_wallet_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(shop_wallet_label)

	# Grid
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid)

	for i in range(GameManager.SKINS.size()):
		var btn := _create_skin_button(i)
		grid.add_child(btn)

	# Back button
	var back := Button.new()
	back.text = "BACK"
	back.add_theme_font_size_override("font_size", 24)
	back.pressed.connect(_on_shop_back)
	vbox.add_child(back)


func _create_skin_button(index: int) -> Button:
	var skin: Dictionary = GameManager.SKINS[index]

	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 100)
	btn.add_theme_font_size_override("font_size", 20)

	var style := StyleBoxFlat.new()
	style.bg_color = skin["color"]
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = skin["color"].lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = skin["color"].darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style := style.duplicate()
	disabled_style.bg_color = skin["color"].darkened(0.3)
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.7))
	btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 1)

	btn.pressed.connect(_on_skin_button_pressed.bind(index))
	return btn


func _refresh_shop() -> void:
	shop_wallet_label.text = "Wallet: " + str(GameManager.wallet)
	var grid: GridContainer = $ShopPanel/VBoxContainer.get_child(2)
	for i in range(grid.get_child_count()):
		var btn: Button = grid.get_child(i) as Button
		var skin: Dictionary = GameManager.SKINS[i]
		if i == GameManager.selected_skin:
			btn.text = skin["name"] + "\nACTIVE"
			btn.disabled = true
		elif i in GameManager.owned_skins:
			btn.text = skin["name"] + "\nUSE"
			btn.disabled = false
		else:
			var price: int = skin["price"]
			btn.text = skin["name"] + "\n" + str(price)
			btn.disabled = GameManager.wallet < price


func _on_skin_button_pressed(index: int) -> void:
	if index in GameManager.owned_skins:
		GameManager.select_skin(index)
	else:
		GameManager.buy_skin(index)
	_refresh_shop()


func _on_shop_button_pressed() -> void:
	_return_to_panel = start_panel if start_panel.visible else game_over_panel
	_hide_all_panels()
	shop_panel.visible = true
	_refresh_shop()


func _on_shop_back() -> void:
	_hide_all_panels()
	_return_to_panel.visible = true


# ── Leaderboard ──

var leaderboard_list: VBoxContainer

func _build_leaderboard() -> void:
	var vbox: VBoxContainer = $LeaderboardPanel/VBoxContainer

	# Title
	var title := Label.new()
	title.text = "LEADERBOARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	# List container
	leaderboard_list = VBoxContainer.new()
	leaderboard_list.add_theme_constant_override("separation", 6)
	leaderboard_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(leaderboard_list)

	# Back button
	var back := Button.new()
	back.text = "BACK"
	back.add_theme_font_size_override("font_size", 24)
	back.pressed.connect(_on_leaderboard_back)
	vbox.add_child(back)


func _refresh_leaderboard() -> void:
	for child in leaderboard_list.get_children():
		child.queue_free()

	if GameManager.run_history.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No runs yet!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		empty_label.add_theme_font_size_override("font_size", 24)
		leaderboard_list.add_child(empty_label)
		return

	# Header
	var header := _create_leaderboard_row("#", "SCORE", "COINS", Color(0.7, 0.7, 0.7))
	leaderboard_list.add_child(header)

	for i in range(GameManager.run_history.size()):
		var run: Dictionary = GameManager.run_history[i]
		var color := Color.WHITE
		if i == 0:
			color = Color(1.0, 0.85, 0.0)  # Gold for #1
		elif i == 1:
			color = Color(0.8, 0.8, 0.8)  # Silver
		elif i == 2:
			color = Color(0.8, 0.5, 0.2)  # Bronze
		var row := _create_leaderboard_row(
			str(i + 1), str(run["score"]), str(run["coins"]), color)
		leaderboard_list.add_child(row)


func _create_leaderboard_row(rank: String, score_text: String, coins_text: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var rank_label := Label.new()
	rank_label.text = rank
	rank_label.custom_minimum_size = Vector2(50, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_color_override("font_color", color)
	rank_label.add_theme_font_size_override("font_size", 22)
	row.add_child(rank_label)

	var score_lbl := Label.new()
	score_lbl.text = score_text
	score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_lbl.add_theme_color_override("font_color", color)
	score_lbl.add_theme_font_size_override("font_size", 22)
	row.add_child(score_lbl)

	var coins_lbl := Label.new()
	coins_lbl.text = coins_text
	coins_lbl.custom_minimum_size = Vector2(100, 0)
	coins_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	coins_lbl.add_theme_font_size_override("font_size", 22)
	row.add_child(coins_lbl)

	return row


func _on_leaderboard_button_pressed() -> void:
	_return_to_panel = start_panel if start_panel.visible else game_over_panel
	_hide_all_panels()
	leaderboard_panel.visible = true
	_refresh_leaderboard()


func _on_leaderboard_back() -> void:
	_hide_all_panels()
	_return_to_panel.visible = true


# ── Common ──

func _on_start_button_pressed() -> void:
	GameManager.start_game()


func _on_retry_button_pressed() -> void:
	GameManager.start_game()
