extends Node3D

var pomni: CharacterBody3D = null
var decisao_atual: Area3D = null
var persegui_ativa: bool = false
var labels_flutuantes = []
var historico_caminhos = []
var anjo = null

func _ready():
	# Tenta encontrar a Pomni na cena
	pomni = get_tree().get_root().find_child("Pomni", true, false)
	
	# Na Fase 3 (Perseguição), a Pomni já tem a lanterna garantida
	if pomni and pomni.has_method("equipar_lanterna"):
		pomni.equipar_lanterna()
		
		# Deixa a lanterna mais forte e com raio maior EXCLUSIVAMENTE nessa fase!
		var ref_spotlight = pomni.get("ref_spotlight")
		if ref_spotlight:
			ref_spotlight.spot_range = 25.0  # Alcance maior (o original era 10)
			ref_spotlight.spot_angle = 40.0  # Cone de luz mais largo (o original era 20)
			ref_spotlight.light_energy = 25.0 # Luz mais intensa (a original era 15)
	
	# Conecta o sinal da entrada do caminho principal
	var entrada = get_node_or_null("EntradaCaminho")
	if entrada:
		entrada.body_entered.connect(_on_entrada_entered)
		
	# Conecta a área do Início da Perseguição para spawnar o Anjo
	var inicio_perseg = get_node_or_null("InicioPerseguicao")
	if inicio_perseg:
		inicio_perseg.body_entered.connect(_on_inicio_perseguicao_entered)
		
	# Conecta os sinais das 3 decisões
	for i in range(1, 10):
		var decisao = get_node_or_null("Decisao" + str(i))
		if decisao:
			decisao.body_entered.connect(_on_decisao_entered.bind(decisao))
			
	# Conecta o sinal do portal de saída (se quiser fazer algo ao terminar)
	var saida = get_node_or_null("PortalSaida/Area3D")
	if saida:
		saida.body_entered.connect(_on_saida_entered)

func _on_entrada_entered(body: Node3D):
	if body == pomni:
		print("Pomni entrou nos tubos!")
		var path_follow = get_node_or_null("EntradaCaminho/CaminhoInicial/PathFollow3D")
		if path_follow and pomni.has_method("entrar_no_caminho"):
			historico_caminhos.append(path_follow) # Salva no histórico para o Anjo
			pomni.entrar_no_caminho(path_follow)
			pomni.set("esperando_decisao", false)
			persegui_ativa = true
	elif body == anjo:
		print("Anjo alcançou a entrada dos tubos!")
		# O Anjo só entra fisicamente no tubo quando ELE encosta na área!
		if historico_caminhos.size() > 0 and not anjo.get("is_on_path"):
			anjo.iniciar_no_caminho(historico_caminhos[0])

func _on_inicio_perseguicao_entered(body: Node3D):
	if body == pomni and anjo == null:
		print("Pomni passou no gatilho! Spawnando Anjo...")
		var cena_anjo = load("res://Personagens/Anjo/Anjo.tscn")
		if cena_anjo:
			anjo = cena_anjo.instantiate()
			get_tree().current_scene.add_child(anjo)
			
			# Configura o Anjo
			anjo.set("gerenciador_tubos", self)
			
			# Posiciona ele exatamente no PontoSpawn do mapa!
			var pos_inicial = get_tree().get_root().find_child("PontoSpawn", true, false)
			if pos_inicial:
				anjo.global_position = pos_inicial.global_position
			
			# Se a Pomni já entrou no tubo (caso a área InicioPerseguicao seja acionada depois), bota ele no tubo!
			if historico_caminhos.size() > 0:
				anjo.iniciar_no_caminho(historico_caminhos[0])
			
			# Inicia a cinemática de revelação!
			_iniciar_cinematica_anjo()

