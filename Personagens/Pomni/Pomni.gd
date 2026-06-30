extends CharacterBody3D

# --- VARIÁVEIS DE CONFIGURAÇÃO ---
@export var speed: float = 5.0
@export var run_speed: float = 10.0
@export var jump_velocity: float = 6.0
@export var acceleration: float = 20.0
@export var friction: float = 15

var max_pulos: int = 2
var pulos_dados: int = 0

var vida: float = 100.0
var vida_maxima: float = 100.0
var regenerando: bool = true

var coracoes: Array = []
var qtd_coracoes: int = 5

var particulas_passos: CPUParticles3D

var z_inicial: float
var x_inicial: float
var travar_eixo_z: bool = true
var travar_eixo_x: bool = false
var linha_inicio: Vector2
var linha_fim: Vector2
var travar_na_linha: bool = false
var usar_linha_pendente: bool = false
var linha_inicio_pendente: Vector2
var linha_fim_pendente: Vector2
var esta_correndo: bool = false
var esta_socando: bool = false

# --- VARIÁVEIS DA BATALHA FINAL ---
var em_batalha_final: bool = false
var camera_batalha_rot: Vector3 = Vector3.ZERO
var posicao_z_congelada: float = 0.0
var posicao_x_min: float = 0.0
var posicao_x_max: float = 0.0

# --- VARIÁVEIS DA LANTERNA E ARMA ---
var tem_lanterna: bool = false
var lanterna_ligada: bool = false
var lanterna_offset_pos: Vector3 = Vector3.ZERO
var ref_lanterna: Node3D = null
var ref_spotlight: SpotLight3D = null

var tem_arma: bool = false

# Variáveis para controle do tempo no double-tap
var ultimo_click_esquerda: int = 0
var ultimo_click_direita: int = 0
var intervalo_double_tap: int = 300 # Tempo máximo em milissegundos entre os toques

# Cooldown para soco/tiro contínuo
var tempo_ultimo_ataque: float = 0.0

# --- VARIÁVEIS DO CAMINHO ---
var is_on_path: bool = false
var trilho_atual: PathFollow3D = null # Guarda o carrinho que a Pomni está usando no momento
var esperando_decisao: bool = false # Variável para travar a Pomni nas bifurcações dos tubos

# Gravidade
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- VARIÁVEIS DE ESCALADA ---
var is_climbing: bool = false
var escada_atual: Area3D = null
var escada_pendente: Area3D = null

# --- SISTEMA DE CURVA (Desacoplado da física) ---
var angulo_movimento: float = 0.0  # Ângulo atual de movimento em radianos
var fazendo_curva: bool = false

# Pivô da câmera — criado em _ready() para orbitar sem rotacionar o CharacterBody3D
var _camera_pivot: Node3D = null
var _original_cam_pos: Vector3
var _target_cam_pos: Vector3
var _cam_ray: RayCast3D

# --- VARIÁVEIS DA ÁGUA E DANO ---
var na_agua: bool = false
var altura_agua: float = 0.0
var tempo_vermelho: float = 0.0

# --- REFERÊNCIAS DE NÓS ---
@onready var animation_player: AnimationPlayer = $Pomni/AnimationPlayer
@onready var visual_model: Node3D = $Pomni



