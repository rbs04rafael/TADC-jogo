extends Area3D

@export var angulo_alvo_y: float = 90.0 # Em graus. Para onde a câmera vai virar (ex: 0, 90, 180, -90)
@export var angulo_alvo_camera_y: float = -999.0 # Em graus. Se for diferente de -999.0, a câmera vai virar para este ângulo enquanto a Pomni continua no angulo_alvo_y
@export var duracao_curva: float = 0.5

var ja_ativada: bool = false

func _ready():
	connect("body_entered", _on_body_entered)
	
	# Detecta a qual parte e plataforma esta curva pertence para definir o ângulo correto
	var path_str = str(get_path())
	if "Parte1" in path_str:
		if "Bloco_Virada1" in path_str:
			angulo_alvo_y = 90.0
		elif "Bloco_Virada2" in path_str:
			angulo_alvo_y = 180.0
	elif "Parte2" in path_str:
		if "Bloco_Virada3" in path_str:
			angulo_alvo_y = 270.0
		elif "Bloco_Virada4" in path_str:
			angulo_alvo_y = 0.0
	elif "Parte3" in path_str:
		if "Bloco_Virada5" in path_str:
			angulo_alvo_y = 90.0
		elif "Bloco_Virada6" in path_str:
			angulo_alvo_y = 180.0
			angulo_alvo_camera_y = 90 # A câmera vai olhar de frente/trás em relação ao movimento

func _on_body_entered(body: Node3D):
	if not ja_ativada and body.is_in_group("jogador") and body.has_method("iniciar_curva"):
		ja_ativada = true
		
		var cam_angle_rad = deg_to_rad(angulo_alvo_camera_y) if angulo_alvo_camera_y != -999.0 else -999.0
		
		# Acha o centro VERDADEIRO do bloco (MeshInstance3D ou CollisionShape3D principal do pai)
		# porque o nó Area3D de gatilho está posicionado apenas na beirada para ativar antes.
		var centro_global = global_position
		var pai = get_parent()
		if pai:
			for child in pai.get_children():
				if child is MeshInstance3D or (child is CollisionShape3D and child.name != "Collision"):
					centro_global = child.global_position
					break
				
		# Passa a posição global correta para a Pomni saber onde centralizar
		body.iniciar_curva(deg_to_rad(angulo_alvo_y), duracao_curva, cam_angle_rad, centro_global)
		
		# Desativa temporariamente para não reativar sem querer se a Pomni ficar presa
		await get_tree().create_timer(duracao_curva + 0.5).timeout
		ja_ativada = false
