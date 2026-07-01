extends Area3D

@export var duracao_curva: float = 0.5

@export var angulo_movimento_y: float = -999.0
@export var angulo_camera_y: float = -999.0
var ja_ativada: bool = false

func _ready():
	connect("body_entered", _on_body_entered)
	
	var meu_caminho = str(get_path())
	if "Bloco_Virada1" in meu_caminho:
		angulo_movimento_y = 270.0
		angulo_camera_y = 180.0
	elif "Bloco_Virada2" in meu_caminho or "blocoa" in meu_caminho:
		angulo_movimento_y = 180.0
		angulo_camera_y = 90.0
	elif "Bloco_Virada3" in meu_caminho:
		angulo_movimento_y = 90.0
		angulo_camera_y = 0.0
	elif "Bloco_Virada4" in meu_caminho:
		angulo_movimento_y = 0.0
		angulo_camera_y = 270.0
	else:
		# Fallback seguro caso mude o nome de algum outro
		angulo_movimento_y = 0.0
		angulo_camera_y = 270.0

func _on_body_entered(body: Node3D):
	if not ja_ativada and body.is_in_group("jogador") and body.has_method("iniciar_curva"):
		ja_ativada = true
		
		# Implementação de centralização igual à Fase 1
		var centro_global = global_position
		var pai = get_parent()
		if pai:
			for child in pai.get_children():
				if child is MeshInstance3D or (child is CollisionShape3D and child.name != "Collision"):
					centro_global = child.global_position
					break
		
		if "Bloco_Virada1" in str(get_path()) and "checkpoint_ativo" in body:
			body.checkpoint_ativo = true
			# Salva a posição um pouco acima do bloco para não nascer enterrada
			body.checkpoint_pos = centro_global + Vector3(0, 1.0, 0)
			
		body.iniciar_curva(deg_to_rad(angulo_movimento_y), duracao_curva, deg_to_rad(angulo_camera_y), centro_global)
		
		await get_tree().create_timer(duracao_curva + 0.5).timeout
		ja_ativada = false