func _iniciar_cinematica_anjo():
	# Congela a Pomni e o Anjo temporariamente
	pomni.set_physics_process(false)
	pomni.set_process(false) # Desativa a câmera do script da Pomni pra não lutar contra o Tween
	pomni.set_process_unhandled_input(false)
	anjo.set_physics_process(false)
	
	var cam_pomni = pomni.find_child("Camera3D", true, false)
	if cam_pomni:
		# Cria a câmera cinematográfica temporária
		var cam_cinematica = Camera3D.new()
		get_tree().current_scene.add_child(cam_cinematica)
		
		# 1. Copia a posição e rotação EXATA de onde a câmera da Pomni está agora
		cam_cinematica.global_transform = cam_pomni.global_transform
		var original_quat = cam_cinematica.quaternion
		cam_cinematica.current = true
		
		# 2. Descobre a rotação alvo (olhando pro monstro)
		var dummy = Node3D.new()
		get_tree().current_scene.add_child(dummy)
		dummy.global_transform = cam_pomni.global_transform
		dummy.look_at(anjo.global_position + Vector3(0, 1.5, 0), Vector3.UP)
		var quat_alvo = dummy.quaternion
		dummy.queue_free()
		
		# 3. Anima a câmera girando usando interpolação esférica (perfeita para visão em 3D)
		var tween = get_tree().create_tween()
		tween.tween_property(cam_cinematica, "quaternion", quat_alvo, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# 4. Fica olhando pro monstro (2.0 segundos totais)
		await get_tree().create_timer(2.0).timeout
		
		# 5. Gira a câmera suavemente DE VOLTA para a posição original das costas da Pomni
		var tween_volta = get_tree().create_tween()
		tween_volta.tween_property(cam_cinematica, "quaternion", original_quat, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween_volta.finished
		
		# Devolve a visão para a Pomni real
		cam_cinematica.queue_free()
		cam_pomni.current = true
	else:
		# Fallback de segurança
		await get_tree().create_timer(2.0).timeout
		
	# Solta os monstros!
	pomni.set_physics_process(true)
	pomni.set_process(true)
	pomni.set_process_unhandled_input(true)
	if is_instance_valid(anjo):
		anjo.set_physics_process(true)

func _on_decisao_entered(body: Node3D, area_decisao: Area3D):
	if body == pomni:
		print("Chegou na decisão: ", area_decisao.name)
		decisao_atual = area_decisao
		# Puxa o freio de mão usando a nova variável
		pomni.set("esperando_decisao", true)
		_mostrar_numeros(area_decisao)

func _unhandled_input(event):
	if decisao_atual == null or not persegui_ativa:
		return
		
	if event is InputEventKey and event.pressed:
		# Só processa se for tecla 1 ou 2
		if event.keycode != KEY_1 and event.keycode != KEY_2:
			return
			
		var nome_decisao = decisao_atual.name
		var vai_para_o_certo = false
		
		# Regra pedida: Na Decisao1 e Decisao2, botão 1 = Certo, botão 2 = Errado.
		if nome_decisao == "Decisao1" or nome_decisao == "Decisao2":
			if event.keycode == KEY_1:
				vai_para_o_certo = true
			elif event.keycode == KEY_2:
				vai_para_o_certo = false
		# Regra pedida: Na última (Decisao3), botão 1 = Errado, botão 2 = Certo.
		else:
			if event.keycode == KEY_1:
				vai_para_o_certo = false
			elif event.keycode == KEY_2:
				vai_para_o_certo = true
				
		var nome_caminho = "CaminhoCerto" if vai_para_o_certo else "CaminhoErrado"
		_fazer_escolha_por_nome(nome_caminho)

func _fazer_escolha_por_nome(nome_caminho: String):
	var caminho_escolhido = decisao_atual.get_node_or_null(nome_caminho)
	
	if caminho_escolhido == null:
		print("Erro: Caminho ", nome_caminho, " não encontrado!")
		return
		
	var path_follow = caminho_escolhido.get_node_or_null("PathFollow3D")
	if path_follow and pomni.has_method("entrar_no_caminho"):
		print("Escolha feita! Pegou o caminho: ", caminho_escolhido.name)
		_esconder_numeros() # Esconde os textos flutuantes
		
		# Registra o caminho que ela pegou no histórico pro anjo seguir
		if not historico_caminhos.has(path_follow):
			historico_caminhos.append(path_follow)
			
		pomni.entrar_no_caminho(path_follow)
		pomni.set("esperando_decisao", false) # Solta o freio
		decisao_atual = null # Limpa a decisão
		get_viewport().set_input_as_handled()

func _mostrar_numeros(area: Area3D):
	_esconder_numeros() # Garante limpeza
	
	var nome_decisao = area.name
	var caminho_certo = area.get_node_or_null("CaminhoCerto")
	var caminho_errado = area.get_node_or_null("CaminhoErrado")
	
	# Verifica se ela está vindo/parada no caminho errado (para não mostrar o número na cara dela)
	var ignorar_errado = false
	var trilho = pomni.get("trilho_atual")
	if trilho and trilho.get_parent() == caminho_errado:
		ignorar_errado = true
	
	if nome_decisao == "Decisao1" or nome_decisao == "Decisao2":
		if caminho_certo: _criar_label(caminho_certo, "1")
		if caminho_errado and not ignorar_errado: _criar_label(caminho_errado, "2")
	else:
		if caminho_errado and not ignorar_errado: _criar_label(caminho_errado, "1")
		if caminho_certo: _criar_label(caminho_certo, "2")

func _criar_label(caminho: Path3D, texto: String):
	var label = Label3D.new()
	label.text = texto
	label.font_size = 500
	label.outline_size = 30
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true # Garante que não fique escondido dentro do tubo
	label.modulate = Color(1, 1, 0) # Cor amarela bonita
	
	# Coloca o número a 3 metros à frente no tubo (se houver curva)
	var pos_local = Vector3(0, 0, 0)
	if caminho.curve and caminho.curve.get_baked_length() > 3.0:
		pos_local = caminho.curve.sample_baked(3.0)
	else:
		pos_local = Vector3(0, 0, -3.0) # Fallback
		
	caminho.add_child(label)
	
	# Usar posição global garante que o número não sofra interferência da rotação/escala do Path3D
	label.top_level = true
	var pos_global = caminho.to_global(pos_local)
	label.global_position = pos_global + Vector3(0, 2.0, 0) # Fica 2 metros ACIMA no mundo global
	labels_flutuantes.append(label)

func _esconder_numeros():
	for label in labels_flutuantes:
		if is_instance_valid(label):
			label.queue_free()
	labels_flutuantes.clear()


func _on_saida_entered(body: Node3D):
	if body == pomni:
		print("Fim da perseguição!")
		persegui_ativa = false
		pomni.set("esperando_decisao", false)
		if pomni.has_method("sair_do_caminho"):
			pomni.sair_do_caminho()
			
		# Transição para o escritório do Caine
		get_tree().call_deferred("change_scene_to_file", "res://Cenas/CenaCaineOffice.tscn")
