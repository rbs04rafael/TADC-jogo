extends CharacterBody3D

@export var speed: float = 6.0
@export var damage: float = 20.0

var is_furious: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pomni: Node3D = null
var attack_cooldown: float = 0.0

var vida: float = 100.0
var vida_maxima: float = 100.0

var health_bar_viewport: SubViewport
var health_bar_progress: ProgressBar
var health_bar_sprite: Sprite3D

var limite_a: Vector2
var limite_b: Vector2
var tem_limite: bool = false

var modo_cuphead: bool = false
var direcao_cuphead: int = 1

func _ready() -> void:
	# Só procura a Pomni se não tiverem passado a referência direta pra ela (O Boss Caine agora passa a ref)
	if pomni == null:
		pomni = get_tree().get_root().find_child("Pomni", true, false)
	
	_create_health_bar()
	
	# Mapeia as viradas para restringir o movimento apenas se não estiver no modo Cuphead!
	if not modo_cuphead:
		call_deferred("_mapear_limites")

func _mapear_limites() -> void:
	var cena_raiz = get_tree().get_root()
	var pontos_caminho = []
	
	for i in range(1, 8):
		var v = cena_raiz.find_child("Virada" + str(i), true, false)
		if v:
			pontos_caminho.append(_get_centro_area(v))
			
	var area_fim = cena_raiz.find_child("Area3d", true, false)
	if area_fim:
		pontos_caminho.append(_get_centro_area(area_fim))
		
	if pontos_caminho.size() < 2:
		return
		
	var menor_dist = INF
	var pos2d = Vector2(global_position.x, global_position.z)
	
	for i in range(pontos_caminho.size() - 1):
		var a = Vector2(pontos_caminho[i].x, pontos_caminho[i].z)
		var b = Vector2(pontos_caminho[i+1].x, pontos_caminho[i+1].z)
		
		var dist = _distancia_ponto_segmento(pos2d, a, b)
		if dist < menor_dist:
			menor_dist = dist
			limite_a = a
			limite_b = b
			tem_limite = true

func _get_centro_area(area: Node3D) -> Vector3:
	for child in area.get_children():
		if child is CollisionShape3D:
			return child.global_position
	return area.global_position

