@tool
extends SceneTree

func _init():
	var path = "res://Personagens/Pomni.tscn"
	var packed = load(path)
	if not packed:
		print("Falhou ao carregar")
		quit()
		return
		
	var root = packed.instantiate()
	
	# Muda a camada de todos os CollisionObject3D (CharacterBody3D, StaticBody3D, etc) para a Layer 2
	# e garante que o mask continue olhando para a Layer 1 (paredes/chão)
	var stack = [root]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is CollisionObject3D:
			node.collision_layer = 2 # Camada 2
			# A Pomni precisa colidir com o chão e paredes (Layer 1) e com itens (Layer 1 ou 2)
			# Godot default mask é 1. Vamos garantir que ela tenha mask 1
			node.collision_mask = 1
		for c in node.get_children():
			stack.push_back(c)
			
	var new_packed = PackedScene.new()
	new_packed.pack(root)
	ResourceSaver.save(new_packed, path)
	print("Layers atualizadas no Pomni.tscn!")
	quit()
