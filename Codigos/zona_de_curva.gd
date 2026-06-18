extends Area3D

@export var angulo_alvo_y: float = 90.0 # Em graus. Para onde a câmera vai virar (ex: 0, 90, 180, -90)
@export var duracao_curva: float = 0.5

var ja_ativada: bool = false

func _ready():
	connect("body_entered", _on_body_entered)
	
	# Detecta a qual parte e plataforma esta curva pertence para definir o ângulo correto
	var path_str = str(get_path())
	if "Parte1" in path_str:
		if "Platform_2" in path_str:
			angulo_alvo_y = 90.0
		elif "Platform_5" in path_str:
			angulo_alvo_y = 180.0
	elif "Parte2" in path_str:
		if "Platform_2" in path_str:
			angulo_alvo_y = 270.0
		elif "Platform_5" in path_str:
			angulo_alvo_y = 0.0
	elif "Parte3" in path_str:
		if "Platform_2" in path_str:
			# A Parte3 tem uma rotação suave de ~6 graus, então 90 graus é o ideal relativo
			angulo_alvo_y = 90.0
		elif "Platform_5" in path_str:
			angulo_alvo_y = 180.0

func _on_body_entered(body: Node3D):
	if not ja_ativada and body.is_in_group("jogador") and body.has_method("iniciar_curva"):
		ja_ativada = true
		body.iniciar_curva(deg_to_rad(angulo_alvo_y), duracao_curva)
		
		# Desativa temporariamente para não reativar sem querer se a Pomni ficar presa
		await get_tree().create_timer(duracao_curva + 0.5).timeout
		ja_ativada = false
