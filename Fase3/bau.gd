extends Area3D

@onready var animationPlayer = $chest/AnimationPlayer

# Adicionei essas variáveis para você poder arrastar a Pistola que está dentro do baú no Inspetor
@export var pistola_do_bau: Node3D 
@export var nome_pistola_pomni: String = "Pistol" # Coloque aqui o nome exato do Nó da pistola que está na cena da Pomni

var estado_bau: int = 0 # 0 = Fechado, 1 = Aberto, 2 = Vazio (Coletado)
var pomni_na_area: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Força o baú a começar no frame 0 (fechado) e paralisa a animação. 
	# Isso corrige o problema do modelo 3D já vir aberto por padrão!
	if animationPlayer.has_animation("GoldenChest|OpenChest"):
		animationPlayer.play("GoldenChest|OpenChest")
		animationPlayer.seek(0.0, true)
		animationPlayer.stop()

func _on_body_entered(body: Node3D):
	if "Pomni" in body.name:
		pomni_na_area = body
		if estado_bau == 0:
			print("Pressione 'E' para abrir o baú.")
		elif estado_bau == 1:
			print("Pressione 'E' para pegar a arma.")

func _on_body_exited(body: Node3D):
	if body == pomni_na_area:
		pomni_na_area = null

func _input(event: InputEvent) -> void:
	# Checa se a Pomni está na área e a tecla E foi pressionada
	if pomni_na_area and event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo:
		
		if estado_bau == 0:
			# Passo 1: Abre o baú
			animationPlayer.play("GoldenChest|OpenChest")
			estado_bau = 1
			print("Baú aberto! Pressione 'E' para pegar a pistola.")
			
		elif estado_bau == 1:
			# Passo 2: Coleta a pistola
			if pistola_do_bau:
				pistola_do_bau.visible = false # Esconde se você linkou no inspetor
			else:
				# Tenta achar o nó automaticamente pelo nome caso você não tenha linkado!
				var pistol_no_bau = find_child("Pistol", true, false)
				if pistol_no_bau:
					pistol_no_bau.visible = false
			
			# Procura a pistola na mão da Pomni e faz aparecer!
			var pistola_na_mao = pomni_na_area.find_child(nome_pistola_pomni, true, false)
			if pistola_na_mao:
				pistola_na_mao.visible = true
			else:
				print("AVISO: A arma não apareceu porque não achei o nó chamado '", nome_pistola_pomni, "' na Pomni.")
				
			# Libera a habilidade de atirar (Criando uma flag na Pomni)
			pomni_na_area.set("tem_arma", true)
			
			# Destrói a porta do Hall de Entrada na cena principal
			var cena_raiz = get_tree().current_scene
			if cena_raiz:
				var porta = cena_raiz.find_child("PortaHallEntrada", true, false)
				if porta:
					porta.queue_free()
					print("Porta do Hall de Entrada removida!")
			
			estado_bau = 2
			print("Pistola adquirida!")
