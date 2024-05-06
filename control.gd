extends Control

var coords_infectadas: Array
var en_proceso: bool
var iteraciones: int
var juego_vida: bool
var malla: Array
var modo_redes_grandes: bool
var prob: float
var red: Array
var red_tmp
var red_vidas: Array
var red_completa: bool
var red_curada: bool
var red_estancada: bool
var simular: bool
var tam_red: int
var tiempo: float
var tiempo_vida: int

# PARA EL GRID
var grid: bool
var grid_datos: Array
var grid_coords_infectadas
var prob_min
var prob_max
var tam_salto
var tiempo_vida_min: int
var tiempo_vida_max: int
var tam_salto_vida: int
var n_media: int
var media: Array
var nombre_archivo: String

func _ready():
	coords_infectadas = []
	en_proceso = false
	grid = false
	grid_datos = []
	iteraciones = 0
	juego_vida = false
	malla = $Malla.get_children()
	modo_redes_grandes = false
	prob = 1
	red = []
	red_vidas = []
	red_completa = false
	red_curada = false
	red_estancada = false
	simular = false
	tam_red = 25
	tiempo = 0.25
	tiempo_vida = 0

func _process(delta):
	if simular and $Timer.is_stopped() and not red_completa and not red_curada and not red_estancada:
		iteracion()
		$Output/Iteracion_Label.text = str(iteraciones)
		if not modo_redes_grandes:
			$Timer.start(tiempo)

func actualizar_malla(x, y, infectar):
	if infectar:
		malla[(x*tam_red+y)+x*(25-tam_red)].infectar()
	else:
		malla[(x*tam_red+y)+x*(25-tam_red)].desinfectar()

func obtener_vecinos(x, y):
	if juego_vida:
		var vecinos = 0
		for i in range(-1,2):
			for j in range(-1,2):
				if i != 0 or j != 0:
					vecinos += red[(x + i + tam_red) % tam_red][(y + j + tam_red) % tam_red]
		return vecinos
	else:
		var abajo = int(x != tam_red-1)
		var arriba = int(x != 0)
		var der = int(y != tam_red-1)
		var izq = int(y != 0)
		
		return abajo*red[x+abajo][y] + arriba*red[x-arriba][y] + der*red[x][y+der] + izq*red[x][y-izq]

func iteracion():
	var infectados = 0
	
	iteraciones += 1
	
	for x in tam_red:
		for y in tam_red:
			var vecinos = obtener_vecinos(x, y)
			if juego_vida: # SI JUEGO DE LA VIDA
				infectados = 1
				if red[x][y]: # SI ESTA VIVO
					if vecinos != 2 and vecinos != 3: # SI TIENE 2 O 3 VECINOS VIVOS MANTIENE ESTADO SI NO, SE MUERE
						red_tmp[x][y] = 0
						if not modo_redes_grandes:
								actualizar_malla(x, y, false)
				elif vecinos == 3: # SI ESTA MUERTO Y TIENE 3 VECINOS VIVOS, REVIVE
					red_tmp[x][y] = 1
					if not modo_redes_grandes:
								actualizar_malla(x, y, true)
			else: # NO JUEGO DE LA VIDA
				if not red[x][y]: # SI NO ESTA INFECTADO
					for v in vecinos:
						if randf() <= prob:
							red_tmp[x][y] = 1
							if tiempo_vida: # SI RECUPERACION HABILITADA ASIGNA VIDAS AL NODO RECIEN INFECTADO
								red_vidas[x][y] = tiempo_vida
							if not modo_redes_grandes:
								actualizar_malla(x, y, true)
							infectados += 1
							break
				else: # SI ESTA INFECTADO
					infectados += 1
					if tiempo_vida: # SI RECUPERACION HABILITADA
						if red_vidas[x][y] == 0: # SI EL NODO NO TIENE MAS VIDAS LO DESINFECTA
							infectados -= 1 
							red_tmp[x][y] = 0
							if not modo_redes_grandes:
								actualizar_malla(x, y, false)
						else:
							red_vidas[x][y] -= 1 # RESTA UN VIDA
			
			if infectados == tam_red*tam_red:
				red_completa = true
			
			if x == tam_red-1 and y == tam_red-1 and infectados == 0:
				red_curada = true
				print(red_curada)
			
			if iteraciones >= tam_red*100:
				red_estancada = true
			
			if grid and (red_completa or red_curada or red_estancada): # PARA EL GRID
				if red_estancada:
					media[0].append("estancada")
				else:
					media[0].append(red_curada)
				media[1].append(iteraciones)
				if media[1].size() < n_media:
					_on_reiniciar_button_button_up()
					coords_infectadas = grid_coords_infectadas.duplicate()
					_on_simular_button_button_up()
					return
				else:
					var sum:float = 0
					for n in media[1]:
						sum += n
					grid_datos.append(media[0])
					grid_datos.append(roundi(sum/float(n_media)))
					_on_reiniciar_button_button_up()
					guardar_csv(grid_datos)
					media = [[],[]]
					grid_datos = []
					
					if tiempo_vida < tiempo_vida_max:
						tiempo_vida += tam_salto_vida
					else:
						tiempo_vida = tiempo_vida_min
						prob += tam_salto
					
					if prob <= prob_max:
						grid_datos.append(grid_coords_infectadas)
						grid_datos.append(prob)
						grid_datos.append(tiempo_vida)
						coords_infectadas = grid_coords_infectadas.duplicate()
						_on_simular_button_button_up()
						return
				bloquear_grid(false)
				return
				
	red = red_tmp.duplicate(true)

