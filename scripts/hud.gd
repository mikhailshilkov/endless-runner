extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var coin_label: Label = $CoinLabel
@onready var heart_container: HBoxContainer = $HeartContainer
@onready var start_panel: PanelContainer = $StartPanel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var final_coins_label: Label = $GameOverPanel/VBoxContainer/FinalCoinsLabel


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.hearts_changed.connect(_on_hearts_changed)
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over.connect(_on_game_over)
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
	final_coins_label.text = "Coins: " + str(GameManager.coins)


func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)


func _on_coins_changed(new_coins: int) -> void:
	coin_label.text = str(new_coins)


func _on_hearts_changed(count: int) -> void:
	_update_hearts(count)


func _update_hearts(count: int) -> void:
	# Clear existing hearts
	for child in heart_container.get_children():
		child.queue_free()
	# Add heart symbols
	for i in range(count):
		var heart := Label.new()
		heart.text = "\u2764"
		heart.add_theme_font_size_override("font_size", 28)
		heart.add_theme_color_override("font_color", Color(1.0, 0.15, 0.25, 1))
		heart.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		heart_container.add_child(heart)


func _on_start_button_pressed() -> void:
	GameManager.start_game()


func _on_retry_button_pressed() -> void:
	GameManager.start_game()
