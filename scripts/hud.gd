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


func _on_start_button_pressed() -> void:
	GameManager.start_game()


func _on_retry_button_pressed() -> void:
	GameManager.start_game()