func bloquear_controles(valor):
	$Controles/Prob_LineEdit.editable = not valor
	$Controles/Recuperacion_LineEdit.editable = not valor
	$Controles/Juego_Vida_CheckBox.disabled = valor
	
	if modo_redes_grandes:
		$Controles/Red_Grande_Button.disabled = true
		$Controles/Malla_HSlider.editable = false
		for n in malla:
			n.disabled = true
		
		$Controles/Red_Peque_Button.disabled = valor
		$Controles/Tam_Red_LineEdit.editable = not valor
		$Controles/Coords_LineEdit.editable = not valor
		$Controles/Infectar_Button.disabled = valor
		$Controles/Inf_Esq_Button.disabled = valor
		$Controles/Inf_Cen_Button.disabled = valor
		$Controles/Ajustar_Grid_Button.disabled = valor
	else:
		$Controles/Red_Grande_Button.disabled = valor
		$Controles/Malla_HSlider.editable = not valor
		for n in malla:
			n.disabled = valor
		
		$Controles/Red_Peque_Button.disabled = true
		$Controles/Tam_Red_LineEdit.editable = false
		$Controles/Coords_LineEdit.editable = false
		$Controles/Infectar_Button.disabled = true
		$Controles/Inf_Esq_Button.disabled = true
		$Controles/Inf_Cen_Button.disabled = true
		$Controles/Ajustar_Grid_Button.disabled = true

func _on_reiniciar_button_button_up():
	en_proceso = false
	coords_infectadas = []
	iteraciones = 0
	red = []
	red_completa = false
	red_curada = false
	red_estancada = false
	simular = false
	$Timer.stop()
	$Output/Iteracion_Label.text = "0"
	$Output/Coords_RichTextLabel.text = ""
	$Controles/Simular_Button.text = "Simular"
	$Malla.hide()
	$Malla.show()
	bloquear_controles(false)

