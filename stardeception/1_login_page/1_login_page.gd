extends CanvasLayer


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://2_main_page/main_page.tscn")
