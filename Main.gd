extends Node

onready var fd = $CanvasLayer/FileDialog
onready var console_log = $CanvasLayer/RichTextLabel

var records = []
var processed = []
var index = 0
var dupes = 0
var total_dupes = 0

var processing = false
var time_elpased = 0
var time_delay = 0.0000001
var console_process = false
var console_timer = 0
var time_passed = 0


var dir_path 

func _ready():
	dir_path = OS.get_executable_path()
#	open_explorer(dir_path)
	
func open_explorer(path):
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.mode =FileDialog.MODE_OPEN_DIR
	
	fd.set_filters(PoolStringArray(["*.gd ; GDScript Files"]))
	fd.set_current_path(path)
	fd.popup_centered(Vector2(400,400))

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_home"):
		open_explorer(fd.current_dir)
	
	if processing:
		console_timer+= delta
		if console_timer >= 1:
			if !console_process:
				console_log.text = console_log.text + "\n" + "Processing duplicates"
				print(console_timer)
				console_process = true
		
		if console_process:
			time_passed += delta
			time_elpased += delta
			if time_elpased >= time_delay:
				if index<records.size():
					if index==0:
						processed.append(records[index])
					else:	
						for n in processed:
							if records[index].id != n.id:
								pass
							else:
								dupes += 1
						if dupes == 0:
							processed.append(records[index])
							
#							print("processed: " + " id: " + String(records[index].id))
						else:
#							print("found duplicate: " + String(records[index]))
							dupes = 0
							total_dupes += 1
					console_log.text = "Files indexed: "+String(records.size()) +"\n" + "Processing duplicates" +"\n" +""+"processed: " +String(index+1) +"\n" +"dupes: " + String(total_dupes) + "\n" + "Estimated time remaining: " + String(stepify(((records.size()/((index+1)/(time_passed)) )- (time_passed)),0.10)) + " s"
					index += 1
					time_elpased = 0
				else:
					print("processing finished")
					console_log.text = console_log.text + "\n" + "processing_finished"
					save_processed_data()
					processing = false				

func save_processed_data():
	var file = File.new()
	var file_path = String(fd.current_path) + "RECORDS.json"
	file.open(file_path, File.WRITE)
	file.store_string(to_json(processed))
	file.close()

func _on_FileDialog_confirmed():
	get_dir_contents(fd.current_dir)
	

func get_dir_contents(rootPath: String) -> Array:
	var files = []
	var directories = []
	var dir = Directory.new()

	if dir.open(rootPath) == OK:
		dir.list_dir_begin(true, false)
		_add_dir_contents(dir, files, directories)
		print(rootPath)
	else:
		push_error("An error occurred when trying to access the path.")

	print(records.size())
	console_log.text = "Files indexed: "+String(records.size())
	if processing == false:
		processing = true
	
	return [files, directories]

func _add_dir_contents(dir: Directory, files: Array, directories: Array):
	var file_name = dir.get_next()
	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name
		if dir.current_is_dir():
#			print("Found directory: %s" % path)
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			directories.append(path)
			_add_dir_contents(subDir, files, directories)

		else:
#			print("Found file: %s" % path)
			files.append(path)

			var format = {
				"id" : file_name.get_basename(),
				 "n" : file_name,
			}
			
			records.append(format)

		file_name = dir.get_next()

	dir.list_dir_end()

func _on_Button_button_up():
	records.clear()
	open_explorer(fd.current_path)
	


func _on_Button2_button_up():
	processing = false
