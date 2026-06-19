extends Node

var concluido = false
var tempo_checagem = 1.0

func _process(delta):
	if concluido:
		return
		
	tempo_checagem -= delta
	if tempo_checagem <= 0:
		tempo_checagem = 1.0
		_checar_inimigos()

func _checar_inimigos():
	var grupo = get_tree().get_root().find_child("Abstracoes", true, false)
	if grupo:
		if grupo.get_child_count() == 0:
			concluido = true
			_finalizar_fase()

func _finalizar_fase():
	print("Todas as abstrações foram derrotadas! Abrindo caminho pro Circo...")
	# Criar ponte final até o Circo
	var cena_raiz = get_tree().get_root()
	var cenario = cena_raiz.find_child("CenarioCircoDigital", false, false)
	if not cenario:
		cenario = get_parent()
		
	var caminho_final = Node3D.new()
	caminho_final.name = "CaminhoFinalCirco"
	cenario.add_child(caminho_final)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.8, 0, 0.8) # Dourado
	mat.emission_enabled = true
	mat.emission = Color(1, 0.8, 0)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# O circo está mais ou menos em x=40, z=-40 ou x=40, z=-10
	# Vamos fazer um caminho em direção a x=40, z=-40
	for i in range(10):
		var mesh = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.8
		sphere.height = 1.6
		mesh.mesh = sphere
		mesh.set_surface_override_material(0, mat)
		
		# Posição interpolada (do centro do parque até o circo)
		mesh.position = Vector3(35 + (i*0.5), 1.0, -30 - (i*1.5))
		
		var body = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.9
		col.shape = shape
		body.add_child(col)
		mesh.add_child(body)
		
		caminho_final.add_child(mesh)
	
	print("Caminho pro circo aberto! Fase 1 finalizada (Pronto pra transição da Fase 2).")
