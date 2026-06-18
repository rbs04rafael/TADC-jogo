extends Node3D

@export var alvo_do_farol: PathFollow3D # Arraste o nó PathFollow3D aqui no Inspetor!
@export var velocidade_patrulha: float = 8.0
@export var velocidade_perseguicao: float = 4.5
@export var dano_do_morcego: int = 25
@export var intervalo_dano: float = 1.0

var pomni_na_luz = null
var ja_foi_vista = false
var direcao_patrulha: float = 1.0
var tempo_ultimo_dano: float = 0.0
var morcego: Node3D
var luz_ataque: OmniLight3D
var particulas_ataque: CPUParticles3D
var ponto_foco_luz: Vector3

func _ready():
	if alvo_do_farol == null:
		var scene_root = get_tree().current_scene
		if scene_root:
			var caminho = scene_root.find_child("CaminhoPedraLago", true, false)
			if caminho:
				alvo_do_farol = caminho.get_node_or_null("PathFollow3D")
				
	if alvo_do_farol != null:
		alvo_do_farol.loop = false
		
	# Procura o nó 'morcego' que foi colocado na cena, em qualquer lugar
	var scene_root = get_tree().current_scene
	if scene_root:
		morcego = scene_root.find_child("morcego", true, false)
		if morcego == null:
			# Caso o usuário tenha renomeado para "Bat" ou com inicial maiúscula
			morcego = scene_root.find_child("Morcego", true, false)
			if morcego == null:
				morcego = scene_root.find_child("Bat", true, false)
				
	if alvo_do_farol != null:
		ponto_foco_luz = alvo_do_farol.global_position

	# Cria efeitos visuais de ataque vermelhos no morcego
	if morcego != null:
		luz_ataque = OmniLight3D.new()
		luz_ataque.light_color = Color(1.0, 0.0, 0.2)
		luz_ataque.light_energy = 0.0
		luz_ataque.omni_range = 8.0
		morcego.add_child(luz_ataque)
		
		particulas_ataque = CPUParticles3D.new()
		particulas_ataque.emitting = false
		particulas_ataque.amount = 40
		particulas_ataque.lifetime = 0.5
		particulas_ataque.mesh = SphereMesh.new()
		particulas_ataque.mesh.radius = 0.1
		particulas_ataque.mesh.height = 0.2
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.0, 0.2)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.0, 0.2)
		particulas_ataque.mesh.surface_set_material(0, mat)
		particulas_ataque.direction = Vector3(0, 1, 0)
		particulas_ataque.spread = 180.0
		particulas_ataque.initial_velocity_min = 2.0
		particulas_ataque.initial_velocity_max = 6.0
		morcego.add_child(particulas_ataque)

