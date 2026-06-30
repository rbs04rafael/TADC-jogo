extends Area3D

var pomni: CharacterBody3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pomni = get_tree().get_root().find_child("Pomni", true, false)
	
	body_entered.connect(on_body_entered)

func on_body_entered(body: Node3D):
	if body == pomni:
		if pomni.has_method("iniciar_batalha_final"):
			pomni.iniciar_batalha_final()
			
		var anim_player = get_tree().current_scene.find_child("AnimationPlayer", true, false)
		if anim_player:
			anim_player.play("CaimSubindo")
			
			# Como a Godot só toca uma animação por vez no mesmo Player, 
			# criamos um sub-player temporário na memória para tocar a segunda simultaneamente!
			var sub_player = AnimationPlayer.new()
			sub_player.add_animation_library("", anim_player.get_animation_library(""))
			# Adiciona na mesma raiz da cena, para que os caminhos dos nós da animação funcionem
			anim_player.get_parent().add_child(sub_player)
			# Copia o caminho da raiz da animação original
			sub_player.root_node = anim_player.root_node
			
			sub_player.play("CenarioBatalhaFinal")
			
		# Destrói o gatilho para não rodar duas vezes
		call_deferred("queue_free")
