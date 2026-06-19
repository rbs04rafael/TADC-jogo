extends CharacterBody3D

@export var speed: float = 4.0
@export var vida: float = 100.0

var estado: String = "amigavel"
var gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var pomni: Node3D = null

func _ready():
	# Tenta encontrar a Pomni na cena
	pomni = get_tree().get_root().find_child("Pomni", true, false)
	
	# Colisão e Hitbox da Abstração
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 2.0
	col.shape = shape
	col.position = Vector3(0, 1.0, 0)
	add_child(col)
	
	# Hitbox para machucar a Pomni se encostar
	var area = Area3D.new()
	var area_col = CollisionShape3D.new()
	var area_shape = CapsuleShape3D.new()
	area_shape.radius = 0.7
	area_shape.height = 2.2
	area_col.shape = area_shape
	area_col.position = Vector3(0, 1.0, 0)
	area.add_child(area_col)
	add_child(area)
	area.connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y -= gravidade * delta

	if pomni:
		_checar_luz_lanterna()
		
		if estado == "furioso":
			# Perseguir a Pomni
			var direcao = global_position.direction_to(pomni.global_position)
			direcao.y = 0 # Não voar
			direcao = direcao.normalized()
			
			velocity.x = direcao.x * speed
			velocity.z = direcao.z * speed
			
			# Rotacionar para olhar para a Pomni
			var alvo_look = Vector3(pomni.global_position.x, global_position.y, pomni.global_position.z)
			if global_position.distance_to(alvo_look) > 0.1:
				look_at(alvo_look, Vector3.UP)
		else:
			# Amigável, fica parado ou andando aleatório. Vamos deixar parado por enquanto.
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func _checar_luz_lanterna():
	if pomni and pomni.get("tem_lanterna") and pomni.get("lanterna_ligada"):
		var lanterna = pomni.get("ref_lanterna")
		var spot = pomni.get("ref_spotlight")
		if spot and lanterna:
			var distancia = global_position.distance_to(pomni.global_position)
			if distancia <= spot.spot_range:
				var dir_para_mim = pomni.global_position.direction_to(global_position).normalized()
				var dir_luz = -lanterna.global_transform.basis.z.normalized() # Spotlight aponta para -Z local da lanterna
				
				# Ângulo entre a direção da luz e a abstração
				var angulo = rad_to_deg(dir_luz.angle_to(dir_para_mim))
				if angulo <= spot.spot_angle:
					_ficar_furioso()

func _ficar_furioso():
	if estado != "furioso":
		estado = "furioso"
		print("Abstração ficou FURIOSA com a luz da lanterna!")
		# Poderia mudar a cor do material pra vermelho aqui

func receber_dano(quantidade: float):
	vida -= quantidade
	print("Abstração recebeu ", quantidade, " de dano! Vida restante: ", vida)
	# Se apanhar, fica furioso automaticamente
	_ficar_furioso()
	
	if vida <= 0:
		print("Abstração derrotada!")
		queue_free()

func _on_body_entered(body: Node3D):
	if estado == "furioso" and ("Pomni" in body.name or body.is_in_group("jogador")):
		if body.has_method("receber_dano"):
			body.receber_dano(20) # Causa dano à Pomni
