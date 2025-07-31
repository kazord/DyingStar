extends CanvasLayer

func _on_ready() -> void:
	BackgrounMusic.play_music_level()
	pass


func _on_button_pressed() -> void:
#	TODO Call HTTP request to auth server to authenticate
	Globals.playerName = $Username.get_text()
	if Globals.playerName == "":
		Globals.playerName = "I am an idiot !"
	get_tree().change_scene_to_file("res://2_main_page/main_page.tscn")
