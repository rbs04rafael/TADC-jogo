extends Node3D

var rafael: Node3D
var direcao_atual: Vector2 = Vector2(1, 0)

var intersecao_ativa: bool = false
var intersecao_opcoes: Array = []
var intersecao_labels: Array = []
var label_aviso: Label
var no_intersecao_atual: Vector3

var pontos_proximos: Array[Area3D] = []
var ultimo_ponto_processado: Area3D = null

var em_cinematica: bool = false
var cam_cinematica: Camera3D

var no_placa_fim: Node3D = null
var label_sucesso: Label
var mostrou_sucesso: bool = false

func _ready():
	rafael = get_node_or_null("NoRafaelFase2")
	if not rafael:
		rafael = get_node_or_null("RafaelFase2")
		
	if rafael:
		rafael.max_pulos = 0
		direcao_atual = _angle_to_dir(rafael.angulo_movimento)
		
	criar_ui()
	
	# Varre o mapa procurando todos os PontoLabirinto e conecta o sinal deles
	conectar_pontos_no_mapa(self)
	
	# Toca o som ambiente da cena em loop
	var som_ambiente = AudioStreamPlayer.new()
	var stream_amb = load("res://Fase2/Cenarios/ambienteNoturno.mp3")
	if stream_amb and stream_amb is AudioStreamMP3:
		stream_amb.loop = true
	som_ambiente.stream = stream_amb
	som_ambiente.volume_db = -5.0 # Volume suave para ambiente
	som_ambiente.autoplay = true
	add_child(som_ambiente)
	
	iniciar_cinematica()

func conectar_pontos_no_mapa(no_pai: Node):
	for filho in no_pai.get_children():
		if filho is Area3D and filho.has_method("_on_ponto_entered"):
			pass
		elif filho.name.begins_with("PontoLabirinto") or filho.name.begins_with("curva"):
			if filho is Area3D:
				filho.body_entered.connect(_on_ponto_entered.bind(filho))
				filho.body_exited.connect(_on_ponto_exited.bind(filho))
		
		# Procura recursivamente
		if filho.get_child_count() > 0:
			conectar_pontos_no_mapa(filho)

func _on_ponto_entered(body: Node3D, ponto: Area3D):
	if body == rafael:
		if not pontos_proximos.has(ponto):
			pontos_proximos.append(ponto)

func _on_ponto_exited(body: Node3D, ponto: Area3D):
	if body == rafael:
		if pontos_proximos.has(ponto):
			pontos_proximos.erase(ponto)
		
		# Se ela saiu completamente do cruzamento, esconde os menus
		if intersecao_ativa and no_intersecao_atual == ponto.global_position:
			limpar_intersecao()
			
		# Permite que ela ative o mesmo ponto de novo se ela entrar nele novamente de ré
		if ultimo_ponto_processado == ponto:
			ultimo_ponto_processado = null

func _physics_process(_delta):
	if em_cinematica: return
	if not rafael or rafael.get("fazendo_curva"): return
	
	# Verifica se a Rafael chegou perto da placa_fim
	if not mostrou_sucesso:
		if not no_placa_fim:
			no_placa_fim = find_child("placa_fim", true, false)
		if no_placa_fim and rafael.global_position.distance_to(no_placa_fim.global_position) < 3.0:
			mostrou_sucesso = true
			exibir_mensagem_sucesso()
	
	# Descobre a direção que a rafael está viajando de verdade
	var input_axis = Input.get_axis("move_left", "move_right")
	var andando_costas = (input_axis < 0)
	
	# Checa todos os pontos próximos para ver se chegamos no centro matemático de algum deles
	var pos_2d = Vector2(rafael.global_position.x, rafael.global_position.z)
	var dir_visual = _angle_to_dir(rafael.angulo_movimento)
	
	for ponto_alvo in pontos_proximos:
		if ponto_alvo == ultimo_ponto_processado:
			continue
			
		var p_pos = Vector2(ponto_alvo.global_position.x, ponto_alvo.global_position.z)
		
		# Calcula a distância separada nos eixos
		var dist_eixo = 0.0
		var dist_cruzado = 0.0
		
		if abs(dir_visual.x) > 0.5: # Andando no eixo X
			dist_eixo = abs(pos_2d.x - p_pos.x)
			dist_cruzado = abs(pos_2d.y - p_pos.y)
		else: # Andando no eixo Z
			dist_eixo = abs(pos_2d.y - p_pos.y)
			dist_cruzado = abs(pos_2d.x - p_pos.x)
			
		# Exige que ela chegue perto (0.4) no eixo em que está andando.
		# O eixo cruzado tem uma tolerância maior (1.0) para perdoar curvas mal alinhadas no Godot,
		# mas impede que ela ative a curva de um corredor vizinho.
		if dist_eixo < 0.4 and dist_cruzado < 1.0:
			processar_ponto(ponto_alvo)
			break # Processa apenas um por frame

