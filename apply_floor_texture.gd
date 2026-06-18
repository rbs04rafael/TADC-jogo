@tool
extends SceneTree

func _init():
	var scene_path = "res://Cenas/DentroFarol.tscn"
	var tex_path = "res://Texturas/chao_pedra.png"
	
	var tex = load(tex_path)
	if not tex:
		print("ERROR: Texture not found")
		quit()
		return
		
	var material = StandardMaterial3D.new()
	material.albedo_texture = tex
	material.uv1_scale = Vector3(10, 10, 10) # Tiling
	material.cull_mode = BaseMaterial3D.CULL_DISABLED # Torna visível por baixo também

	var packed = load(scene_path)
	var root = packed.instantiate()
	
	var applied_count = 0
	
	# Função recursiva para aplicar o material
	var call_apply = Callable(self, "apply_mat")
	call_apply.call(root, material)
	
	var new_packed = PackedScene.new()
	new_packed.pack(root)
	ResourceSaver.save(new_packed, scene_path)
	print("Material applied to floors successfully.")
	quit()

func apply_mat(node: Node, mat: Material):
	if "Chao" in node.name and node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		apply_mat(child, mat)