func _process(delta):
	# --- LÓGICA DO CAMINHO PERFEITO E PERSEGUIÇÃO ---
	if alvo_do_farol != null:
		if ja_foi_vista and pomni_na_luz != null:
			# A luz persegue a Pomni!
			# Ignora a diferença de altura (Y) para o ponto focal de luz não flutuar
			var alvo_pos = pomni_na_luz.global_position
			alvo_pos.y = ponto_foco_luz.y
			
			var direcao_para_pomni = ponto_foco_luz.direction_to(alvo_pos)
			ponto_foco_luz += direcao_para_pomni * velocidade_perseguicao * delta
		else:
			# Patrulha normal no trilho
			alvo_do_farol.progress += (velocidade_patrulha * direcao_patrulha) * delta
			if alvo_do_farol.progress_ratio >= 1.0:
				direcao_patrulha = -1.0
			elif alvo_do_farol.progress_ratio <= 0.0:
				direcao_patrulha = 1.0
			
			# O ponto de foco volta para o caminho suavemente
			ponto_foco_luz = ponto_foco_luz.lerp(alvo_do_farol.global_position, 5.0 * delta)
		
		# Faz o eixo e as luzes mirarem sempre no ponto focal (que pode estar no caminho ou na Pomni)
		look_at(ponto_foco_luz, Vector3.UP)
		if has_node("LuzDoFarol"):
			$LuzDoFarol.look_at(ponto_foco_luz, Vector3.UP)
		if has_node("ZonaDeAlarme"):
			$ZonaDeAlarme.look_at(ponto_foco_luz, Vector3.UP)


	# --- LÓGICA DE DETECÇÃO PRECISA ---
	if pomni_na_luz != null:
		# Usa matemática de vetores para conferir se ela está EXATAMENTE dentro do círculo de luz
		var luz = $LuzDoFarol if has_node("LuzDoFarol") else self
		var dir_to_pomni = luz.global_position.direction_to(pomni_na_luz.global_position)
		var forward_dir = -luz.global_transform.basis.z
		var angulo_graus = rad_to_deg(forward_dir.angle_to(dir_to_pomni))
		
		# Pega a largura do cone da lâmpada (no nosso caso, 6.0)
		var limite_angulo = luz.spot_angle if "spot_angle" in luz else 6.0
		
		if angulo_graus <= limite_angulo:
			# Ela está iluminada!
			if ja_foi_vista == false and pomni_na_luz.is_on_floor():
				print("🚨 POMNI FOI VISTA PELO FAROL! 🚨")
				ja_foi_vista = true 
				if "regenerando" in pomni_na_luz:
					pomni_na_luz.regenerando = false
				
			# O morcego ataca Pomni enquanto ela estiver na luz
			if ja_foi_vista and pomni_na_luz.has_method("receber_dano"):
				if luz_ataque: luz_ataque.light_energy = 8.0
				if particulas_ataque: particulas_ataque.emitting = true
				
				tempo_ultimo_dano += delta
				if tempo_ultimo_dano >= intervalo_dano:
					pomni_na_luz.receber_dano(dano_do_morcego)
					tempo_ultimo_dano = 0.0
					
				# Faz o morcego avançar intensamente para o meio do corpo da Pomni
				if morcego != null:
					var alvo_ataque = pomni_na_luz.global_position + Vector3(0, 1.0, 0)
					morcego.global_position = morcego.global_position.lerp(alvo_ataque, 12.0 * delta)
					if morcego.global_position.distance_squared_to(alvo_ataque) > 0.1:
						morcego.look_at(alvo_ataque, Vector3.UP)
		else:
			# Ela saiu de baixo da lâmpada, mas ainda está perto
			if ja_foi_vista == true:
				print("💨 Pomni fugiu da luz do farol! 💨")
				ja_foi_vista = false
				tempo_ultimo_dano = 0.0 # Reseta o timer de dano
				if "regenerando" in pomni_na_luz:
					pomni_na_luz.regenerando = true

			if luz_ataque: luz_ataque.light_energy = lerp(luz_ataque.light_energy, 0.0, 5.0 * delta)
			if particulas_ataque: particulas_ataque.emitting = false

			# Se o morcego não estiver atacando, ele deve patrulhar junto com a luz.
			if morcego != null and alvo_do_farol != null:
				# Posição mais perto do chão (Y = 1.5)
				var centro_da_luz_no_chao = ponto_foco_luz + Vector3(0, 1.5, 0)
				
				# Menos preso à luz: valor menor no lerp cria um atraso/suavidade no voo
				morcego.global_position = morcego.global_position.lerp(centro_da_luz_no_chao, 1.5 * delta)
				
				# Faz o morcego olhar para a direção do movimento da luz
				var path_dir = (alvo_do_farol.global_transform.basis.z * direcao_patrulha)
				var direcao_olhar = centro_da_luz_no_chao + path_dir
				if morcego.global_position.distance_squared_to(direcao_olhar) > 0.1:
					morcego.look_at(direcao_olhar, Vector3.UP)

func _on_zona_de_alarme_body_entered(body):
	if body.is_in_group("jogador"):
		pomni_na_luz = body

func _on_zona_de_alarme_body_exited(body):
	if body == pomni_na_luz:
		if "regenerando" in pomni_na_luz:
			pomni_na_luz.regenerando = true
		pomni_na_luz = null
		if ja_foi_vista == true:
			print("💨 Pomni fugiu da luz do farol! 💨")
			ja_foi_vista = false
			tempo_ultimo_dano = 0.0
