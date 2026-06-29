extends CharacterBody3D

var trilho_anjo: PathFollow3D = null
var gerenciador_tubos: Node3D = null
var is_on_path: bool = false
var progress_index: int = 0
var speed: float = 9 # Um pouco mais rápido que a Pomni (que tem run_speed = 8.0)

@onready var visual_model: Node3D = $Anjo
@onready var collision: CollisionShape3D = $CollisionShape3D

func _ready():
	# Configura a colisão para detectar a Pomni
	# Se a Pomni for um CharacterBody3D, podemos apenas detectar colisão no move_and_slide
	pass

func iniciar_no_caminho(path_follow: PathFollow3D):
	if trilho_anjo:
		trilho_anjo.queue_free()
		
	var path3d = path_follow.get_parent()
	trilho_anjo = PathFollow3D.new()
	path3d.add_child(trilho_anjo)
	
	is_on_path = true
	progress_index = 0
	
	trilho_anjo.progress = 0.0
	global_position = trilho_anjo.global_position

func _physics_process(delta: float):
	if not is_on_path or trilho_anjo == null:
		# Se ainda não está no trilho (a Pomni não entrou ainda), voa na direção dela!
		if gerenciador_tubos != null:
			var pomni_node = get_tree().get_root().find_child("Pomni", true, false)
			if pomni_node:
				var dir = global_position.direction_to(pomni_node.global_position)
				global_position += dir * speed * delta
				rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 8 * delta)
				
				var bateu = move_and_slide()
				if bateu:
					for i in get_slide_collision_count():
						var col = get_slide_collision(i)
						if col.get_collider() and col.get_collider().name == "Pomni":
							_matar_pomni(col.get_collider())
		return
		
	# Move o Anjo pelo trilho atual
	trilho_anjo.progress += speed * delta
	
	# Rotaciona para olhar para a frente no caminho
	var rotacao_caminho = trilho_anjo.global_rotation.y
	rotation.y = lerp_angle(rotation.y, rotacao_caminho - PI, 8 * delta)
	
	# Atualiza a posição no mundo
	global_position = trilho_anjo.global_position
	
	# Se chegou no final desse trilho
	if trilho_anjo.progress_ratio >= 0.99:
		_buscar_proximo_caminho()
		
	# Verifica colisão com a Pomni usando a física
	var bateu_trilho = move_and_slide()
	if bateu_trilho:
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			if col.get_collider() and col.get_collider().name == "Pomni":
				_matar_pomni(col.get_collider())

func _buscar_proximo_caminho():
	if gerenciador_tubos == null:
		return
		
	var historico = gerenciador_tubos.get("historico_caminhos")
	if historico and historico.size() > progress_index + 1:
		progress_index += 1
		var path_follow = historico[progress_index]
		var path3d = path_follow.get_parent()
		if trilho_anjo:
			trilho_anjo.queue_free()
		trilho_anjo = PathFollow3D.new()
		path3d.add_child(trilho_anjo)
		trilho_anjo.progress = 0.0
	else:
		# Se não tem mais caminho no histórico, significa que ele alcançou a Pomni na área de decisão!
		if trilho_anjo:
			trilho_anjo.progress_ratio = 0.99

func _matar_pomni(pomni_node: Node3D):
	if pomni_node.has_method("receber_dano"):
		print("Anjo pegou a Pomni!")
		pomni_node.receber_dano(100, global_position)
		# Desativa o anjo pra não ficar chamando 1000 vezes
		set_physics_process(false)
