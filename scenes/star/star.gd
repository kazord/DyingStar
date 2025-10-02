extends MeshInstance3D

func _process(_delta: float) -> void:
	if GameOrchestrator.is_server(): return
	var camera = $/root/SystemSandbox/Camera3D#get_viewport().get_camera_3d()
	if camera:
		$DirectionalLight3D.look_at(camera.global_position)
	
