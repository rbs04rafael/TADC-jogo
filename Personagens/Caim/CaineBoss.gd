extends CharacterBody3D

var hp: float = 1000.0

@onready var visual = $"."
@onready var animation_player = $CaimFinalForm/AnimationPlayer

func _ready():
	add_to_group("boss")
	print("Boss Caine spawnou com ", hp, " de vida.")
	
	if animation_player:
		var anim_name = "META-Sintel|Idle_Caine"
		if animation_player.has_animation(anim_name):
			var anim = animation_player.get_animation(anim_name)
			anim.loop_mode = Animation.LOOP_LINEAR
			
			# Configura a Godot para interpolar (suavizar) os ossos automaticamente entre as duas animações!
			var arremesso_anim = "ArremessaGloinks"
			if animation_player.has_animation(arremesso_anim):
				animation_player.set_blend_time(anim_name, arremesso_anim, 0.2) # Do idle pro arremesso
				animation_player.set_blend_time(arremesso_anim, anim_name, 0.4) # Do arremesso de volta pro idle (mais suave)
				
			animation_player.play(anim_name)


var hp_perdido_acumulado: float = 0.0
var animacoes_dano: Array = ["CaimMovimentoEsquerda", "CaimMovimentoDireita", "CaimMovimentoMeio"]
var indice_animacao_atual: int = 0
var _scene_anim_player: AnimationPlayer = null

func _get_scene_anim_player() -> AnimationPlayer:
	if _scene_anim_player != null:
		return _scene_anim_player
	if get_tree() and get_tree().current_scene:
		_scene_anim_player = _find_anim_player_with("CaimMovimentoEsquerda", get_tree().current_scene)
	return _scene_anim_player

func _find_anim_player_with(anim_name: String, node: Node) -> AnimationPlayer:
	if node is AnimationPlayer and node.has_animation(anim_name):
		return node
	for child in node.get_children():
		var res = _find_anim_player_with(anim_name, child)
		if res: return res
	return null

func receber_dano(quantidade: float):
	hp -= quantidade
	hp_perdido_acumulado += quantidade

	print("Caine recebeu ", quantidade, " de dano! HP restante: ", hp)
	
	# Checa se acumulou 100 de dano ou mais
	while hp_perdido_acumulado >= 100.0:
		hp_perdido_acumulado -= 100.0
		
		var anim_tocar = animacoes_dano[indice_animacao_atual]
		var s_anim = _get_scene_anim_player()
		
		if s_anim and s_anim.has_animation(anim_tocar):
			s_anim.play(anim_tocar)
		else:
			print("AVISO: Nenhuma animação encontrada para ", anim_tocar, " na cena.")
			
		# Avança o índice (vai para 0, 1, 2 e volta pro 0)
		indice_animacao_atual = (indice_animacao_atual + 1) % animacoes_dano.size()

	# Efeito de piscar vermelho ou sumir rápido para dar feedback de hit
	if visual:
		visual.visible = false
		await get_tree().create_timer(0.05).timeout
		visual.visible = true
		
	if hp <= 0:
		morrer()

func morrer():
	print("Caine Final Form derrotado!")
	
	# Busca e deleta as portas para abrir passagem
	var porta_direita = get_tree().get_root().find_child("PortaDireita", true, false)
	if porta_direita:
		porta_direita.queue_free()
	
	var porta_esquerda = get_tree().get_root().find_child("PortaEsquerda", true, false)
	if porta_esquerda:
		porta_esquerda.queue_free()
		
	# Finaliza a batalha final para a Pomni (retorna a câmera e destrava eixos)
	if pomni_ref and pomni_ref.has_method("finalizar_batalha_final"):
		pomni_ref.finalizar_batalha_final()
		
	# Aqui você pode carregar a cena de zeramento ou animação de morte!
	queue_free()

var timer_abstracao: float = 5.0
var proxima_direcao_abstracao: int = 1 # 1 = Esquerda->Direita, -1 = Direita->Esquerda

var timer_arremesso: float = 3.0

var pomni_ref: Node3D = null
var cena_abs: PackedScene = preload("res://Personagens/Abstracao/Abstracao.tscn")

# Carrega automaticamente as 3 cenas de Gloinks que você já criou!
@export var gloinks_caindo: Array[PackedScene] = [
	preload("res://Personagens/Gloinks/PinoGloink.tscn"),
	preload("res://Personagens/Gloinks/QuadradoGloink.tscn"),
	preload("res://Personagens/Gloinks/TrianguloGloink.tscn"),
	preload("res://Personagens/Gloinks/LuaGloink.tscn")
]

