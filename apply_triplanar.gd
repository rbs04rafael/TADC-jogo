@tool
extends SceneTree

func _init():
	var scene_path = "res://Cenas/DentroFarol.tscn"
	var packed = load(scene_path)
	if not packed:
		print("Failed to load scene")
		quit()
		return
		
	var root = packed.instantiate()
	var modified = false
	
	var chao_cima = root.get_node_or_null("Farol/ChaoCima")
	if chao_cima:
		for child in chao_cima.get_children():
			if child is MeshInstance3D:
				# Tenta pegar o material
				var mat = child.material_override
				if not mat and child.mesh:
					mat = child.mesh.surface_get_material(0)
				
				if mat is StandardMaterial3D:
					mat.uv1_triplanar = true
					# Ajuda a ficar suave
					mat.uv1_triplanar_sharpness = 10.0
					modified = true
					print("Triplanar enabled for: ", child.name)

	if modified:
		var new_packed = PackedScene.new()
		new_packed.pack(root)
		ResourceSaver.save(new_packed, scene_path)
		print("Scene saved with Triplanar Mapping enabled.")
	else:
		print("No materials found to modify or already triplanar.")
		
	quit()
