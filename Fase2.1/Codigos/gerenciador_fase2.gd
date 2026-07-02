extends Node

var concluido = false
var tempo_checagem = 1.0

@onready var lobby = $CircusLobby

var carrinho_ativo: PathFollow3D = null
var kayke_ref: CharacterBody3D = null
var caminhos_info = [] # Array de dicts: {"carrinho": PathFollow3D, "inicio": Vector3, "nome": String}
var estava_no_caminho: bool = false

func _ready():
	_gerar_colisoes_cenario(lobby)
	
	kayke_ref = get_node_or_null("Kayke")
	if kayke_ref:
		# Começa o jogo em linha reta SEMPRE
		kayke_ref.travar_eixo_z = false
		kayke_ref.travar_eixo_x = true
		kayke_ref.angulo_movimento = PI / 2.0
		
		# Procura se existem caminhos no cenário
		var todos_caminhos = find_children("*", "Path3D", true, false)
		for caminho in todos_caminhos:
			var carrinho = caminho.get_node_or_null("PathFollow3D")
			if not carrinho:
				carrinho = PathFollow3D.new()
				carrinho.name = "PathFollow3D"
				caminho.add_child(carrinho)
				
			carrinho.loop = false
			carrinho.rotation_mode = 1 # Impede de capotar
			
			# Salva a posição exata de onde o caminho começa no mundo 3D
			var inicio = caminho.to_global(caminho.curve.get_point_position(0))
			caminhos_info.append({"carrinho": carrinho, "inicio": inicio, "nome": caminho.name})
		
		# Força a lanterna a ficar ligada e visível na Fase 2
		kayke_ref.tem_lanterna = true
		kayke_ref.lanterna_ligada = true
		if "ref_lanterna" in kayke_ref and kayke_ref.ref_lanterna:
			kayke_ref.ref_lanterna.visible = true
		if "ref_spotlight" in kayke_ref and kayke_ref.ref_spotlight:
			kayke_ref.ref_spotlight.visible = true
		if kayke_ref.has_method("ativar_brilho_corpo"):
			kayke_ref.ativar_brilho_corpo()

	# --- CRIAR CLIMA DE LUZ APAGADA ---
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.02) # Fundo bem escuro
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.05, 0.05, 0.06) # Quase breu total
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	# Desliga o sol e outras luzes
	_desligar_luzes(self)
	print("Fase 2 Iniciada! Colisões geradas.")

func _process(delta):
	# Sistema de detecção: Entra no caminho se chegar perto e apertar pra frente
	if kayke_ref:
		if not kayke_ref.is_on_path:
			if estava_no_caminho:
				# Ela ACABOU de sair do caminho!
				estava_no_caminho = false
				
				# Destrava os eixos rígidos para ela continuar andando na direção que o caminho deixou!
				kayke_ref.travar_eixo_x = false
				kayke_ref.travar_eixo_z = false
				
				# Ajusta a direção física (vetor de movimento) para casar perfeitamente com a última tangente do trilho
				if carrinho_ativo:
					kayke_ref.angulo_movimento = carrinho_ativo.global_rotation.y + (PI / 2.0)
				carrinho_ativo = null
				
			else:
				for info in caminhos_info:
					var distancia = kayke_ref.global_position.distance_to(info["inicio"])
					
					if info["nome"] == "Caminho_Tubo":
						# Se a Kayke estiver a menos de 5 metros da ponta inicial do tubo e tocar no chão (caiu do Bloco_Virada4)
						if distancia < 5.0 and kayke_ref.is_on_floor():
							carrinho_ativo = info["carrinho"]
							kayke_ref.entrar_no_caminho(carrinho_ativo)
							break
					else:
						# Outros caminhos (ex: Caminho_Chão), a menos de 2 metros e precisa apertar pra frente
						if distancia < 2.0:
							var input_dir = Input.get_axis("move_left", "move_right")
							if input_dir > 0:
								carrinho_ativo = info["carrinho"]
								kayke_ref.entrar_no_caminho(carrinho_ativo)
								break
		else:
			estava_no_caminho = true

	if concluido:
		return
		
	tempo_checagem -= delta
	if tempo_checagem <= 0:
		tempo_checagem = 1.0
		_checar_inimigos()

func _checar_inimigos():
	var grupo = get_tree().get_root().find_child("Abstracoes", true, false)
	if grupo:
		if grupo.get_child_count() == 0:
			concluido = true
			_finalizar_fase()

func _finalizar_fase():
	print("Todas as abstrações foram derrotadas na Fase 2!")

func _gerar_colisoes_cenario(node: Node):
	if node is MeshInstance3D:
		var mesh = node.mesh
		if mesh:
			var static_body = StaticBody3D.new()
			var collision_shape = CollisionShape3D.new()
			collision_shape.shape = mesh.create_trimesh_shape()
			static_body.add_child(collision_shape)
			node.add_child(static_body)
	
	for child in node.get_children():
		_gerar_colisoes_cenario(child)

func _desligar_luzes(node: Node):
	if node is Light3D and not "Kayke" in String(node.get_path()):
		node.light_energy = 0.0
		node.visible = false
	
	for child in node.get_children():
		_desligar_luzes(child)