func _on_simular_button_button_up():
	if not en_proceso: # EVITA QUE SE CREE DE NUEVO LA RED SI SOLO SE PONE EN PAUSA
		red = []
		red_vidas = []
		bloquear_controles(true)
		
		if modo_redes_grandes:
			for x in tam_red: # CREA LA RED ASIGNANDO DIRECTAMENTE LOS INFECTADOS
				red.append([])
				red_vidas.append([])
				for y in tam_red:
					red[x].append([])
					red_vidas[x].append([])
					if Vector2(x, y) in coords_infectadas:
						red[x][y] = 1
						if tiempo_vida: # ASIGNA LOS TIEMPOS DE VIDA A LOS INFECTADOS
							red_vidas[x][y] = tiempo_vida
					else:
						red[x][y] = 0
						if tiempo_vida: # ASIGNA 0 VIDAS A LOS NO INFECTADOS
							red_vidas[x][y] = 0
		else:
			var cont = -1
			
			for x in tam_red: # CREA LA RED
				red.append([])
				for y in tam_red:
					red[x].append([])
					red[x][y] = 0
			
			if tiempo_vida: # CREA LA RED QUE GUARDA LOS TIEMPOS DE VIDA
				red_vidas = red.duplicate(true)
			
			for n in malla: # INFECTA LOS NODOS CORRESPONDIENTES EN FUNCION DE LOS MARCADOS EN LA MALLA
				if n.visible:
					cont += 1
					if n.infectado:
						red[cont/tam_red][cont%tam_red] = 1
						if tiempo_vida: # ASIGNA LOS TIEMPOS DE VIDA A LOS INFECTADOS
							red_vidas[cont/tam_red][cont%tam_red] = tiempo_vida
	
	en_proceso = true
	red_tmp = red.duplicate(true)
	simular = not simular
	
	if simular:
		$Controles/Simular_Button.text = "Pausar"
	else:
		$Controles/Simular_Button.text = "Simular"

func _on_prob_line_edit_text_changed(new_text):
	prob = float(new_text)

func _on_malla_h_slider_value_changed(value):
	$Output/Malla_Label.text = str(value)

func _on_malla_h_slider_drag_ended(value_changed):
	tam_red = $Controles/Malla_HSlider.value
	
	for n in malla: # LIMPIA LA MALLA
		n.hide()
	
	for i in tam_red: # AJUSTA LA MALLA AL TAMAÑO DE LA RED
		for j in tam_red:
			malla[i*25+j].show()

func _on_red_peque_button_button_up():
	modo_redes_grandes = false
	tam_red = $Controles/Malla_HSlider.value
	bloquear_controles(false)

func _on_red_grande_button_button_up():
	modo_redes_grandes = true
	tam_red = int($Controles/Tam_Red_LineEdit.text)
	bloquear_controles(false)

func _on_tam_red_line_edit_text_changed(new_text):
	tam_red = int(new_text)

func _on_infectar_button_button_up():
	var texto = $Controles/Coords_LineEdit.text
	var coord = Vector2(int(texto.get_slice(" ",0)), int(texto.get_slice(" ",1)))
	
	if texto.count(" ") == 1 and not coord in coords_infectadas:
		coords_infectadas.append(coord)
		$Output/Coords_RichTextLabel.text += str(coord) + " "

func _on_inf_esq_button_button_up():
	if not Vector2(0,0) in coords_infectadas:
		coords_infectadas.append(Vector2(0,0))
		$Output/Coords_RichTextLabel.text += "(0,0) "

func _on_inf_cen_button_button_up():
	var coord = Vector2(tam_red/2,tam_red/2)
	
	if not coord in coords_infectadas:
		coords_infectadas.append(coord)
		$Output/Coords_RichTextLabel.text += str(coord) + " "

func _on_recuperacion_line_edit_text_changed(new_text):
	tiempo_vida = int(new_text)
	if tiempo_vida < 0:
		tiempo_vida = 0
	juego_vida = false # DESACTIVA EL JUEGO DE LA VIDA
	$Controles/Juego_Vida_CheckBox.set_pressed_no_signal(false)

func _on_juego_vida_check_box_toggled(toggled_on):
	juego_vida = toggled_on
	tiempo_vida = 0 # DESACTIVA LA RECUPERACION
	$Controles/Recuperacion_LineEdit.text = ""



func _on_ajustar_grid_button_button_up():
	$Ajustar_Grid_Window.show()

