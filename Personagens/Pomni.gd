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

var z_inicial
var esta_correndo: bool = false

# Variáveis para controle do tempo no double-tap
var ultimo_click_esquerda: int = 0
var ultimo_click_direita: int = 0
var intervalo_double_tap: int = 300 # Tempo máximo em milissegundos entre os toques

# --- VARIÁVEIS DO CAMINHO ---
var is_on_path: bool = false
var trilho_atual: PathFollow3D = null # Guarda o carrinho que a Pomni está usando no momento

# Gravidade
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- SISTEMA DE CURVA (Desacoplado da física) ---
var angulo_movimento: float = 0.0  # Ângulo atual de movimento em radianos
var fazendo_curva: bool = false

# Pivô da câmera — criado em _ready() para orbitar sem rotacionar o CharacterBody3D
var _camera_pivot: Node3D = null
var _original_cam_pos: Vector3
var _cam_ray: RayCast3D

# --- VARIÁVEIS DA ÁGUA ---
var na_agua: bool = false
var altura_agua: float = 0.0

# --- REFERÊNCIAS DE NÓS ---
@onready var animation_player: AnimationPlayer = $Pomni/AnimationPlayer
@onready var visual_model: Node3D = $Pomni



func _ready():
	z_inicial = global_position.z
	safe_margin = 0.01
	floor_block_on_wall = false
	
	# Configurar pivô da câmera e o sistema anti-colisão (RayCast3D)
	var cam = get_node_or_null("Camera3D")
	if cam:
		_camera_pivot = Node3D.new()
		_camera_pivot.name = "CameraPivot"
		add_child(_camera_pivot)
		
		# Salva a posição original e local da câmera
		var cam_local_transform = cam.transform
		_original_cam_pos = cam_local_transform.origin
		
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

func _process(delta: float) -> void:
	if regenerando and vida < vida_maxima:
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

	# Controle de emissão das partículas de passos
	if particulas_passos != null:
		var andando = abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1
		var no_chao = is_on_floor() or is_on_path
		particulas_passos.emitting = (andando and no_chao)

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

# ==========================================
# SISTEMA DE CURVA — Rotaciona apenas a câmera, nunca o CharacterBody3D
# ==========================================
func iniciar_curva(novo_angulo_y: float, duracao: float, angulo_camera_y: float = -999.0, centro_alvo: Vector3 = Vector3(INF, INF, INF)):
	if fazendo_curva:
		return
	fazendo_curva = true
	
	if angulo_camera_y == -999.0:
		angulo_camera_y = novo_angulo_y
	
	# Desbloqueia os eixos durante a curva para evitar bugs de transição
	axis_lock_linear_x = false
	axis_lock_linear_z = false
	
	# Centraliza a Pomni no eixo perpendicular à NOVA direção para evitar que ela caia da beirada
	if centro_alvo.x != INF:
		var angulo_norm = fposmod(novo_angulo_y, TAU)
		var epsilon = 0.1
		var tween_pos = create_tween()
		tween_pos.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) # Roda junto com a física
		
		# Se a nova direção for no eixo Z (90 graus ou 270/-90 graus), o eixo lateral é o X
		if abs(angulo_norm - PI/2) < epsilon or abs(angulo_norm - 3*PI/2) < epsilon:
			tween_pos.tween_property(self, "global_position:x", centro_alvo.x, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Se a nova direção for no eixo X (0 graus ou 180 graus), o eixo lateral é o Z
		elif abs(angulo_norm) < epsilon or abs(angulo_norm - PI) < epsilon or abs(angulo_norm - TAU) < epsilon:
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
		tween_cam.tween_property(_camera_pivot, "rotation:y", cam_alvo_continuo, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
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
	
	# Normaliza o ângulo (ajusta para ficar entre 0 e 2*PI)
	var angulo_norm = fposmod(angulo_final, TAU)
	
	# Define a tolerância para checar o ângulo
	var epsilon = 0.1
	
	# Se estiver movendo no eixo Z (90 graus ou 270/-90 graus)
	if abs(angulo_norm - PI/2) < epsilon or abs(angulo_norm - 3*PI/2) < epsilon:
		axis_lock_linear_x = true
		axis_lock_linear_z = false
	# Se estiver movendo no eixo X (0 graus ou 180 graus)
	elif abs(angulo_norm) < epsilon or abs(angulo_norm - PI) < epsilon or abs(angulo_norm - TAU) < epsilon:
		axis_lock_linear_x = false
		axis_lock_linear_z = true
	else:
		# Se por algum motivo o ângulo for diagonal, deixa ambos soltos
		axis_lock_linear_x = false
		axis_lock_linear_z = false

func _physics_process(delta: float) -> void:
	if is_on_path and trilho_atual != null:
		handle_path_movement(delta)
	else:
		apply_gravity(delta)
		handle_jump()
		handle_movement(delta)
		move_and_slide()
			
	update_animations()
	
	# Anti-clipping customizado da câmera
	if _camera_pivot and _cam_ray:
		var cam = _camera_pivot.get_node_or_null("Camera3D")
		if cam:
			# Força a atualização do raycast (necessário se o pivot moveu)
			_cam_ray.force_raycast_update()
			if _cam_ray.is_colliding():
				# Move a câmera para o ponto de colisão com uma margem de segurança na normal
				cam.global_position = _cam_ray.get_collision_point() + _cam_ray.get_collision_normal() * 0.25
			else:
				# Sem parede no caminho, volta para a posição original
				cam.position = _original_cam_pos

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

func sair_da_agua():
	na_agua = false

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
	var direction := Input.get_axis("move_left", "move_right")
	
	if Input.is_physical_key_pressed(KEY_SHIFT):
		esta_correndo = true
	if direction == 0:
		esta_correndo = false
		
	var current_speed = run_speed if esta_correndo else speed
	
	if direction != 0:
		trilho_atual.progress += direction * current_speed * delta
		if trilho_atual.progress_ratio >= 1.0:
			sair_do_caminho()
			return
		var rotacao_caminho = trilho_atual.global_rotation.y
		var rotacao_alvo = rotacao_caminho - PI - 1
		if direction == -1:
			rotacao_alvo = rotacao_alvo - PI
		visual_model.rotation.y = lerp_angle(visual_model.rotation.y, rotacao_alvo, 8 * delta)
	
	global_position = trilho_atual.global_position
	global_position.y += 1.0 
	velocity.x = direction * current_speed
	velocity.y = 0.0

func update_animations() -> void:
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
			if animation_player.current_animation != "Walk":
				animation_player.play("Walk", 0.2)
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

func sair_do_caminho() -> void:
	is_on_path = false
	trilho_atual = null
	# Atualiza o Z inicial para que ela assuma a nova profundidade onde o trilho terminou
	z_inicial = global_position.z

func receber_dano(quantidade: float) -> void:
	vida -= quantidade
	print("Pomni recebeu dano do morcego! Vida atual: ", int(vida))
	if vida <= 0:
		print("Pomni morreu!")
		get_tree().reload_current_scene()
