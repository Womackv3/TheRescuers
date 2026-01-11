extends Control

@export var ip_address_input: LineEdit

func _on_host_pressed() -> void:
    NetworkManager.host_game()
    # Transition logic

func _on_join_pressed() -> void:
    var ip = "127.0.0.1"
    if ip_address_input and not ip_address_input.text.is_empty():
        ip = ip_address_input.text
        
    NetworkManager.join_game(ip)