func _ready():
	z_inicial = global_position.z
	x_inicial = global_position.x
	safe_margin = 0.01
	floor_block_on_wall = false
	
	# Garante que a física padrão não interfira com nosso travamento manual
	axis_lock_linear_x = false
	axis_lock_linear_z = false
	
	# === LÓGICA DE CHECKPOINT E ITENS ===
	var global_node = get_node_or_null("/root/Global")
	if global_node and "pomni_tem_lanterna" in global_node:
		if global_node.pomni_tem_lanterna:
			tem_lanterna = true
			lanterna_ligada = true
			
			# Ativar o brilho corporal para ela não ficar preta no escuro
			ativar_brilho_corpo()
			
			# Renasce na Virada1 (EtapaParque) em vez do começo do jogo
			var cena_raiz = get_tree().current_scene
			if cena_raiz:
				var virada1 = cena_raiz.find_child("Virada1", true, false)
				if virada1:
					global_position = virada1.global_position
					# Atualiza posição inicial para evitar bugs de corrida
					z_inicial = global_position.z
					x_inicial = global_position.x
					
	# Oculta a arma da mão da Pomni por padrão (até ela pegar no baú)
	var pistola_visual = find_child("Pistol", true, false)
	if pistola_visual and not tem_arma:
		pistola_visual.visible = false
	
	# Busca a lanterna na mão da Pomni (adicionada pelo nosso script)
	var skeleton = find_child("Skeleton3D", true, false)
	if skeleton:
		ref_lanterna = skeleton.find_child("Lanterna", true, false)
		
		if ref_lanterna:
			lanterna_offset_pos = ref_lanterna.position
			ref_lanterna.top_level = true
			ref_spotlight = ref_lanterna.find_child("SpotLight3D", true, false)
			
			if not tem_lanterna:
				ref_lanterna.visible = false
			if ref_spotlight:
				ref_spotlight.visible = lanterna_ligada
				# Ajuste da lanterna: raio longo mas cone mais fechado e luz BEM intensa
				ref_spotlight.spot_range = 10
				ref_spotlight.spot_angle = 20
				ref_spotlight.light_energy = 15
				ref_spotlight.spot_attenuation = 0.5
				
				# Puxa a luz um pouquinho para trás para sair de dentro do modelo
				ref_spotlight.position.z -= 0
				
	# Configurar pivô da câmera e o sistema anti-colisão (RayCast3D)
	var cam = get_node_or_null("Camera3D")
	if cam:
		_camera_pivot = Node3D.new()
		_camera_pivot.name = "CameraPivot"
		add_child(_camera_pivot)
		
		# Salva a posição original e local da câmera
		var cam_local_transform = cam.transform
		_original_cam_pos = cam_local_transform.origin
		_target_cam_pos = _original_cam_pos
		
		# Reparenta a câmera
		cam.get_parent().remove_child(cam)
		_camera_pivot.add_child(cam)
		cam.transform = cam_local_transform
		
		# Cria um RayCast3D para detectar paredes
		_cam_ray = RayCast3D.new()
		_cam_ray.name = "CameraRay"
		_cam_ray.position = Vector3(0, 1.5, 0) # Raio sai do peito da Pomni
		_cam_ray.target_position = _original_cam_pos - _cam_ray.position
		
		# O RayCast só precisa bater no cenário (Layer 1). A Pomni está na Layer 2, então ele ignora ela!
		_cam_ray.collision_mask = 1
		
		_camera_pivot.add_child(_cam_ray)
	
	# Criar Interface de Vida visível via código usando Corações
	var canvas = CanvasLayer.new()
	canvas.name = "HealthCanvas"
	add_child(canvas)
	
	var hbox = HBoxContainer.new()
	hbox.position = Vector2(20, 20)
	hbox.add_theme_constant_override("separation", 10)
	canvas.add_child(hbox)
	
	var tex_vazio = load("res://Assets/UI/coração sem vida.png")
	var tex_cheio = load("res://Assets/UI/coração com vida.png")
	
	for i in range(qtd_coracoes):
		var tpb = TextureProgressBar.new()
		tpb.texture_under = tex_vazio
		tpb.texture_progress = tex_cheio
		tpb.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
		
		# Habilitar redimensionamento da textura (coração grande caber no cantinho da tela)
		tpb.nine_patch_stretch = true
		tpb.custom_minimum_size = Vector2(60, 60)
		
		tpb.max_value = vida_maxima / float(qtd_coracoes)
		tpb.value = tpb.max_value
		
		hbox.add_child(tpb)
		coracoes.append(tpb)

	# --- CRIAR PARTÍCULAS DE PASSOS (Ciano Fluorescente) ---
	particulas_passos = CPUParticles3D.new()
	particulas_passos.emitting = false
	particulas_passos.amount = 8 # Poucas partículas para ser suave
	particulas_passos.lifetime = 1.0
	particulas_passos.mesh = SphereMesh.new()
	particulas_passos.mesh.radius = 0.08
	particulas_passos.mesh.height = 0.16
	
	var mat_part = StandardMaterial3D.new()
	mat_part.albedo_color = Color(0.0, 1.0, 1.0, 0.7) # Ciano transparente
	mat_part.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_part.emission_enabled = true
	mat_part.emission = Color(0.0, 1.0, 1.0)
	mat_part.emission_energy_multiplier = 5.0 # Bem fluorescente e intenso
	particulas_passos.mesh.surface_set_material(0, mat_part)
	
	particulas_passos.direction = Vector3(0, 1, 0)
	particulas_passos.spread = 30.0
	particulas_passos.initial_velocity_min = 0.5
	particulas_passos.initial_velocity_max = 1.5
	particulas_passos.gravity = Vector3(0, 0.8, 0) # Sobem suavemente ao invés de cair
	
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0)) # Somem encolhendo
	particulas_passos.scale_amount_curve = curve
	
	# Posição nos pés da personagem
	particulas_passos.position = Vector3(0, -0.8, 0)
	add_child(particulas_passos)
	
	# --- SISTEMA DE TELEPORTE ENTRE PORTAS ---
	if has_node("/root/Global"):
		var global = get_node("/root/Global")
		if global.porta_destino_nome != "":
			var nome_porta = global.porta_destino_nome
			global.porta_destino_nome = "" # Reseta para não teleportar repetidamente
			
			# O get_tree().get_root() retorna a Window raiz, get_child(1) ou semelhante é a cena em si
			# find_child deve procurar em toda a árvore da cena
			var root = get_tree().get_root()
			var porta = root.find_child(nome_porta, true, false)
			if porta:
				# Teleporta a Pomni para a posição da porta + um deslocamento para a frente dela
				# Usa -Z da base global da porta normalizada para garantir que o 'Scale' da porta não empurre a Pomni mais longe do que o esperado
				global_position = porta.global_position + (porta.global_transform.basis.z.normalized() * 1.5)
				
				# Faz a Pomni olhar para as costas da porta (para frente, afastando-se dela)
				visual_model.global_rotation.y = porta.global_rotation.y
				
				# ATUALIZA AS TRAVAS PARA A NOVA POSICAO DO TELEPORTE!
				z_inicial = global_position.z
				x_inicial = global_position.x

	# Conecta os sinais das curvas do Parque de Diversões de forma automática
	call_deferred("_conectar_areas_parque")
	
	# Habilita a colisão do soco (Godot 4 exige que fique ativado para detectar)
	var hitbox = find_child("HitboxSoco", true, false)
	if hitbox:
		for child in hitbox.get_children():
			if child is CollisionShape3D:
				child.disabled = false
				
		# Reparenta para o modelo visual para que a hitbox de soco acompanhe a rotação visual!
		if hitbox.get_parent() != visual_model:
			var old_transform = hitbox.transform
			hitbox.get_parent().remove_child(hitbox)
			visual_model.add_child(hitbox)
			hitbox.transform = old_transform
			
	# Conecta gatilho da IdaFase2 (fim do Circo)
	call_deferred("_conectar_ida_fase_2")

func _process(delta: float) -> void:
	# Debug: Rotação manual da câmera com 'J' e 'K'
	if _camera_pivot:
		if Input.is_physical_key_pressed(KEY_J):
			_camera_pivot.rotation.y += 2.0 * delta
		elif Input.is_physical_key_pressed(KEY_K):
			_camera_pivot.rotation.y -= 2.0 * delta

	# Debug: Movimento lateral da câmera com 'M' (direita) e 'N' (esquerda)
	if _camera_pivot:
		var cam_debug = _camera_pivot.get_node_or_null("Camera3D")
		if cam_debug:
			var move_speed = 5.0 * delta
			# Pega o eixo X real da câmera (direita e esquerda na tela) ignorando o Y
			var right_dir = cam_debug.global_transform.basis.x
			right_dir.y = 0
			right_dir = right_dir.normalized()
			
			if Input.is_physical_key_pressed(KEY_M):
				_camera_pivot.global_position += right_dir * move_speed
			elif Input.is_physical_key_pressed(KEY_N):
				_camera_pivot.global_position -= right_dir * move_speed

	# Debug: Zoom da câmera com 'I' (afastar) e 'O' (aproximar)
	if _camera_pivot and _cam_ray:
		var zoom_speed = 5.0 * delta
		var dir = (_original_cam_pos - _cam_ray.position).normalized()
		var mudou_zoom = false
		if Input.is_physical_key_pressed(KEY_I):
			_original_cam_pos += dir * zoom_speed
			mudou_zoom = true
		elif Input.is_physical_key_pressed(KEY_O):
			if _original_cam_pos.distance_to(_cam_ray.position) > 1.0:
				_original_cam_pos -= dir * zoom_speed
				mudou_zoom = true
		
		if mudou_zoom:
			_cam_ray.target_position = _original_cam_pos - _cam_ray.position

	# A vida não regenera durante a Batalha Final contra o Boss!
	if regenerando and not em_batalha_final and vida < vida_maxima:
		vida += 3.0 * delta # Recuperação mais lenta (3 de vida por segundo)
		if vida > vida_maxima:
			vida = vida_maxima
			
	# Atualiza a interface dos corações
	if coracoes.size() > 0:
		var vida_por_coracao = vida_maxima / float(qtd_coracoes)
		var vida_restante = vida
		
		for tpb in coracoes:
			if vida_restante >= vida_por_coracao:
				tpb.value = vida_por_coracao
				vida_restante -= vida_por_coracao
			else:
				tpb.value = max(0, vida_restante)
				vida_restante = 0

	# Controle de piscar (Efeito de dano)
	if tempo_vermelho > 0:
		tempo_vermelho -= delta
		if tempo_vermelho <= 0:
			if na_agua:
				_aplicar_cor_agua_toxica()
			else:
				_remover_cor_agua_toxica()

	# Controle de emissão das partículas de passos
	if particulas_passos != null:
		var andando = abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1
		var no_chao = is_on_floor() or is_on_path
		particulas_passos.emitting = (andando and no_chao)

	# Lógica para tiro/soco contínuo
	if tempo_ultimo_ataque > 0:
		tempo_ultimo_ataque -= delta
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_physical_key_pressed(KEY_Z):
		if tempo_ultimo_ataque <= 0:
			socar()
			tempo_ultimo_ataque = 0.25 # 4 vezes por segundo

