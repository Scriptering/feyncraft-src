extends Control

@onready var Box = get_node('Box')
@onready var ConnectedInteraction: Interaction = get_parent()
@onready var TabC = get_node('Box/MarginContainer/TabContainer')
@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var Cursor = Level.get_node('Cursor')
@onready var Clock = get_node('Timer')

@onready var Row = preload("res://Scenes and Scripts/UI/Info/InfoRow.tscn")

var hovering := false
var scroll_hovering := false
var placed := true
var start_mouse := Vector2()

var old_name_index := [[],[]]

var Tab
var Scroll
var Rows

#1 charge, 2 lepton num., 3 e. num, 4 mu num., 5 tau num., 6 quark num., 7 up num., 8 down num., 9 charm num., 10 strange num., 11 top num., 12 bottom num., 13 colour

var names = [['lol', 'charge', 'lepton num.', 'electron num.', 'mu num.', 'tau num.', 'baryon num.', 'up num.', 'down num.', 'charm num.', 'strange num.', 'top num.', 'bottom num.', 'colour'],
['dimensionality', 'colourless gluon?', 'neutral photon?']]

func _ready():
	var margin_value = 2
	
	var Shadow = get_node('Box/shadow')
	var X_container = get_node('Box/MarginContainer/X_container')
	var NumberContainer = get_node('Box/MarginContainer/NumberContainer')
	
	Shadow.add_theme_constant_override("offset_top", 2*margin_value)
	Shadow.add_theme_constant_override("offset_left", 2*margin_value)
	Shadow.add_theme_constant_override("offset_right", -margin_value)
	Shadow.add_theme_constant_override("offset_bottom", -margin_value)
	
	X_container.add_theme_constant_override("offset_left", 87)
	
	NumberContainer.get_node('Label').text = ConnectedInteraction.get_node('InfoNumberLabel').text
	NumberContainer.add_theme_constant_override("offset_top", -58)
	NumberContainer.add_theme_constant_override("offset_left", 3)
	
	var mar = get_node('Box/MarginContainer')
	mar.add_theme_constant_override('offset_top', -9)
	
	for i in (TabC.get_children().size()):
		var tab = TabC.get_children()[i]
		tab.add_theme_constant_override("offset_top", -margin_value)
		tab.add_theme_constant_override("offset_left", margin_value)
		tab.add_theme_constant_override("offset_bottom", margin_value)
		
		tab.get_node('ScrollContainer/MarginContainer').add_theme_constant_override('offset_right', -margin_value)
		
		tab.get_node('ScrollContainer').get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_PASS
	
	
		var titles = Row.instantiate()
		
		if i == 0:
			titles.get_node('HBoxContainer/0').text = 'PROPERTY'
			titles.get_node('HBoxContainer/1').text = 'BEFORE'
			titles.get_node('HBoxContainer/2').text = 'AFTER'
			tab.get_node('ScrollContainer/MarginContainer/VBoxContainer').add_child(titles)
		
		elif i == 1:
			titles.get_node('HBoxContainer/0').text = 'PROPERTY'
			titles.get_node('HBoxContainer/1').text = ''
			titles.get_node('HBoxContainer/2').text = ''

	build_table()

func _process(_delta):
	if Input.is_action_just_pressed('click') and hovering and !scroll_hovering:
		if Level.mode == 'editing':
			Level.mode = 'placing'
			placed = false
			start_mouse = get_global_mouse_position() - position

		elif Level.mode == 'deleting':
			ConnectedInteraction.info_showing = false
			queue_free()
	
	if Input.is_action_just_released("click") and !placed:
		placed = true
	
	if !placed:
		position = get_global_mouse_position() - start_mouse
	
	if hovering and Level.mode == 'deleting':
		modulate.a = 0.6
	else:
		modulate.a = 1
	
