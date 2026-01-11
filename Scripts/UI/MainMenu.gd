extends Control

@export var first_level_scene_path: String = "res://Scenes/Levels/Stage1.tscn"

func _on_start_button_pressed() -> void:
    get_tree().change_scene_to_file(first_level_scene_path)

func _on_exit_button_pressed() -> void:
    get_tree().quit()