func processar_ponto(ponto: Area3D):
	ultimo_ponto_processado = ponto
	
	# Descobre a direção que a rafael está viajando de verdade
	# (Se ela estiver dando ré, o eixo "move_left/right" será negativo)
	var input_axis = Input.get_axis("move_left", "move_right")
	var andando_costas = (input_axis < 0)
	
	var dir_visual = _angle_to_dir(rafael.angulo_movimento)
	var dir_chegada = dir_visual
	if andando_costas:
		dir_chegada = -dir_visual
		
	direcao_atual = dir_chegada
	
	var abertos = ponto.get_direcoes()
	var dir_costas = -dir_chegada
	var opcoes_frente = []
	
	for d in abertos:
		if d != dir_costas:
			opcoes_frente.append(d)
			
	var centro = ponto.global_position
			
	if opcoes_frente.size() == 0:
		# Beco sem saída ou parede: Não faz nada, apenas deixa a física colidir com a parede
		pass
	elif opcoes_frente.size() == 1:
		# Apenas um caminho a frente: vira automaticamente ou segue reto
		fazer_curva(opcoes_frente[0], centro)
	else:
		# Vários caminhos: Mostra o menu de escolhas sem travar a Rafael
		iniciar_intersecao(centro, opcoes_frente, dir_chegada)

func fazer_curva(nova_dir: Vector2, centro: Vector3):
	var input_axis = Input.get_axis("move_left", "move_right")
	var andando_costas = (input_axis < 0)
	
	# Se ela estiver andando de costas, precisamos inverter a direção da câmera
	# para que o "trás" continue apontando para dentro do novo corredor
	if andando_costas:
		nova_dir = -nova_dir
		
	direcao_atual = nova_dir
	var angulo_mov = _dir_to_angle(nova_dir)
	rafael.iniciar_curva(angulo_mov, 0.3, angulo_mov, centro)

func iniciar_intersecao(centro: Vector3, opcoes: Array, dir_chegada: Vector2):
	intersecao_ativa = true
	intersecao_opcoes = opcoes
	no_intersecao_atual = centro
	
	var msg = "Pressione: "
	for i in range(opcoes.size()):
		var d = opcoes[i]
		var lbl = Label3D.new()
		lbl.text = str(i+1)
		lbl.font = load("res://Fase2/Super Warming.ttf")
		lbl.font_size = 100
		lbl.pixel_size = 0.01
		lbl.outline_size = 10
		lbl.modulate = Color(1.0, 1.0, 0.0) 
		lbl.outline_modulate = Color(0, 0, 0)
		
		var pos_lbl = centro + Vector3(d.x, 0.5, d.y) * 1.0
		lbl.position = pos_lbl
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED 
		
		add_child(lbl)
		intersecao_labels.append(lbl)
		
		msg += str(i+1) + " para " + _dir_to_nome(d, dir_chegada)
		if i < opcoes.size() - 1:
			msg += ", "
			
	if label_aviso:
		label_aviso.text = msg

func limpar_intersecao():
	intersecao_ativa = false
	if label_aviso:
		label_aviso.text = ""
	for lbl in intersecao_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	intersecao_labels.clear()

func _input(event):
	if is_instance_valid(canvas_video) and event is InputEventKey and event.pressed:
		_on_video_finished()
		return
		
	if intersecao_ativa and event is InputEventKey and event.pressed:
		var index = -1
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1: index = 0
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2: index = 1
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3: index = 2
		elif event.keycode == KEY_4 or event.keycode == KEY_KP_4: index = 3
		
		if index >= 0 and index < intersecao_opcoes.size():
			var dir_escolhida = intersecao_opcoes[index]
			limpar_intersecao()
			fazer_curva(dir_escolhida, no_intersecao_atual)

func criar_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	label_aviso = Label.new()
	label_aviso.text = ""
	label_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_aviso.add_theme_font_override("font", load("res://Fase2/Super Warming.ttf"))
	label_aviso.add_theme_font_size_override("font_size", 40)
	label_aviso.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label_aviso.add_theme_constant_override("outline_size", 8)
	label_aviso.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label_aviso.offset_top = 80
	canvas.add_child(label_aviso)
	
	label_sucesso = Label.new()
	label_sucesso.text = "VOCÊ CONSEGUIU!"
	label_sucesso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_sucesso.add_theme_font_override("font", load("res://Fase2/Super Warming.ttf"))
	label_sucesso.add_theme_font_size_override("font_size", 60)
	label_sucesso.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2)) # Verde vibrante
	label_sucesso.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label_sucesso.add_theme_constant_override("outline_size", 15)
	label_sucesso.set_anchors_preset(Control.PRESET_CENTER)
	label_sucesso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label_sucesso.grow_vertical = Control.GROW_DIRECTION_BOTH
	label_sucesso.hide() # Fica escondido até chegar na placa
	canvas.add_child(label_sucesso)

