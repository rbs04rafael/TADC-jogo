extends Area3D

var damage_amount : float = 20.0
var damage_interval : float = 1.0
var damage_timer : float = 0.0
var player_inside = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Create particle effect using CPUParticles3D
	var particles = CPUParticles3D.new()
	add_child(particles)
	particles.amount = 100
	particles.lifetime = 2.0
	particles.speed_scale = 0.5
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	particles.transform.origin = Vector3(0, 0.5, 0)
	
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(35, 0.5, 30)
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 10.0
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 3.0
	particles.gravity = Vector3(0, 1, 0)
	particles.color = Color(0.2, 0.9, 0.2, 0.6)
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.15
	mesh.height = 0.3
	mesh.radial_segments = 8
	mesh.rings = 4
	
	var spat_mat = StandardMaterial3D.new()
	spat_mat.albedo_color = Color(0.2, 0.9, 0.2, 0.8)
	spat_mat.emission_enabled = true
	spat_mat.emission = Color(0.1, 0.8, 0.1, 1.0)
	mesh.surface_set_material(0, spat_mat)
	
	particles.mesh = mesh
func _process(delta):
	if player_inside:
		damage_timer += delta
		if damage_timer >= damage_interval:
			if player_inside.has_method("receber_dano"):
				player_inside.receber_dano(damage_amount)
			damage_timer = 0.0

func obter_altura_superficie() -> float:
	var y_max = global_position.y
	for child in get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			var top = child.global_position.y + (child.shape.size.y / 2.0)
			if top > y_max:
				y_max = top
	return y_max

func _on_body_entered(body):
	if body.has_method("receber_dano"):
		player_inside = body
		player_inside.receber_dano(damage_amount)
		damage_timer = 0.0
		
	if body.has_method("entrar_na_agua"):
		body.entrar_na_agua(obter_altura_superficie())

func _on_body_exited(body):
	if body == player_inside:
		player_inside = null
		
	if body.has_method("sair_da_agua"):
		body.sair_da_agua()
