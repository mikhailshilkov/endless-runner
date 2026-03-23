extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var coin_label: Label = $CoinLabel
@onready var heart_container: HBoxContainer = $HeartContainer
@onready var start_panel: PanelContainer = $StartPanel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var final_coins_label: Label = $GameOverPanel/VBoxContainer/FinalCoinsLabel

var shop_section: VBoxContainer
var wallet_label: Label


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.hearts_changed.connect(_on_hearts_changed)
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over.connect(_on_game_over)
	GameManager.wallet_changed.connect(_on_wallet_changed)
	_build_shop()
	_show_start_screen()


func _show_start_screen() -> void:
	start_panel.visible = true
	game_over_panel.visible = false
	score_label.visible = false
	coin_label.visible = false
	heart_container.visible = false
	_move_shop_to($StartPanel/VBoxContainer)
	_refresh_shop()


func _on_game_started() -> void:
	start_panel.visible = false
	game_over_panel.visible = false
	score_label.visible = true
	coin_label.visible = true
	heart_container.visible = true
	_update_hearts(0)
	score_label.text = "0"
	coin_label.text = "0"


func _on_game_over() -> void:
	game_over_panel.visible = true
	final_score_label.text = "Score: " + str(GameManager.score)
	final_coins_label.text = "Coins earned: +" + str(GameManager.coins)
	_move_shop_to($GameOverPanel/VBoxContainer)
	wallet_label.text = "Wallet: " + str(GameManager.wallet)
	_refresh_shop()


func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)


func _on_coins_changed(new_coins: int) -> void:
	coin_label.text = str(new_coins)


func _on_hearts_changed(count: int) -> void:
	_update_hearts(count)


func _on_wallet_changed(_amount: int) -> void:
	if wallet_label:
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


func _build_shop() -> void:
	shop_section = VBoxContainer.new()
	shop_section.add_theme_constant_override("separation", 8)

	# Wallet label
	wallet_label = Label.new()
	wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	wallet_label.add_theme_font_size_override("font_size", 32)
	wallet_label.text = "Wallet: " + str(GameManager.wallet)
	shop_section.add_child(wallet_label)

	# Shop header
	var shop_label := Label.new()
	shop_label.text = "SHOP"
	shop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_label.add_theme_color_override("font_color", Color(1, 1, 1))
	shop_label.add_theme_font_size_override("font_size", 34)
	shop_section.add_child(shop_label)

	# Grid of skin items
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_section.add_child(grid)

	for i in range(GameManager.SKINS.size()):
		var item := _create_skin_item(i)
		grid.add_child(item)


func _create_skin_item(index: int) -> Button:
	var skin: Dictionary = GameManager.SKINS[index]

	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 100)
	btn.add_theme_font_size_override("font_size", 20)

	# Color the button background
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

	# White text with shadow for readability
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.7))
	btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 1)

	btn.pressed.connect(_on_skin_button_pressed.bind(index))
	return btn


func _move_shop_to(parent: VBoxContainer) -> void:
	if shop_section.get_parent():
		shop_section.get_parent().remove_child(shop_section)
	parent.add_child(shop_section)


func _refresh_shop() -> void:
	var grid: GridContainer = shop_section.get_child(2)
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


func _on_start_button_pressed() -> void:
	GameManager.start_game()


func _on_retry_button_pressed() -> void:
	GameManager.start_game()