func exibir_mensagem_sucesso():
	if label_sucesso:
		label_sucesso.show()
		var tween = create_tween()
		label_sucesso.scale = Vector2(0.1, 0.1)
		label_sucesso.pivot_offset = label_sucesso.size / 2.0
		tween.tween_property(label_sucesso, "scale", Vector2(1.2, 1.2), 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(label_sucesso, "scale", Vector2(1.0, 1.0), 0.5)

func _dir_to_angle(dir: Vector2) -> float:
	if dir == Vector2(1, 0): return 0.0
	if dir == Vector2(-1, 0): return PI
	if dir == Vector2(0, -1): return PI / 2.0
	if dir == Vector2(0, 1): return -PI / 2.0
	return 0.0

func _angle_to_dir(ang: float) -> Vector2:
	var cos_a = cos(ang)
	var sin_a = -sin(ang)
	if abs(cos_a) > abs(sin_a):
		return Vector2(sign(cos_a), 0)
	else:
		return Vector2(0, sign(sin_a))

func _dir_to_nome(dir: Vector2, frente: Vector2) -> String:
	if dir == frente: return "Frente"
	var esquerda = Vector2(frente.y, -frente.x)
	if dir == esquerda: return "Esquerda"
	var direita = Vector2(-frente.y, frente.x)
	if dir == direita: return "Direita"
	return "Voltar"

var luz_cinematica: DirectionalLight3D
var canvas_video: CanvasLayer

func iniciar_cinematica():
	if not rafael: return
	em_cinematica = true
	
	# Desabilita o processamento da Rafael temporariamente para que o jogador não se mova
	rafael.set_physics_process(false)
	rafael.set_process(false)
	rafael.set_process_input(false)
	rafael.set_process_unhandled_input(false)
	
	# Cria a interface para o vídeo
	canvas_video = CanvasLayer.new()
	canvas_video.layer = 100 # Garante que fique por cima de tudo
	add_child(canvas_video)
	
	# Fundo preto para caso a tela seja mais larga que o vídeo
	var bg_preto = ColorRect.new()
	bg_preto.color = Color(0, 0, 0, 1)
	bg_preto.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_video.add_child(bg_preto)
	
	# Toca o vídeo em qualidade máxima/tela cheia
	var vp = VideoStreamPlayer.new()
	var stream_video = load("res://Fase2/Cenarios/CenarioLabirinto/intro_convertido.ogv")
	
	if stream_video == null:
		print("AVISO: Vídeo não pôde ser carregado. Pulando para a cinemática.")
		canvas_video.queue_free()
		_iniciar_visao_de_cima()
		return
		
	vp.stream = stream_video
	vp.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.expand = true 
	vp.autoplay = true
	vp.finished.connect(_on_video_finished)
	canvas_video.add_child(vp)

func _on_video_finished():
	if is_instance_valid(canvas_video):
		canvas_video.queue_free()
	
	_iniciar_visao_de_cima()

func _iniciar_visao_de_cima():
	# Cria a câmera cinemática
	cam_cinematica = Camera3D.new()
	cam_cinematica.far = 10000.0
	add_child(cam_cinematica)
	
	# Cria uma luz global temporária para iluminar o labirinto visto de cima
	luz_cinematica = DirectionalLight3D.new()
	luz_cinematica.rotation_degrees = Vector3(-90, 0, 0)
	luz_cinematica.light_energy = 1.0 # Brilho inicial
	add_child(luz_cinematica)
	
	# Posiciona a câmera cinemática no alto do labirinto (visão de cima)
	cam_cinematica.global_position = Vector3(0.0, 20.0, 0.0)
	cam_cinematica.rotation_degrees = Vector3(-90, 0, 0)
	cam_cinematica.current = true
	
	# Aguarda 3 segundos na visão de cima
	await get_tree().create_timer(3.0).timeout
	
	finalizar_cinematica()

func finalizar_cinematica():
	if not rafael or not is_instance_valid(cam_cinematica):
		return
		
	var cam_rafael: Camera3D = null
	var pivot = rafael.get("_camera_pivot")
	if pivot:
		cam_rafael = pivot.get_node_or_null("Camera3D")
	if not cam_rafael:
		cam_rafael = rafael.get_node_or_null("Camera3D")
		
	if cam_rafael:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		
		# Anima a posição e rotação da câmera cinemática para a da Rafael
		tween.tween_property(cam_cinematica, "global_transform", cam_rafael.global_transform, 2.0)
		
		# Anima a intensidade da luz diminuindo suavemente até apagar totalmente (em paralelo)
		if is_instance_valid(luz_cinematica):
			tween.parallel().tween_property(luz_cinematica, "light_energy", 0.0, 2.0)
		
		await tween.finished
		
		# Devolve a visão para a câmera da Rafael e remove a cinemática se a cena ainda for válida
		if is_instance_valid(cam_rafael):
			cam_rafael.current = true
	
	
	if is_instance_valid(cam_cinematica):
		cam_cinematica.queue_free()
		
	if is_instance_valid(luz_cinematica):
		luz_cinematica.queue_free()
		
	# Reabilita a Rafael
	em_cinematica = false
	if is_instance_valid(rafael):
		rafael.set_physics_process(true)
		rafael.set_process(true)
		rafael.set_process_input(true)
		rafael.set_process_unhandled_input(true)
