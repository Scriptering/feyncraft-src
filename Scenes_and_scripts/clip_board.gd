extends Node

signal copied()
signal pasted()

func copy(content: String) -> void:
	if OS.get_name() == "Web":
		await _copy_web(content)
	else:
		DisplayServer.clipboard_set(content)
		copied.emit()

func paste() -> String:
	if OS.get_name() == "Web":
		return await _paste_web()
	
	else:
		var pasted_text := DisplayServer.clipboard_get()
		
		if pasted_text == null:
			return ""
		
		pasted.emit()
		return pasted_text

func _copy_web(content: String) -> void:
	content = _clean_content(content)
	
	ConfirmationDialogJsLoader.set_snippet_content(
		true,
		content,
		"",
		"Copy",
		"Copy the text below to share",
		"Accept",
		"Cancel"
	)
	var copy_text: String = await ConfirmationDialogJsLoader.eval_snippet(self)
	
	if copy_text != "":
		copied.emit()

func _paste_web() -> String:
	ConfirmationDialogJsLoader.set_snippet_content(
		false,
		"",
		"Paste text here",
		"Paste",
		"Paste text below to upload",
		"Accept",
		"Cancel"
	)
	
	var pasted_text := await ConfirmationDialogJsLoader.eval_snippet(self)
	pasted.emit()
	return pasted_text

func _clean_content(content: String) -> String:
	return content.replace("\\", "\\\\")