func _process(delta: float) -> void:
	if pomni_ref == null:
		pomni_ref = get_tree().get_root().find_child("Pomni", true, false)
		
	if not pomni_ref or not pomni_ref.get("em_batalha_final"):
		return
		
	timer_abstracao -= delta
	if timer_abstracao <= 0:
		timer_abstracao = 5.0
		spawn_abstracao()
		
	timer_arremesso -= delta
	if timer_arremesso <= 0:
		timer_arremesso = 3.0
		preparar_arremesso()

# ======== NOVA LÓGICA DE ARREMESSO (CHUVA DE OBJETOS) ========

func preparar_arremesso() -> void:
	# 1. Toca a animação feita no Blender
	if animation_player:
		var anim_name = "ArremessaGloinks"
		var anim_final = anim_name
		if not animation_player.has_animation(anim_final):
			anim_final = "META-Sintel|" + anim_name
			
		if animation_player.has_animation(anim_final):
			animation_player.play(anim_final)
			# Após terminar o arremesso, volta sozinho pro Idle
			animation_player.queue("META-Sintel|Idle_Caine")
		else:
			print("AVISO: Animação de arremesso não encontrada!")
			
	# 2. Chama a lógica que vai esperar o braço dele ir pra frente e dropar o objeto
	disparar_ataque_arremesso()

func disparar_ataque_arremesso() -> void:
	print("Caine fez o movimento de arremesso!")
	await get_tree().create_timer(1.5).timeout
	_fazer_objetos_cairem_na_pomni()

func _fazer_objetos_cairem_na_pomni() -> void:
	print("3 Gloinks estão caindo do teto!")
	
	if gloinks_caindo.size() == 0 or not pomni_ref:
		print("Falta adicionar as Cenas dos Gloinks no Array do Inspetor do Caine!")
		return
		
	# Vamos fazer um laço de repetição (loop) para spawnar 3 de uma vez!
	for i in range(6):
		var cena_sorteada = gloinks_caindo.pick_random()
		if not cena_sorteada: continue
		
		var objeto = cena_sorteada.instantiate()
		get_tree().current_scene.add_child(objeto)
		
		var x_alvo = pomni_ref.global_position.x
		var z_alvo = pomni_ref.global_position.z
		var altura = 15.0
		
		if i == 0:
			# 1º GLOINK: Cai EXATAMENTE na cabeça da Pomni para forçá-la a andar
			pass
		else:
			# 2º e 3º GLOINKS: Caem em posições X totalmente aleatórias dentro da tela
			# Puxamos os limites laterais direto da Pomni!
			var limite_esq = pomni_ref.posicao_x_min
			var limite_dir = pomni_ref.posicao_x_max
			x_alvo = randf_range(limite_esq, limite_dir)
			
			# Adiciona uma variação na altura para eles caírem em tempos um pouco diferentes
			altura += randf_range(0.0, 6.0)
		
		# Posição final onde o Gloink vai spawnar lá no céu
		objeto.global_position = Vector3(x_alvo, pomni_ref.global_position.y + altura, z_alvo)

# =============================================================

func spawn_abstracao() -> void:
	if not cena_abs: return
	
	var abstracao = cena_abs.instantiate()
	
	# Seta as propriedades ANTES de adicionar na cena, assim o _ready da abstração já sabe que é modo cuphead
	abstracao.modo_cuphead = true
	abstracao.direcao_cuphead = proxima_direcao_abstracao
	abstracao.speed = 10.0 # Pode ajustar a velocidade dos minions aqui
	abstracao.is_furious = true 
	abstracao.pomni = pomni_ref # Passa a referência direta para evitar lentidão de busca
	
	get_tree().current_scene.add_child(abstracao)
	
	var z_pos = pomni_ref.global_position.z
	var x_pos = 0.0
	
	# Spawna exatamente fora dos limites da tela da câmera (calculados dinamicamente pela Pomni)
	if proxima_direcao_abstracao == 1:
		x_pos = pomni_ref.posicao_x_min - 2.0
	else:
		x_pos = pomni_ref.posicao_x_max + 2.0
		
	abstracao.global_position = Vector3(x_pos, pomni_ref.global_position.y, z_pos)
	
	proxima_direcao_abstracao *= -1 # Alterna o lado para o próximo spawn
