extends SceneTree

func _init():
	print("Carregando cena...")
	var scene_path = "res://Cenarios/CenarioMundoCompleto/CenarioCircoDigital.tscn"
	var packed_scene = ResourceLoader.load(scene_path)
	if not packed_scene:
		print("Erro: Não foi possível carregar a cena.")
		quit()
		return
		
	var scene_root = packed_scene.instantiate()
	
	var caminhos = scene_root.find_child("Caminhos", true, false)
	if not caminhos:
		print("Erro: Nó Caminhos não encontrado.")
		quit()
		return
		
	var caminho_parque = caminhos.find_child("CaminhoParque", true, false)
	if not caminho_parque:
		print("Erro: CaminhoParque não encontrado.")
		quit()
		return
		
	# Verifica se já existe um Seguidor
	var seguidor = caminho_parque.find_child("Seguidor", true, false)
	if not seguidor:
		seguidor = PathFollow3D.new()
		seguidor.name = "Seguidor"
		caminho_parque.add_child(seguidor)
		seguidor.owner = scene_root
		print("Seguidor (PathFollow3D) criado com sucesso em CaminhoParque!")
	else:
		print("Seguidor já existe.")
		
	# Reseta a posição do seguidor e salva a cena
	seguidor.progress_ratio = 0.0
	
	var new_packed_scene = PackedScene.new()
	new_packed_scene.pack(scene_root)
	ResourceSaver.save(new_packed_scene, scene_path)
	print("Cena salva com sucesso!")
	
	quit()
