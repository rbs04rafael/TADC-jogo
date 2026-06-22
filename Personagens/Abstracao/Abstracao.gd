extends CharacterBody3D

@export var speed: float = 6.0
@export var damage: float = 25.0

var is_furious: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pomni: Node3D = null
var attack_cooldown: float = 0.0

func _ready() -> void:
	# Encontra a Pomni na cena, já que agora as abstrações são colocadas manualmente
	pomni = get_tree().get_root().find_child("Pomni", true, false)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not pomni:
		move_and_slide()
		return
		
	_check_flashlight()
	
	if is_furious:
		_chase_pomni(delta)
	else:
		_idle_behavior(delta)
		
	move_and_slide()
	_check_damage(delta)

func _check_flashlight() -> void:
	# Se já está furiosa, não precisa checar de novo
	if is_furious: return
	
	if "lanterna_ligada" in pomni and "tem_lanterna" in pomni:
		if pomni.lanterna_ligada and pomni.tem_lanterna:
			var spot = pomni.ref_spotlight
			if spot and spot.visible:
				var to_abstracao = global_position - spot.global_position
				var distance = to_abstracao.length()
				if distance < 18.0: # Alcance da lanterna
					var dir_abstracao = to_abstracao.normalized()
					# O eixo -Z local do Spotlight é pra onde a luz aponta
					var forward_light = -spot.global_transform.basis.z.normalized()
					
					# Se o ângulo for menor que ~30 graus (dot product > 0.86)
					if dir_abstracao.dot(forward_light) > 0.86:
						_become_furious()

func _become_furious() -> void:
	is_furious = true
	print("Abstração ficou FURIOSA com a luz da lanterna e está perseguindo a Pomni!")
	# Pode adicionar aqui uma mudança de cor nos materiais, se desejar!

func _chase_pomni(delta: float) -> void:
	var to_pomni = pomni.global_position - global_position
	to_pomni.y = 0 # Ignora eixo Y para mover só no chão
	if to_pomni.length() > 0.5:
		var dir = to_pomni.normalized()
		# Corre atrás da Pomni
		velocity.x = move_toward(velocity.x, dir.x * speed, 15.0 * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, 15.0 * delta)
		
		# Faz a abstração olhar para a Pomni (interpola suavemente a rotação)
		var look_at_pos = global_position + dir
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
					pomni.receber_dano(damage)
					attack_cooldown = 1.0 # 1 segundo de cooldown para o próximo ataque
					
					# Empurrão leve pra trás após bater
					var knockback = (global_position - pomni.global_position).normalized()
					velocity = knockback * (speed * 0.5)
					break
