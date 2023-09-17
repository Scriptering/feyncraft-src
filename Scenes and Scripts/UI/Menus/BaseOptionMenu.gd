class_name BaseOptionMenu
extends TabContainer

signal returned

const MAIN_MENU: int = 0

func _ready() -> void:
	for tab_index in range(get_tab_count()):
		if tab_index == MAIN_MENU:
			continue
		
		get_tab_control(tab_index).return_to_main_menu.connect(return_to_main_menu)

func return_to_main_menu() -> void:
	self.current_tab = MAIN_MENU
	
	emit_signal("returned")

