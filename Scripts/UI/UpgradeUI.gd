extends CanvasLayer

@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var button1 = $Panel/VBoxContainer/HBoxContainer/Button1
@onready var button2 = $Panel/VBoxContainer/HBoxContainer/Button2
@onready var button3 = $Panel/VBoxContainer/HBoxContainer/Button3

var buttons = []
var input_enabled = false

func _ready():
	buttons = [button1, button2, button3]
	
	# Connect buttons
	button1.pressed.connect(_on_upgrade_selected.bind(0))
	button2.pressed.connect(_on_upgrade_selected.bind(1))
	button3.pressed.connect(_on_upgrade_selected.bind(2))
	
	# Hide initially
	hide()
	
	# Connect to UpgradeManager
	UpgradeManager.upgrade_choices_ready.connect(_on_choices_ready)

func _on_choices_ready(choices):
	# Update button labels
	for i in range(choices.size()):
		if i < buttons.size():
			var upgrade = choices[i]
			buttons[i].text = upgrade.name + "\n" + upgrade.description
			buttons[i].visible = true
			buttons[i].disabled = true # Disable initially
	
	# Hide unused buttons
	for i in range(choices.size(), buttons.size()):
		buttons[i].visible = false
	
	# Show UI
	show()
	
	# Enable input after delay
	input_enabled = false
	await get_tree().create_timer(0.5, true, false, true).timeout
	input_enabled = true
	for btn in buttons:
		if btn.visible:
			btn.disabled = false

func _on_upgrade_selected(index: int):
	if not input_enabled:
		return
	
	UpgradeManager.select_upgrade(index)
	hide()