func _input(event: InputEvent) -> void:
	# Detecta o toque duplo para a direita
	if event.is_action_pressed("move_right"):
		var tempo_atual = Time.get_ticks_msec()
		if tempo_atual - ultimo_click_direita <= intervalo_double_tap:
			esta_correndo = true
		ultimo_click_direita = tempo_atual
		
	# Detecta o toque duplo para a esquerda
	if event.is_action_pressed("move_left"):
		var tempo_atual = Time.get_ticks_msec()
		if tempo_atual - ultimo_click_esquerda <= intervalo_double_tap:
			esta_correndo = true
		ultimo_click_esquerda = tempo_atual

	# Alternar lanterna (tecla F)
	if event is InputEventKey and event.physical_keycode == KEY_F and event.pressed and not event.echo:
		if tem_lanterna:
			lanterna_ligada = not lanterna_ligada
			if ref_spotlight:
				ref_spotlight.visible = lanterna_ligada
			print("Lanterna ligada: ", lanterna_ligada)
			

func socar() -> void:
	if em_batalha_final and tem_arma:
		print("Pomni atirou um projetil magico!")
		var cena_tiro = load("res://Cenas/TiroPomni.tscn")
		if cena_tiro:
			var tiro = cena_tiro.instantiate()
			get_tree().current_scene.add_child(tiro)
			# Posiciona na frente da Pomni
			tiro.global_position = global_position + Vector3(0, 1.2, 0)
			# Na batalha final, o tiro vai na direção onde o mouse aponta!
			var cam = get_viewport().get_camera_3d()
			if cam:
				var mouse_pos = get_viewport().get_mouse_position()
				# Projeta a posição do mouse a 20 metros de distância (logo à frente da Pomni)
				# Isso faz o tiro cruzar o ponteiro visualmente bem mais cedo!
				var alvo_3d = cam.project_position(mouse_pos, 20.0)
				tiro.direction = (alvo_3d - tiro.global_position).normalized()
			else:
				tiro.direction = Vector3(0, 0, -1)
	else:
		# 1. Aplica o Dano imediatamente a CADA CLIQUE, mesmo se a animação já estiver tocando
		print("Pomni desferiu um soco rápido!")
		var hitbox = find_child("HitboxSoco", true, false)
		if hitbox:
			var corpos = hitbox.get_overlapping_bodies()
			for body in corpos:
				if body.has_method("receber_dano") and body != self:
					body.receber_dano(25, global_position)
				
	# 2. Controle Visual da Animação
	if esta_socando:
		return # Se já está tocando, não reinicia a animação
		
	esta_socando = true
	var animacao_nome = "Atirar" if (em_batalha_final and tem_arma) else "Punch"
	var tempo_anim = 0.5
	var velocidade_anim = 2.5 # Acelerando a animação em 2.5x
	
	if animation_player:
		# Toca a animação com blend de 0.1s e custom_speed de 2.5x
		animation_player.play(animacao_nome, 0.1, velocidade_anim)
		if animation_player.has_animation(animacao_nome):
			# O tempo de espera será a duração original dividida pela nova velocidade
			tempo_anim = animation_player.get_animation(animacao_nome).length / velocidade_anim
				
	# Espera exatamente a duração real da animação acelerada
	await get_tree().create_timer(tempo_anim).timeout
	esta_socando = false


func equipar_lanterna() -> void:
	tem_lanterna = true
	lanterna_ligada = true
	if ref_lanterna:
		ref_lanterna.visible = true
	if ref_spotlight:
		ref_spotlight.visible = true
	print("Pomni equipou a lanterna!")
	
	# Salva globalmente para não perder ao trocar de cena
	if has_node("/root/Global"):
		var global_node = get_node("/root/Global")
		if "pomni_tem_lanterna" in global_node:
			global_node.pomni_tem_lanterna = true
	# Faz o próprio corpo da Pomni brilhar com as cores originais no escuro
	ativar_brilho_corpo()
	
	# Emitimos um sinal ou chamamos um Singleton pra escurecer o mundo
	if has_node("/root/Global"):
		if get_node("/root/Global").has_method("ativar_modo_escuro"):
			get_node("/root/Global").ativar_modo_escuro()

