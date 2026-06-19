extends Area3D

var lanterna_coletada = false

func _ready():
	# Garante que o CaminhoEscada fique oculto até a lanterna ser pega
	var cena_raiz = get_tree().get_root()
	var caminho = cena_raiz.find_child("CaminhoEscada", true, false)
	if caminho:
		caminho.visible = false

func _process(delta):
	if lanterna_coletada:
		return
		
	# Acha a Pomni no grupo 'jogador'
	var pomni = null
	var jogadores = get_tree().get_nodes_in_group("jogador")
	if jogadores.size() > 0:
		pomni = jogadores[0]
		
	if pomni:
		var distancia = global_position.distance_to(pomni.global_position)
		# Se estiver a menos de 6 metros da LampadaFarol
		if distancia < 6.0:
			if Input.is_physical_key_pressed(KEY_E) or Input.is_key_pressed(KEY_E):
				_coletar_lanterna(pomni)

func _coletar_lanterna(pomni):
	lanterna_coletada = true
	print("Interação: Pomni coletou a lanterna da LampadaFarol!")
	
	if pomni.has_method("equipar_lanterna"):
		pomni.equipar_lanterna()
		
	# Ativa o modo ESCURO TOTAL
	var cena_raiz = get_tree().get_root()
	var luz_sol = cena_raiz.find_child("DirectionalLight3D", true, false)
	if luz_sol:
		luz_sol.light_energy = 0.0 # Apaga o sol
		
	var env = cena_raiz.find_child("WorldEnvironment", true, false)
	if env and env.environment:
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color(0, 0, 0)
		env.environment.ambient_light_energy = 0.0 # Sem luz ambiente
		
	# Ativa o caminho guiado e prende a Pomni a ele
	var caminho = cena_raiz.find_child("CaminhoEscada", true, false)
	if caminho:
		caminho.visible = true
		var carrinho = caminho.find_child("CarrinhoEscada", true, false)
		if carrinho and pomni.has_method("entrar_no_caminho"):
			pomni.entrar_no_caminho(carrinho)
			
	# Oculta o objeto da lanterna no farol (assumindo que o pai desta área é a mesh visual)
	var lampada_visual = get_parent()
	if lampada_visual:
		lampada_visual.visible = false


