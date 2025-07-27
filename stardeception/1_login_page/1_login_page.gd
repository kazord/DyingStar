extends CanvasLayer


func _on_button_pressed() -> void:
#	TODO Call HTTP request to auth server to authenticate
	get_tree().change_scene_to_file("res://2_main_page/main_page.tscn")
