extends SceneTree
func _initialize() -> void:
	var malos := 0
	var pila := ["res://juego", "res://biomas", "res://niveles"]
	while pila.size() > 0:
		var d: String = pila.pop_back()
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd") or f.ends_with(".tscn"):
				var r = load(d + "/" + f)
				if r == null:
					print("FALLA ", d, "/", f); malos += 1
		for sub in DirAccess.get_directories_at(d):
			pila.append(d + "/" + sub)
	print("PARSE malos=", malos)
	quit(malos)
