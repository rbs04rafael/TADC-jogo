extends CharacterBody3D

var pode_atacar: bool = false
var material_teste: StandardMaterial3D

func _ready():
	# Cria o material dinâmico
	material_teste = StandardMaterial3D.new()
	$MeshInstance3D.material_override = material_teste

func _physics_process(delta):
	checar_iluminacao()
	
	if pode_atacar:
		# Modo Letal (Na Luz) - Fica Vermelho
		material_teste.albedo_color = Color.RED
	else:
		# Modo Inofensivo (Na Sombra) - Fica Azul
		material_teste.albedo_color = Color.BLUE

func checar_iluminacao():
	var esta_na_luz = false
	var estado_fisico = get_world_3d().direct_space_state
	
	var luzes = get_tree().get_nodes_in_group("luzes_perigo")
	
	for luz in luzes:
		# 1. Mede a distância exata entre o inimigo e esta luz
		var distancia = global_position.distance_to(luz.global_position)
		
		# 2. Só dispara o Raycast se o inimigo estiver dentro da área iluminada
		if distancia <= luz.omni_range:
			var query = PhysicsRayQueryParameters3D.create(global_position, luz.global_position)
			query.exclude = [self.get_rid()]
			
			var resultado = estado_fisico.intersect_ray(query)
			
			if not resultado:
				esta_na_luz = true
				break
				
	pode_atacar = esta_na_luz
