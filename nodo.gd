extends Button

var infectado: bool


func _ready():
	infectado = false
	set_self_modulate(Color(1,1,0,1))

func _on_visibility_changed():
	infectado = false
	set_self_modulate(Color(1,1,0,1))

func _on_pressed():
	infectado = not infectado
	
	if infectado: set_self_modulate(Color(0,0,1,1))
	else: set_self_modulate(Color(1,1,0,1))

func infectar():
	infectado = true
	set_self_modulate(Color(0,0,1,1))

func desinfectar():
	infectado = false
	set_self_modulate(Color(1,1,0,1))