func _on_ajustar_grid_window_close_requested():
	$Ajustar_Grid_Window.hide()

func _on_generar_grid_button_button_up():
	$Ajustar_Grid_Window.hide()
	
	grid_coords_infectadas = coords_infectadas.duplicate()
	prob_min = float($Ajustar_Grid_Window/Controles_Grid/Osc_Prob_Min_LineEdit.text)
	prob_max = float($Ajustar_Grid_Window/Controles_Grid/Osc_Prob_Max_LineEdit.text)
	tam_salto = float($Ajustar_Grid_Window/Controles_Grid/Tam_Salto_LineEdit.text)
	tiempo_vida_min = int($Ajustar_Grid_Window/Controles_Grid/Osc_Rec_Min_LineEdit.text)
	tiempo_vida_max = int($Ajustar_Grid_Window/Controles_Grid/Osc_Rec_Max_LineEdit.text)
	tam_salto_vida = int($Ajustar_Grid_Window/Controles_Grid/Tam_Salto_Rec_LineEdit.text)
	n_media = int($Ajustar_Grid_Window/Controles_Grid/N_Simul_LineEdit.text)
	media = [[],[]]
	
	if prob_min <= 0 or tam_salto <= 0 or tiempo_vida_min < 0 or tam_salto_vida <= 0 or n_media <= 0:
		return
	
	grid = true
	
	if prob_max < prob_min:
		prob_max = prob_min
	
	if tiempo_vida_max < tiempo_vida_min:
		tiempo_vida_max = tiempo_vida_min
	
	bloquear_grid(true)
	
	nombre_archivo = crear_csv()
	
	prob = prob_min
	tiempo_vida = tiempo_vida_min
	grid_datos.append(grid_coords_infectadas)
	grid_datos.append(prob)
	grid_datos.append(tiempo_vida)
	_on_simular_button_button_up()

func bloquear_grid(valor):
	$Ajustar_Grid_Window/Controles_Grid/Osc_Prob_Min_LineEdit.editable = not valor
	$Ajustar_Grid_Window/Controles_Grid/Osc_Prob_Max_LineEdit.editable = not valor
	$Ajustar_Grid_Window/Controles_Grid/Tam_Salto_LineEdit.editable = not valor
	$Ajustar_Grid_Window/Controles_Grid/Osc_Rec_Min_LineEdit.editable = not valor
	$Ajustar_Grid_Window/Controles_Grid/Osc_Rec_Max_LineEdit.editable = not valor
	$Ajustar_Grid_Window/Controles_Grid/N_Simul_LineEdit.editable = not valor
	$Ajustar_Grid_Window/Controles_Grid/Generar_Grid_Button.disabled = valor
	
	$Controles/Reiniciar_Button.disabled = valor
	$Controles/Simular_Button.disabled = valor
	$Controles/Ajustar_Grid_Button.disabled = valor

func crear_csv():
	var tiempo = Time.get_datetime_dict_from_system()
	var fecha = "%d-%d-%d_%d-%d-%d" % [tiempo.day,tiempo.month,tiempo.year,tiempo.hour,tiempo.minute,tiempo.second]
	var dimensiones = "%dx%d" % [tam_red,tam_red]
	var grid_csv = FileAccess.open("user://grid_"+dimensiones+"_"+fecha+".csv", FileAccess.WRITE)
	grid_csv.store_line("Posición,Probabilidad,Tiempo de recuperación,Red curada,Iteraciones")
	return "grid_"+dimensiones+"_"+fecha

func guardar_csv(linea):
	var grid_csv = FileAccess.open("user://"+nombre_archivo+".csv", FileAccess.READ_WRITE)
	
	if linea[0] == [Vector2(0,0)]:
		linea[0] = "Esquina"
	elif linea[0] == [Vector2(tam_red/2,tam_red/2)]:
		linea[0] = "Centro"
	
	grid_csv.seek_end()
	grid_csv.store_csv_line(linea)
