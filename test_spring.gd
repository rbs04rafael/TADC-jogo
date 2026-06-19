@tool
extends SceneTree

func _init():
	var s = SpringArm3D.new()
	s.spring_length = 10
	var n = Node3D.new()
	s.add_child(n)
	# Força uma atualização
	s.set_physics_process(true)
	# Na verdade, position só atualiza na árvore.
	print("SpringArm default Z: ", s.get_hit_length())
	quit()