# ==========================================
# SISTEMA DE CURVA — Rotaciona apenas a câmera, nunca o CharacterBody3D
# ==========================================
func iniciar_curva(novo_angulo_y: float, duracao: float, angulo_camera_y: float = -999.0, centro_alvo: Vector3 = Vector3(INF, INF, INF), cam_offset: Vector3 = Vector3.ZERO):
	if fazendo_curva:
		return
	fazendo_curva = true
	
	if angulo_camera_y == -999.0:
		angulo_camera_y = novo_angulo_y
	
	# Desbloqueia os eixos manuais durante a curva para permitir a transição
	travar_eixo_x = false
	travar_eixo_z = false
	
	# Centraliza a Pomni no eixo perpendicular à NOVA direção para evitar que ela caia da beirada
	if centro_alvo.x != INF:
		var angulo_norm = fposmod(novo_angulo_y, TAU)
		var epsilon = 0.1
		var eh_z = abs(angulo_norm - PI/2) < epsilon or abs(angulo_norm - 3*PI/2) < epsilon
		var eh_x = abs(angulo_norm) < epsilon or abs(angulo_norm - PI) < epsilon or abs(angulo_norm - TAU) < epsilon
		
		if eh_z or eh_x:
			var tween_pos = create_tween()
			tween_pos.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) # Roda junto com a física
			
			# Se a nova direção for no eixo Z (90 graus ou 270/-90 graus), o eixo lateral é o X
			if eh_z:
				tween_pos.tween_property(self, "global_position:x", centro_alvo.x, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			# Se a nova direção for no eixo X (0 graus ou 180 graus), o eixo lateral é o Z
			elif eh_x:
				tween_pos.tween_property(self, "global_position:z", centro_alvo.z, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Calcula o caminho mais curto para o angulo_movimento
	var diff_mov = fposmod(novo_angulo_y - angulo_movimento + PI, TAU) - PI
	var angulo_mov_continuo = angulo_movimento + diff_mov
	
	# Atualiza o ângulo de movimento para a nova direção
	var tween_angulo = create_tween()
	tween_angulo.tween_property(self, "angulo_movimento", angulo_mov_continuo, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Rotaciona o pivô da câmera pelo caminho mais curto usando o ângulo da câmera
	if _camera_pivot:
		var diff_cam = fposmod(angulo_camera_y - _camera_pivot.rotation.y + PI, TAU) - PI
		var cam_alvo_continuo = _camera_pivot.rotation.y + diff_cam
		var tween_cam = create_tween()
		tween_cam.set_parallel(true)
		tween_cam.tween_property(_camera_pivot, "rotation:y", cam_alvo_continuo, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Anima o offset da câmera (para aproximar/afastar ou deslocar lateralmente)
		var pos_alvo = _original_cam_pos + cam_offset
		tween_cam.tween_property(self, "_target_cam_pos", pos_alvo, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Rotaciona o modelo visual pelo caminho mais curto (usa o angulo_mov_continuo para acompanhar o movimento)
	var tween_visual = create_tween()
	var angulo_visual_alvo = novo_angulo_y + PI/2
	var diff_vis = fposmod(angulo_visual_alvo - visual_model.global_rotation.y + PI, TAU) - PI
	var vis_alvo_continuo = visual_model.global_rotation.y + diff_vis
	tween_visual.tween_property(visual_model, "global_rotation:y", vis_alvo_continuo, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Passa o novo ângulo para o callback atualizar as travas de eixo
	tween_visual.tween_callback(func(): _finalizar_curva(angulo_mov_continuo))

func _finalizar_curva(angulo_final: float):
	fazendo_curva = false
	
	if usar_linha_pendente:
		linha_inicio = linha_inicio_pendente
		linha_fim = linha_fim_pendente
		travar_na_linha = true
		usar_linha_pendente = false
		travar_eixo_x = false
		travar_eixo_z = false
	else:
		travar_na_linha = false
		var angulo_norm = fposmod(angulo_final, TAU)
		var epsilon = 0.1
		
		if abs(angulo_norm - PI/2) < epsilon or abs(angulo_norm - 3*PI/2) < epsilon:
			travar_eixo_x = true
			travar_eixo_z = false
			x_inicial = global_position.x
		elif abs(angulo_norm) < epsilon or abs(angulo_norm - PI) < epsilon or abs(angulo_norm - TAU) < epsilon:
			travar_eixo_x = false
			travar_eixo_z = true
			z_inicial = global_position.z
		else:
			travar_eixo_x = false
			travar_eixo_z = false

func _physics_process(delta: float) -> void:
	if is_on_path and trilho_atual != null:
		handle_path_movement(delta)
	elif is_climbing:
		handle_climbing(delta)
	else:
		apply_gravity(delta)
		handle_jump()
		handle_movement(delta)
		move_and_slide()
		
		# Aplica o travamento na linha se ativado pelo Parque
		if travar_na_linha and not fazendo_curva:
			var pos2d = Vector2(global_position.x, global_position.z)
			var a = linha_inicio
			var b = linha_fim
			var ab = b - a
			if ab.length_squared() > 0.001:
				var ap = pos2d - a
				var t = ap.dot(ab) / ab.length_squared()
				var proj = a + ab * t
				global_position.x = proj.x
				global_position.z = proj.y
		# Senão, aplica o travamento de eixo original
		else:
			if travar_eixo_z and not fazendo_curva:
				global_position.z = z_inicial
			if travar_eixo_x and not fazendo_curva:
				global_position.x = x_inicial
	# Faz a lanterna sempre apontar para frente da Pomni, independente da animação da mão
	if ref_lanterna and tem_lanterna:
		var mao = ref_lanterna.get_parent()
		if mao:
			# Direção para frente baseada no modelo visual (Pomni)
			# Como a lanterna estava apontando para trás, invertemos o sinal do Z
			var frente = visual_model.global_transform.basis.z.normalized()
			
			# Anula a inclinação vertical para a luz ficar reta
			frente.y = 0 
			frente = frente.normalized()
			
			# Ajuste manual da posição da lanterna para ficar na mão
			# A posição da 'mao' já está na direita, então o offset_direita pode ser quase zero.
			var dir_direita = -visual_model.global_transform.basis.x.normalized()
			var offset_direita = -0.3
			var offset_baixo = -0.12
			var offset_frente = 0.08
			
			# Ajuste manual da ROTAÇÃO da malha da lanterna (em graus)
			# Modifique esses valores até o modelo 3D ficar perfeito na mão!
			var rotacao_x_graus = 0
			var rotacao_y_graus = 210
			var rotacao_z_graus = 0
			
			ref_lanterna.global_position = mao.global_position + (dir_direita * offset_direita) + (Vector3.UP * offset_baixo) + (frente * offset_frente)
			
			# Aponta a lanterna
			if frente.length() > 0.1:
				# 1. Apontamos o padrão do Godot para frente
				ref_lanterna.look_at(ref_lanterna.global_position + frente, Vector3.UP)
				
				# 2. Rotação fina manual
				ref_lanterna.rotate_object_local(Vector3.RIGHT, deg_to_rad(rotacao_x_graus))
				ref_lanterna.rotate_object_local(Vector3.UP, deg_to_rad(rotacao_y_graus))
				ref_lanterna.rotate_object_local(Vector3.FORWARD, deg_to_rad(rotacao_z_graus))
				
				# Força a luz (SpotLight3D) a apontar para a frente da Pomni!
				if ref_spotlight:
					# Se a luz estava batendo na parede atrás, "+ frente" vai jogar o raio 
					# exatamente 180 graus pro outro lado (pra frente da Pomni)!
					ref_spotlight.look_at(ref_spotlight.global_position + frente, Vector3.UP)
					
					# Inclina a lanterna um pouco para baixo para a luz bater no chão mais perto dela!
					ref_spotlight.rotate_object_local(Vector3.RIGHT, deg_to_rad(-8.0))
			
	update_animations()

	# Anti-clipping customizado da câmera
	if _camera_pivot and _cam_ray:
		var cam = _camera_pivot.get_node_or_null("Camera3D")
		if cam:
			_cam_ray.target_position = _target_cam_pos - _cam_ray.position
			_cam_ray.force_raycast_update()
			if _cam_ray.is_colliding():
				cam.global_position = _cam_ray.get_collision_point() + _cam_ray.get_collision_normal() * 0.25
			else:
				cam.position = _target_cam_pos

	# ===== TRAVAMENTO CUPHEAD (BATALHA FINAL INTEGRADA) =====
	if em_batalha_final:
		# A câmera fica totalmente estática e top_level (nós ativamos isso no iniciar_batalha_final)
		# Limites simples baseados na posição X (Esquerda/Direita na tela):
		# A Pomni agora caminha pelo eixo X.
		if global_position.x < posicao_x_min:
			global_position.x = posicao_x_min
		if global_position.x > posicao_x_max:
			global_position.x = posicao_x_max
			
		# E garante que o Z (profundidade em relação à câmera) não fuja NUNCA
		global_position.z = posicao_z_congelada
		velocity.z = 0
		
		# Força a Pomni a olhar para o Boss (fundo, eixo -Z) no idle, e pros lados quando corre
		if visual_model:
			var target_rot = PI/2 # Idle = Boss
			var input_axis = Input.get_axis("move_left", "move_right")
			if input_axis > 0.1:
				target_rot = 0 # Direita
			elif input_axis < -0.1:
				target_rot = PI # Esquerda
			visual_model.rotation.y = lerp_angle(visual_model.rotation.y, target_rot, 12 * delta)
		
		return


func handle_climbing(_delta: float) -> void:
	# Reseta as velocidades horizontais para ela não escorregar
	velocity.x = 0
	velocity.z = 0
	
	# Entrada de Cima e Baixo para subir e descer a escada
	var climb_dir = Input.get_axis("move_down", "move_up")
	
	if escada_atual:
		var shape = null
		for child in escada_atual.get_children():
			if child is CollisionShape3D:
				shape = child
				break
				
		if shape and shape.shape is BoxShape3D:
			# Limita a subida até o topo do CollisionShape3D
			var max_y = shape.global_position.y + (shape.shape.size.y / 2.0) - 0.5
			if global_position.y >= max_y and climb_dir > 0:
				climb_dir = 0
				
	velocity.y = climb_dir * speed
	
	move_and_slide()
	
	# Se bater no chão ao descer, solta a escada (colisão natural restaurada!)
	if is_on_floor() and climb_dir < 0:
		sair_da_escada()
	
	if climb_dir != 0:
		if animation_player.current_animation != "ClimbingDown":
			animation_player.play("ClimbingDown", 0.2)
		elif not animation_player.is_playing():
			animation_player.play()
	else:
		if animation_player.current_animation == "ClimbingDown":
			animation_player.pause()

func entrar_na_escada(escada: Area3D) -> void:
	if is_on_path:
		escada_pendente = escada
		return
		
	is_climbing = true
	escada_atual = escada
	velocity = Vector3.ZERO
	
	# Centraliza a Pomni exatamente no CollisionShape3D da escada
	var shape = null
	for child in escada.get_children():
		if child is CollisionShape3D:
			shape = child
			break
	if shape:
		global_position.x = shape.global_position.x
		global_position.z = shape.global_position.z
		
	# Rotaciona o modelo visual em 180 graus
	if visual_model:
		visual_model.rotation.y += PI - 1
		visual_model.rotation.x -= 0.5 
		visual_model.position.z -= 0.5
	# Desativa travamento de linha ao escalar
	travar_na_linha = false
		
	print("Pomni começou a escalar a escada!")

func sair_da_escada() -> void:
	if is_on_path:
		escada_pendente = null
		return
		
	is_climbing = false
	escada_atual = null
	
	# Retorna as propriedades modificadas para o padrão
	if visual_model:
		visual_model.rotation.x += 0.5
		visual_model.position.z += 0.5
		
	# Atualiza a trava no ponto exato onde soltou a escada
	travar_na_linha = false
	
	print("Pomni soltou a escada!")

func apply_gravity(delta: float) -> void:
	if na_agua:
		# Lógica de Flutuação (Empuxo)
		var profundidade = altura_agua - global_position.y
		# Queremos que ela afunde até 1.2 metros (mais ou menos o peito/pescoço)
		var profundidade_alvo = 1.2
		var empuxo = (profundidade - profundidade_alvo) * 20.0
		
		velocity.y += empuxo * delta
		# Amortecimento da água (arrasto vertical)
		velocity.y = lerp(velocity.y, 0.0, 5.0 * delta)
	elif not is_on_floor():
		velocity.y -= gravity * delta

func entrar_na_agua(y_superficie: float):
	na_agua = true
	altura_agua = y_superficie
	_aplicar_cor_agua_toxica()

func sair_da_agua():
	na_agua = false
	_remover_cor_agua_toxica()

func _aplicar_cor_agua_toxica() -> void:
	var meshes = []
	if visual_model:
		_buscar_meshes(visual_model, meshes)
		
	var toxic_mat = StandardMaterial3D.new()
	toxic_mat.albedo_color = Color(0.2, 0.9, 0.2, 0.5)
	toxic_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	toxic_mat.emission_enabled = true
	toxic_mat.emission = Color(0.2, 0.9, 0.2)
	toxic_mat.emission_energy_multiplier = 2.0
	
	for mesh in meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = toxic_mat

func _remover_cor_agua_toxica() -> void:
	var meshes = []
	if visual_model:
		_buscar_meshes(visual_model, meshes)
	for mesh in meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = null

func handle_jump() -> void:
	if is_on_floor() or na_agua:
		pulos_dados = 0
	elif pulos_dados == 0:
		pulos_dados = 1 # Gastar o primeiro pulo se cair de uma borda
		
	if Input.is_action_just_pressed("move_up") and pulos_dados < max_pulos:
		# Pulo na água é mais fraco
		if na_agua:
			velocity.y = jump_velocity * 0.7
		else:
			velocity.y = jump_velocity
		pulos_dados += 1
		
		# Reinicia a animação se for o segundo pulo (e não estiver nadando)
		if pulos_dados > 1 and not na_agua:
			animation_player.stop()
			animation_player.play("Jumping", 0.1)

func handle_movement(delta: float) -> void:
	var input_axis := Input.get_axis("move_left", "move_right")
	
	if Input.is_physical_key_pressed(KEY_SHIFT):
		esta_correndo = true
	
	if input_axis == 0:
		esta_correndo = false
	
	var current_speed = run_speed if esta_correndo else speed
	
	# Se estiver na água, fica lento e nadando com arrasto
	if na_agua:
		current_speed *= 0.5
	
	# Calcula a direção de movimento baseada no ângulo armazenado
	var input_dir: Vector2
	input_dir.x = input_axis
	
	var direction = Vector3(input_dir.x, 0, 0)
	direction = direction.rotated(Vector3.UP, angulo_movimento)
	
	if direction:
		# Na água, ela acelera e desacelera com mais inércia (arrasto do fluido)
		var accel = 2.0 if na_agua else 10.0
		velocity.x = move_toward(velocity.x, direction.x * current_speed, accel * current_speed * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, accel * current_speed * delta)
		
		# Rotação visual do modelo baseada na direção de input + ângulo da curva (absoluto/global)
		if not em_batalha_final:
			var rotacao_alvo = angulo_movimento + PI/2
			if input_axis == -1:
				rotacao_alvo = angulo_movimento - PI/2
			visual_model.global_rotation.y = lerp_angle(visual_model.global_rotation.y, rotacao_alvo, 8 * delta)
	else:
		# Desaceleração mais suave na água (flutuando/derrapando levemente no líquido)
		var deccel = 2.0 if na_agua else 10.0
		velocity.x = move_toward(velocity.x, 0, deccel * current_speed * delta)
		velocity.z = move_toward(velocity.z, 0, deccel * current_speed * delta)

func handle_path_movement(delta: float) -> void:
	if esperando_decisao:
		velocity.x = 0
		velocity.y = 0
		return
		
	var direction := Input.get_axis("move_left", "move_right")
	
	if Input.is_physical_key_pressed(KEY_SHIFT):
		esta_correndo = true
	if direction == 0:
		esta_correndo = false
		
	var current_speed = run_speed if esta_correndo else speed
	
	if direction != 0:
		trilho_atual.progress += direction * current_speed * delta
		
		# Se tentar ir além do início (0.0), bloqueie o movimento
		if trilho_atual.progress_ratio <= 0.01 and direction < 0:
			trilho_atual.progress_ratio = 0.0
			velocity.x = 0
			
		# Se chegar no fim do caminho (0.99+), FORCE a saída do caminho
		elif trilho_atual.progress_ratio >= 0.99 and direction > 0:
			var parent_name = str(trilho_atual.get_parent().name) if trilho_atual.get_parent() else ""
			if "Errado" in parent_name:
				trilho_atual.progress_ratio = 0.99
				velocity.x = 0
			else:
				sair_do_caminho()
				return
		else:
			# Rotação visual enquanto anda no caminho
			var scene_name = str(get_tree().current_scene.name) if get_tree().current_scene else ""
			var is_perseguicao = "Perseguicao" in scene_name
			var is_EscritorioCaim = "Caine" in scene_name
					
			var rotacao_caminho = trilho_atual.global_rotation.y
			
			# Por padrão, todas as outras cenas do jogo usam o offset de -1
			var rotacao_alvo = rotacao_caminho - PI - 1
			
			# Na Perseguição, ela deve ficar retinha
			if is_perseguicao:
				rotacao_alvo = rotacao_caminho + PI/2
				
			if is_EscritorioCaim:
				rotacao_alvo = rotacao_caminho + PI/2
				
			if direction == -1:
				rotacao_alvo = rotacao_alvo - PI
			visual_model.rotation.y = lerp_angle(visual_model.rotation.y, rotacao_alvo, 8 * delta)
	
	# Só atualiza a posição se ela ainda estiver no caminho
	if is_on_path and trilho_atual != null:
		global_position = trilho_atual.global_position
		velocity.x = direction * current_speed
		velocity.y = 0.0
		
		# NOVO: Mantém a câmera sempre atrás da Pomni enquanto ela estiver no caminho (visão em 3ª pessoa)
		if _camera_pivot:
			var scene_name = str(get_tree().current_scene.name) if get_tree().current_scene else ""
			var is_perseguicao = "Perseguicao" in scene_name
			
			var is_parque = false
			if trilho_atual.get_parent() and "Parque" in trilho_atual.get_parent().name:
				is_parque = true
				
			# Roda a câmera APENAS no Parque ou na Perseguição!
			if is_parque:
				_camera_pivot.rotation.y = lerp_angle(_camera_pivot.rotation.y, visual_model.rotation.y + PI + 1, 4.0 * delta)
			elif is_perseguicao:
				_camera_pivot.rotation.y = lerp_angle(_camera_pivot.rotation.y, visual_model.rotation.y, 10.0 * delta)
			else:
				_camera_pivot.rotation.y = lerp_angle(_camera_pivot.rotation.y, visual_model.rotation.y - PI/2, 4.0 * delta)

func update_animations() -> void:
	if esta_socando or is_climbing:
		return
		
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() and not is_on_path:
		if velocity.y > 0.0:
			if animation_player.current_animation != "Jumping":
				animation_player.play("Jumping", 0.3)
		else:
			if animation_player.current_animation != "Falling":
				animation_player.play("Falling", 0.7)
	elif horizontal_speed > 0.1:
		if esta_correndo:
			if animation_player.current_animation != "Run":
				animation_player.play("Run", 0.2)
		else:
			if animation_player.current_animation != "Walk":
				animation_player.play("Walk", 0.2)
	else:
		if animation_player.current_animation != "Idle":
			animation_player.play("Idle", 0.3)

# ==========================================
# GATILHOS DE ENTRADA E SAÍDA (API EXTERNA)
# ==========================================
func entrar_no_caminho(carrinho: PathFollow3D) -> void:
	is_on_path = true
	trilho_atual = carrinho
	trilho_atual.loop = false # Garante que o caminho não é infinito
	# Anula as velocidades acumuladas para ela não escorregar
	velocity = Vector3.ZERO 
	
	# FORÇA A POMNI A MOVER IMEDIATAMENTE PARA O CARRINHO
	if trilho_atual != null:
		global_position = trilho_atual.global_position

func sair_do_caminho() -> void:
	is_on_path = false
	trilho_atual = null
	
	# Atualiza a posição inicial para que ela assuma a nova profundidade onde o trilho terminou
	z_inicial = global_position.z
	x_inicial = global_position.x
	
	if escada_pendente != null:
		var escada_temp = escada_pendente
		escada_pendente = null
		entrar_na_escada(escada_temp)
		
	# Mudar o ângulo da câmera ao sair de um tubo baseado na Cena atual
	var scene_name = str(get_tree().current_scene.name) if get_tree().current_scene else ""
	if "Caine" in scene_name:
		# Quando sai do tubo (CaminhoCorredor) no escritório do Caine, 
		# rotaciona a câmera para a visão Side-Scroller
		var angulo_mov = 0.0 # Define a linha de movimento (horizontal)
		var duracao_suave = 0.3 # 1 segundo para a câmera fazer a transição
		var angulo_cam = deg_to_rad(-90) # 180 graus (ou 0, 90, -90, ajuste conforme ficar melhor visualmente!)
		iniciar_curva(angulo_mov, duracao_suave, angulo_cam)

func receber_dano(quantidade: float, origem: Vector3 = Vector3.ZERO, aplicar_knockback: bool = true) -> void:
	vida -= abs(quantidade) # Garante que a vida seja subtraída
	print("Pomni recebeu dano! Vida atual: ", int(vida))
	
	if aplicar_knockback:
		# Efeito de Knockback corrigido (Horizontal)
		if origem != Vector3.ZERO:
			var dir = (global_position - origem)
			dir.y = 0 # Ignora a altura para não jogar pro alto
			
			if dir.length_squared() < 0.001:
				dir = -visual_model.global_transform.basis.z.normalized()
			else:
				dir = dir.normalized()
				
			velocity.x = dir.x * 15.0
			velocity.z = dir.z * 15.0
			velocity.y = 3.0 # Apenas um pequeno pulo, não a força principal
		else:
			# Knockback genérico (Morcego)
			var backward = -visual_model.global_transform.basis.z.normalized()
			velocity.x = backward.x * 15.0
			velocity.z = backward.z * 15.0
			velocity.y = 3.0
		
	# Efeito visual de Dano (Piscar Vermelho ou Branco se já estiver na água)
	var meshes = []
	if visual_model:
		_buscar_meshes(visual_model, meshes)
		
	var damage_mat = StandardMaterial3D.new()
	damage_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	damage_mat.emission_enabled = true
	damage_mat.emission_energy_multiplier = 4.0
	
	# O flash de dano é sempre vermelho intenso para ficar bem visível
	damage_mat.albedo_color = Color(1, 0, 0, 0.8)
	damage_mat.emission = Color(1, 0, 0)
	
	for mesh in meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = damage_mat
			
	tempo_vermelho = 0.3
		
	if vida <= 0:
		print("Pomni morreu!")
		var hc = get_node_or_null("HealthCanvas")
		if hc:
			hc.visible = false
		var game_over_scene = load("res://Cenarios/GameOver.tscn")
		if game_over_scene:
			var game_over_instance = game_over_scene.instantiate()
			get_tree().get_root().add_child(game_over_instance)
			get_tree().paused = true

func ativar_brilho_corpo() -> void:
	if has_node("LuzPessoalPomni_0"):
		return
		
	var posicoes_luzes = [
		Vector3(-1.0, 2.5, 2.0),  # Luz Principal (Alta, na frente e na esquerda) - Cria sombras do lado direito e embaixo do pescoço
		Vector3(1.0, 1.0, -2.0)   # Luz de Recorte (Baixa, nas costas e na direita) - Bem fraca, só pra dar silhueta
	]
	
	for i in range(posicoes_luzes.size()):
		var luz_pessoal = OmniLight3D.new()
		luz_pessoal.name = "LuzPessoalPomni_" + str(i)
		luz_pessoal.light_color = Color(1, 1, 1)
		
		# A luz da frente tem energia 0.35, a das costas tem energia 0.15
		luz_pessoal.light_energy = 0.35 if i == 0 else 0.15 
		
		luz_pessoal.omni_range = 5.0
		
		# Camada 20 (524288 em bits). A luz SÓ vai bater em quem estiver na camada 20.
		luz_pessoal.light_cull_mask = 524288 
		
		add_child(luz_pessoal)
		luz_pessoal.position = posicoes_luzes[i]
	
	var meshes = []
	if visual_model:
		_buscar_meshes(visual_model, meshes)
		
	for mesh_node in meshes:
		# Colocamos a Pomni na camada 1 (normal) + camada 20 (luz pessoal) = 524289
		mesh_node.layers = 524289

func _buscar_meshes(node: Node, lista: Array) -> void:
	if node is MeshInstance3D:
		lista.append(node)
	for child in node.get_children():
		_buscar_meshes(child, lista)

# ==========================================
# LÓGICA DO ETAPA PARQUE (CURVAS E CAMINHOS)
# ==========================================
var _viradas_feitas: Array = []

func _conectar_areas_parque() -> void:
	var cena_raiz = get_tree().get_root()
	var etapa_parque = cena_raiz.find_child("EtapaParque", true, false)
	
	if etapa_parque:
		# Conecta as 7 viradas
		for i in range(1, 8):
			var area_virada = etapa_parque.find_child("Virada" + str(i), true, false)
			if area_virada and area_virada is Area3D:
				area_virada.body_entered.connect(_on_virada_parque_entered.bind(i, area_virada))
				
		# Conecta a área final do CaminhoCirco
		var caminho_circo = etapa_parque.find_child("CaminhoCirco", true, false)
		if caminho_circo:
			var area_final = caminho_circo.find_child("Area3d", true, false)
			if area_final and area_final is Area3D:
				area_final.body_entered.connect(_on_area_caminho_circo_entered)


func _on_virada_parque_entered(body: Node3D, index: int, area: Area3D) -> void:
	if body != self:
		return
	if index in _viradas_feitas:
		return
		
	_viradas_feitas.append(index)
	
	# Em vez de somar exatamente 90 graus (o que falha se o cenário for diagonal),
	# vamos calcular o ângulo exato apontando direto para a PRÓXIMA área!
	var cena_raiz = get_tree().get_root()
	var proxima_area: Node3D = null
	
	if index < 7:
		proxima_area = cena_raiz.find_child("Virada" + str(index + 1), true, false)
	else:
		proxima_area = cena_raiz.find_child("Area3d", true, false) # Fim do percurso
		
	var novo_angulo = angulo_movimento
	
	if proxima_area:
		var dir = proxima_area.global_position - area.global_position
		dir.y = 0 # Ignora a altura
		if dir.length() > 0.1:
			# atan2(-Z, X) nos dá o ângulo exato da Godot no eixo Y
			novo_angulo = atan2(-dir.z, dir.x)
	
	print("Pomni entrou na Virada ", index, ". Apontando exatamente para a próxima área!")
	
	# Busca o centro exato da colisão (CollisionShape3D) para alinhar a Pomni,
	# evitando que ela seja jogada para o lado se a Area3D estiver descentralizada.
	var alvo_pos = Vector3(INF, INF, INF)
	for child in area.get_children():
		if child is CollisionShape3D:
			alvo_pos = child.global_position
			break
			
	# Lógica Customizada de Câmera e Offset baseada no pedido
	var angulo_cam = novo_angulo - PI/2 # Padrão: 3ª pessoa nas costas
	var cam_offset = Vector3.ZERO
	
	if index in [1, 2, 6]:
		# Visão terceira pessoa (nas costas)
		angulo_cam = novo_angulo - PI/2
		cam_offset = Vector3.ZERO
	elif index == 3:
		# Deslocada para esquerda e um pouco de zoom out
		angulo_cam = novo_angulo + PI + 0.3
		cam_offset = Vector3(-2, 0, -4) # X negativo = esquerda, Z positivo = zoom out
		
	elif index == 4:
		# Rotacionada 90 graus (side-scroller)
		angulo_cam = novo_angulo # Fica de lado
		cam_offset = Vector3(2, 0, 4) # Mais para cima (Y positivo) e mais zoom out (Z maior)
	elif index == 5:
		# Deslocada para a direita e zoom out
		angulo_cam = novo_angulo + 0.1 # Volta para as costas, mas deslocada
		cam_offset = Vector3(1, 0, 1) # X positivo = direita
		
	# Define a linha pendente que será ativada ao fim da curva
	if proxima_area:
		var proxima_pos = proxima_area.global_position
		for child in proxima_area.get_children():
			if child is CollisionShape3D:
				proxima_pos = child.global_position
				break
				
		linha_inicio_pendente = Vector2(alvo_pos.x, alvo_pos.z)
		linha_fim_pendente = Vector2(proxima_pos.x, proxima_pos.z)
		usar_linha_pendente = true
	else:
		usar_linha_pendente = false
		
	iniciar_curva(novo_angulo, 0.4, angulo_cam, alvo_pos, cam_offset)

func _on_area_caminho_circo_entered(body: Node3D) -> void:
	if body != self:
		return
	if is_on_path:
		return
		
	var cena_raiz = get_tree().get_root()
	var etapa_parque = cena_raiz.find_child("EtapaParque", true, false)
	if etapa_parque:
		var caminho_circo = etapa_parque.find_child("CaminhoCirco", true, false)
		if caminho_circo:
			var path_follow = caminho_circo.find_child("PathFollow3D", true, false)
			if path_follow:
				print("Pomni entrou no CaminhoCirco!")
				entrar_no_caminho(path_follow)

func _conectar_ida_fase_2() -> void:
	var cena_raiz = get_tree().get_root()
	var circo_node = cena_raiz.find_child("Circo", true, false)
	if circo_node:
		var ida_fase2 = circo_node.find_child("IdaFase2", true, false)
		if ida_fase2 and ida_fase2 is Area3D:
			ida_fase2.body_entered.connect(_on_ida_fase_2_entered)

func _on_ida_fase_2_entered(body: Node3D) -> void:
	if body != self:
		return
		
	print("Pomni entrou na IdaFase2! Abrindo a tela final...")
	
	var script_tela = load("res://Codigos/tela_fim_fase.gd")
	if script_tela:
		var tela = script_tela.new()
		get_tree().get_root().add_child(tela)
		
	# Pausa o jogo
	get_tree().paused = true

func iniciar_batalha_final() -> void:
	em_batalha_final = true
	print("Pomni entrou no modo Batalha Final (Cuphead)!")
	
	# Destrava o mouse obrigatoriamente para poder mirar
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if _camera_pivot:
		# Solta a câmera do corpo da Pomni para ela não andar junto
		_camera_pivot.set_as_top_level(true)
		
		# Define a posição da câmera travada (Afastada no eixo Z e Y para não bugar nos móveis)
		_camera_pivot.global_position = global_position + Vector3(0, 2.5, 2)
		
		# O pivot vira 90 graus para anular a rotação local bizarra da Camera3D filha, fazendo ela apontar reto pro -Z! 
		_camera_pivot.rotation = Vector3(0, PI/2, 0)
		
	# Trava as bordas do corredor no eixo X (Esquerda e Direita da tela)
	# Área lateral aumentada (de 7.0 para 14.0 metros para cada lado)
	posicao_x_min = global_position.x - 14.0
	posicao_x_max = global_position.x + 14.0
	posicao_z_congelada = global_position.z
	
	# Move a Pomni no eixo X (Esquerda/Direita)
	angulo_movimento = 0.0
	
	# Desliga as travas antigas de cena 2.5D para o nosso código fluir solto!
	travar_eixo_x = false
	travar_eixo_z = false
	travar_na_linha = false
	
	# Força a malha a olhar para frente (-Z, onde o boss vai estar)
	if visual_model:
		visual_model.rotation.y = 0
		
	# Trava as bordas do corredor no eixo X (Esquerda e Direita) pelas BORDAS DA CÂMERA!
	# Aguardamos 1 frame para garantir que a câmera assumiu a posição global
	await get_tree().process_frame
	if _camera_pivot:
		var cam = _camera_pivot.get_node_or_null("Camera3D")
		if cam:
			var viewport_size = get_viewport().get_visible_rect().size
			var distancia = abs(cam.global_position.z - posicao_z_congelada)
			
			# Pega a posição 3D do canto esquerdo e direito da tela, na exata profundidade da Pomni
			var limite_esq = cam.project_position(Vector2(0, viewport_size.y / 2.0), distancia)
			var limite_dir = cam.project_position(Vector2(viewport_size.x, viewport_size.y / 2.0), distancia)
			
			# Adiciona 0.5 de margem para o modelo 3D não vazar metade pra fora da tela
			var margem = 0.5
			posicao_x_min = min(limite_esq.x, limite_dir.x) + margem
			posicao_x_max = max(limite_esq.x, limite_dir.x) - margem
		else:
			posicao_x_min = global_position.x - 14.0
			posicao_x_max = global_position.x + 14.0

func finalizar_batalha_final() -> void:
	em_batalha_final = false
	print("Pomni saiu do modo Batalha Final!")
	
	# Retorna o mouse para o estado padrão (se ele era capturado)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if _camera_pivot:
		# Devolve a câmera para ser filha do CharacterBody3D, seguindo a Pomni
		_camera_pivot.set_as_top_level(false)
		_camera_pivot.position = Vector3.ZERO
		
	# Rotaciona 90 graus para a direita para voltar à visão em terceira pessoa do corredor
	# O ângulo de movimento continua 0.0 (para ela correr ao longo do corredor),
	# mas passamos -PI/2 como terceiro argumento para girar a câmera e ela olhar para a profundidade do corredor.
	iniciar_curva(0.0, 1.0, -PI/2)