func build_table():
	for j in range(TabC.get_children().size()):
		Tab = TabC.get_children()[j]
		Scroll = Tab.get_node('ScrollContainer')
		Rows = Scroll.get_node('MarginContainer/VBoxContainer')
		
		if j == 0:
			var name_index = []
			var alternate_colour = true
			Row = load('res://InfoRow.tscn')
			
			name_index.append(1)
			
			for line in ConnectedInteraction.connected:
				for i in range(2, 13):
					if float(line.qns[line.type][i]) != 0.0 and name_index.find(i) == -1:
						name_index.append(i)
						continue
			
			if ConnectedInteraction.has_colour:
				name_index.append(13)
			
			if !old_name_index[j] == name_index:
				for i in range(1, Rows.get_children().size()):
					Rows.get_children()[i].queue_free()

			var data = []
			for i in name_index:
				var row
				if !old_name_index[j] == name_index:
					row = Row.instantiate()
				else:
					row = Rows.get_children()[name_index.find(i) + 1]
				
				if i < 13:
					data = get_quantum_number_data(j, i)
				
				if i == 13:
					data = get_colour_data(j, i)
				
				
				if alternate_colour:
					row.modulate = 'd1bd97'
				alternate_colour = !alternate_colour
				
				if i in ConnectedInteraction.invalid_index:
					row.get_node('HBoxContainer/invalid').visible = true
				for k in range(3):
					row.get_node('HBoxContainer/' + str(k)).text = data[k]
				
				if !old_name_index[j] == name_index:
					Tab.get_node('ScrollContainer/MarginContainer/VBoxContainer').add_child(row)
			
			old_name_index[j] = [name_index][0]
			
		if j == 1:
			var name_index = []
			var alternate_colour = false
			
			Row = load('res://OtherRow.tscn')
			
			name_index = ConnectedInteraction.other_index
			alternate_colour = false
			
			name_index.push_front(0)
			
			if old_name_index[j] != name_index:
				for i in range(Rows.get_children().size()):
					Rows.get_children()[i].queue_free()
			
			var data = []
			for i in name_index:
				var row
				if !old_name_index[j] == name_index:
					row = Row.instantiate()
				else:
					row = Rows.get_children()[name_index.find(i)]

				if i == 0:
					if i in ConnectedInteraction.other_invalid_index:
						data = names[j][i] + ' = ' + str(ConnectedInteraction.dimensionality) + ' ( > 4 )  '
					else:
						data = names[j][i] + ' = ' + str(ConnectedInteraction.dimensionality) + ' ( <= 4 )  '
				
				elif i in ConnectedInteraction.other_invalid_index:
					data = names[j][i] + '    Yes  '
				else:
					data = names[j][i] + '    No  '
			
				if alternate_colour:
					row.modulate = 'd1bd97'
				alternate_colour = !alternate_colour

				if i in ConnectedInteraction.other_invalid_index:
					row.get_node('HBoxContainer/invalid').visible = true
				row.get_node('HBoxContainer/0').text = data
				
				if old_name_index[j] != name_index:
					Tab.get_node('ScrollContainer/MarginContainer/VBoxContainer').add_child(row)
			
			old_name_index[j] = name_index
		
func is_integer(f):
	return is_zero_approx(abs(f) - floor(abs(f)))

func _on_MarginContainer_mouse_entered():
	hovering = true

func _on_MarginContainer_mouse_exited():
	hovering = false

func _on_Scroll_mouse_entered():
	scroll_hovering = true

func _on_Scroll_mouse_exited():
	scroll_hovering = false

func _on_TabContainer_tab_selected(_tab):
	Cursor.button_press()

func _on_TextureButton_pressed():
	Cursor.button_press()
	queue_free()
	ConnectedInteraction.info_showing = false

func is_hovered():
	return hovering
	
func get_quantum_number_data(tab_index, name_index):
	var data = [names[tab_index][name_index], str(ConnectedInteraction.left_sum[name_index]), str(ConnectedInteraction.right_sum[name_index])]

	if !is_integer(ConnectedInteraction.left_sum[name_index]):
		data[1] = str(ConnectedInteraction.left_sum[name_index] * 3) + '/3'
	if !is_integer(ConnectedInteraction.right_sum[name_index]):
		data[2] = str(ConnectedInteraction.right_sum[name_index] * 3) + '/3'
	
	return data

func get_colour_data(tab_index, name_index):
	var left_colour = ConnectedInteraction.left_colour
	var right_colour = ConnectedInteraction.right_colour
	
	return [names[tab_index][name_index], left_colour, right_colour]


func _on_timer_timeout():
	pass # Replace with function body.