func _distancia_ponto_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	if ab.length_squared() == 0:
		return p.distance_to(a)
	var t = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var proj = a + t * ab
	return p.distance_to(proj)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not pomni:
		move_and_slide()
		return
		
	if modo_cuphead:
		velocity.x = direcao_cuphead * speed
		velocity.z = 0
		
		# Faz a abstração olhar para a direção em que está correndo
		# Como o modelo 3D é invertido (+Z pra frente), subtraímos o vetor direção
		var dir = Vector3(direcao_cuphead, 0, 0)
		var look_at_pos = global_position - dir
		look_at_pos.y = global_position.y
		if look_at_pos.distance_squared_to(global_position) > 0.001:
			var target_transform = global_transform.looking_at(look_at_pos, Vector3.UP)
			global_transform.basis = global_transform.basis.slerp(target_transform.basis, 15.0 * delta)
		
		move_and_slide()
		_check_damage(delta)
		
		if direcao_cuphead > 0 and global_position.x > pomni.posicao_x_max + 2.0:
			queue_free()
		elif direcao_cuphead < 0 and global_position.x < pomni.posicao_x_min - 2.0:
			queue_free()
		return
		
	_check_flashlight()
	
	if is_furious:
		_chase_pomni(delta)
	else:
		_idle_behavior(delta)
		
	move_and_slide()
	_check_damage(delta)
	
	# Prende a abstração no seu respectivo segmento de linha
	if tem_limite:
		var pos2d = Vector2(global_position.x, global_position.z)
		var ab = limite_b - limite_a
		if ab.length_squared() > 0.001:
			var ap = pos2d - limite_a
			var t = clamp(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
			var proj = limite_a + ab * t
			global_position.x = proj.x
			global_position.z = proj.y

func _check_flashlight() -> void:
	# Se já está furiosa, não precisa checar de novo
	if is_furious: return
	
	if "lanterna_ligada" in pomni and "tem_lanterna" in pomni:
		if pomni.lanterna_ligada and pomni.tem_lanterna:
			var spot = pomni.ref_spotlight
			if spot and spot.visible:
				var to_abstracao = global_position - spot.global_position
				var distance = to_abstracao.length()
				if distance < spot.spot_range: # Alcance dinâmico da lanterna
					var dir_abstracao = to_abstracao.normalized()
					# O eixo -Z local do Spotlight é pra onde a luz aponta
					var forward_light = -spot.global_transform.basis.z.normalized()
					
					# Se o ângulo for menor que ~30 graus (dot product > 0.86)
					if dir_abstracao.dot(forward_light) > 0.86:
						_become_furious()

func _become_furious() -> void:
	is_furious = true
	print("Abstração ficou FURIOSA com a luz da lanterna e está perseguindo a Pomni!")
	if health_bar_sprite:
		health_bar_sprite.visible = true

func _chase_pomni(delta: float) -> void:
	var to_pomni = pomni.global_position - global_position
	to_pomni.y = 0 # Ignora eixo Y para mover só no chão
	if to_pomni.length() > 0.5:
		var dir = to_pomni.normalized()
		# Corre atrás da Pomni
		velocity.x = move_toward(velocity.x, dir.x * speed, 15.0 * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, 15.0 * delta)
		
		# Faz a abstração olhar para a Pomni, mas inverte a direção ( - dir ) 
		# porque o modelo 3D foi importado com a frente apontando para +Z em vez de -Z.
		var look_at_pos = global_position - dir
		look_at_pos.y = global_position.y
		
		# look_at trava se o vetor up for paralelo, mas como é só no chão, é seguro.
		var target_transform = global_transform.looking_at(look_at_pos, Vector3.UP)
		# Suaviza a rotação (lerp do Quat)
		global_transform.basis = global_transform.basis.slerp(target_transform.basis, 8.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 15.0 * delta)

func _idle_behavior(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 5.0 * delta)
	velocity.z = move_toward(velocity.z, 0, 5.0 * delta)

func _check_damage(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		
	if not is_furious: return
	
	if attack_cooldown <= 0.0:
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			var collider = col.get_collider()
			if collider == pomni:
				if pomni.has_method("receber_dano"):
					pomni.receber_dano(damage, global_position)
					attack_cooldown = 1.0 # 1 segundo de cooldown para o próximo ataque
					
					# Empurrão leve pra trás após bater
					var knockback = (global_position - pomni.global_position).normalized()
					velocity = knockback * (speed * 0.5)
					break

func _create_health_bar() -> void:
	health_bar_viewport = SubViewport.new()
	health_bar_viewport.transparent_bg = true
	health_bar_viewport.size = Vector2i(200, 30)
	health_bar_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	health_bar_progress = ProgressBar.new()
	health_bar_progress.size = Vector2(200, 30)
	health_bar_progress.value = vida
	health_bar_progress.max_value = vida_maxima
	health_bar_progress.show_percentage = false
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(1, 0, 0, 1)
	health_bar_progress.add_theme_stylebox_override("background", sb_bg)
	health_bar_progress.add_theme_stylebox_override("fill", sb_fg)
	
	health_bar_viewport.add_child(health_bar_progress)
	add_child(health_bar_viewport)
	
	health_bar_sprite = Sprite3D.new()
	health_bar_sprite.texture = health_bar_viewport.get_texture()
	health_bar_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar_sprite.position = Vector3(0, 3.0, 0) # Acima da cabeça
	health_bar_sprite.visible = false
	add_child(health_bar_sprite)

func receber_dano(quantidade: float, origem: Vector3 = Vector3.ZERO) -> void:
	vida -= abs(quantidade)
	
	if health_bar_progress:
		health_bar_progress.value = vida
		
	if not is_furious:
		_become_furious()
		
	# Efeito de Dano Visual
	var meshes = []
	_buscar_meshes(self, meshes)
	
	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color(1, 0, 0, 0.5)
	red_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	red_mat.emission_enabled = true
	red_mat.emission = Color(1, 0, 0)
	red_mat.emission_energy_multiplier = 2.0
	
	for mesh in meshes:
		mesh.material_overlay = red_mat
		
	# Knockback
	if origem != Vector3.ZERO:
		var dir = (global_position - origem)
		dir.y = 0
		if dir.length_squared() > 0.001:
			dir = dir.normalized()
			velocity.x = dir.x * 12.0
			velocity.z = dir.z * 12.0
			velocity.y = 4.0
			
	if vida <= 0:
		queue_free()
		
	await get_tree().create_timer(0.2).timeout
	for mesh in meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = null

func _buscar_meshes(node: Node, lista: Array) -> void:
	if node is MeshInstance3D:
		lista.append(node)
	for child in node.get_children():
		_buscar_meshes(child, lista)
