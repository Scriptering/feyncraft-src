extends GrabbableControl

signal closed
signal submitted(text: String)

enum Mode {Load, Upload}

@export var pop_up_time: float = 1
@export var mode: Mode = Mode.Load

@onready var Title: Label = $PanelContainer/VBoxContainer/TitleContainer/HBoxContainer/Title
@onready var Text: TextEdit = $PanelContainer/VBoxContainer/PanelContainer/VBoxContainer/PanelContainer/MarginContainer/TextEdit
@onready var PopUp: Label = $PanelContainer/VBoxContainer/PanelContainer/VBoxContainer/PanelContainer/PopUp
@onready var copy: PanelContainer = $PanelContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Copy
@onready var paste: PanelContainer = $PanelContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Paste
@onready var submit: PanelContainer = $PanelContainer/VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/SubmitContainer/Submit

func _ready() -> void:
	super._ready()
	
	$PopUpTimer.wait_time = pop_up_time
	
	match mode:
		Mode.Load:
			Text.editable = true
			Title.text = 'Load'
			copy.hide()
		Mode.Upload:
			Text.editable = false
			Title.text = 'Upload'
			paste.hide()

func _on_text_edit_child_entered_tree(node: Node) -> void:
	if node is ScrollBar:
		node.use_parent_material = true

func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(Text.text)
	
	show_popup("Text Copied!")

func _on_paste_pressed() -> void:
	Text.text = DisplayServer.clipboard_get()

func _on_submit_pressed() -> void:
	submitted.emit(Text.text)

func show_popup(text: String) -> void:
	PopUp.text = text
	PopUp.show()
	$PopUpTimer.start()
	
func _on_pop_up_timer_timeout() -> void:
	PopUp.hide()

func invalid_submission() -> void:
	show_popup("Invalid Upload.")

func _on_close_pressed() -> void:
	closed.emit()

func set_text(new_text: String) -> void:
	Text.text = new_text
