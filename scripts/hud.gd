extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var coin_label: Label = $CoinLabel
@onready var heart_container: HBoxContainer = $HeartContainer
@onready var start_panel: PanelContainer = $StartPanel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var final_coins_label: Label = $GameOverPanel/VBoxContainer/FinalCoinsLabel

var shop_container: GridContainer
var wallet_label: Label
var skin_buttons: Array[Button] = []


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
	# Left lobe
	var left := ColorRect.new()
	left.color = Color(1.0, 0.15, 0.25, 1)
	left.position = Vector2(2, 2)
	left.size = Vector2(12, 12)
	container.add_child(left)
	# Right lobe
	var right := ColorRect.new()
	right.color = Color(1.0, 0.15, 0.25, 1)
	right.position = Vector2(14, 2)
	right.size = Vector2(12, 12)
	container.add_child(right)
	# Bottom diamond
	var bottom := ColorRect.new()
	bottom.color = Color(1.0, 0.15, 0.25, 1)
	bottom.position = Vector2(4, 10)
	bottom.size = Vector2(20, 14)
	bottom.rotation = 0.785  # 45 degrees
	bottom.pivot_offset = Vector2(10, 0)
	container.add_child(bottom)
	return container


func _build_shop() -> void:
	var vbox: VBoxContainer = $GameOverPanel/VBoxContainer

	# Wallet label
	wallet_label = Label.new()
	wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	wallet_label.add_theme_font_size_override("font_size", 20)
	wallet_label.text = "Wallet: 0"
	vbox.add_child(wallet_label)
	vbox.move_child(wallet_label, 3)  # After FinalCoinsLabel

	# Shop header
	var shop_label := Label.new()
	shop_label.text = "SHOP"
	shop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_label.add_theme_color_override("font_color", Color(1, 1, 1))
	shop_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(shop_label)
	vbox.move_child(shop_label, 4)

	# Grid of skin buttons
	shop_container = GridContainer.new()
	shop_container.columns = 4
	shop_container.add_theme_constant_override("h_separation", 8)
	shop_container.add_theme_constant_override("v_separation", 8)
	vbox.add_child(shop_container)
	vbox.move_child(shop_container, 5)

	for i in range(GameManager.SKINS.size()):
		var btn := _create_skin_button(i)
		shop_container.add_child(btn)
		skin_buttons.append(btn)


func _create_skin_button(index: int) -> Button:
	var skin: Dictionary = GameManager.SKINS[index]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(70, 60)
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(_on_skin_button_pressed.bind(index))

	# Add a color swatch as a child
	var swatch := ColorRect.new()
	swatch.color = skin["color"]
	swatch.custom_minimum_size = Vector2(30, 20)
	swatch.size = Vector2(30, 20)
	swatch.position = Vector2(20, 4)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(swatch)

	return btn


func _refresh_shop() -> void:
	for i in range(skin_buttons.size()):
		var btn: Button = skin_buttons[i]
		var skin: Dictionary = GameManager.SKINS[i]
		if i == GameManager.selected_skin:
			btn.text = "\n" + skin["name"] + "\nACTIVE"
			btn.disabled = true
		elif i in GameManager.owned_skins:
			btn.text = "\n" + skin["name"] + "\nUSE"
			btn.disabled = false
		else:
			var price: int = skin["price"]
			btn.text = "\n" + skin["name"] + "\n" + str(price)
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
