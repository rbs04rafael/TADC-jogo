extends Node3D

var flashlight : SpotLight3D = null
var is_visible_by_light = false
var area : Area3D
var touched = false

func _ready():
	# Esconder a armadilha no início
	_set_meshes_visible(false)
	
	# Encontrar a área de colisão (Area3D)
	for child in get_children():
		if child is Area3D:
			area = child
			break
			
	if area:
		# Garante que a área consiga detectar a Pomni (Layer 1 e 2)
		area.collision_mask |= 3
		# Conecta o sinal de entrar no espinho
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)
	else:
		print("AVISO: Nenhuma Area3D encontrada na armadilha ", name, "! Adicione uma Area3D como filha.")

	# Buscar a lanterna da Pomni
	call_deferred("_find_flashlight")

func _find_flashlight():
	var jogador = get_tree().get_first_node_in_group("jogador")
	if not jogador:
		var root = get_tree().current_scene
		if root.has_node("The Grounds/Pomni"):
			jogador = root.get_node("The Grounds/Pomni")
	
	if jogador and "ref_spotlight" in jogador:
		flashlight = jogador.ref_spotlight

func _process(_delta):
	if touched:
		return
		
	if not flashlight or not is_instance_valid(flashlight) or not flashlight.visible:
		if is_visible_by_light:
			_set_meshes_visible(false)
			is_visible_by_light = false
		return

	# Checar se a armadilha está dentro do cone da lanterna
	var trap_pos = global_position + Vector3(0, 1.0, 0)
	var light_pos = flashlight.global_position
	var light_dir = -flashlight.global_transform.basis.z.normalized()
	
	var dir_to_trap = (trap_pos - light_pos)
	var dist = dir_to_trap.length()
	
	if dist <= flashlight.spot_range:
		dir_to_trap = dir_to_trap.normalized()
		var angle = rad_to_deg(acos(light_dir.dot(dir_to_trap)))
		# Considerar um ângulo um pouco mais aberto para facilitar a visão
		if angle <= (flashlight.spot_angle): 
			if not is_visible_by_light:
				_set_meshes_visible(true)
				is_visible_by_light = true
			return
			
	if is_visible_by_light:
		_set_meshes_visible(false)
		is_visible_by_light = false

func _set_meshes_visible(v: bool):
	for child in get_children():
		# Não afetar a visibilidade de CollisionShapes ou Areas, apenas malhas
		if not (child is Area3D) and "visible" in child:
			child.visible = v

func _on_body_entered(body):
	if touched: return
	
	if body.name == "Pomni" or body.name == "NoPomni" or body.is_in_group("jogador"):
		touched = true
		_set_meshes_visible(true)
		is_visible_by_light = true
		
		# Morte instantânea
		if body.has_method("receber_dano"):
			# Passa a vida atual como dano para garantir morte imediata
			body.receber_dano(1000.0, Vector3.ZERO, false) 
		else:
			get_tree().reload_current_scene()
