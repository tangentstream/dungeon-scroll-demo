@tool extends Node3D

@onready var template  : GridMap = $Template
@onready var generated : GridMap = $Generated

# hack to make a "button" in the inspector
@export var generate : bool = false :
	set(v):
		generate = false
		regen_rules()
		copy_template()

const DEFAULT_RULES = '''{
	"floor" : [
		[0.75, "floor"],
		[0.10, "floor-detail"],
		[0.10, "rocks"],
		[0.05, "wall"]
	]
}'''

var parsed_rules : Dictionary
@export_multiline var rewrite_rules : String = DEFAULT_RULES :
	## JSON string containing an object that maps 
	## tile names to lists of (probability, tile name) pairs.
	## i.e., {tilename: [[probability, tilename, ...]}
	set(v):
		rewrite_rules = v
		regen_rules()

func _read():
	regen_rules()
	
func regen_rules():
	if not is_node_ready(): return
	var tmp:Dictionary = JSON.parse_string(rewrite_rules)
	var lib:MeshLibrary = template.mesh_library
	parsed_rules = {}
	for str_key in tmp.keys():
		var int_key = lib.find_item_by_name(str_key)
		var rule = []
		for pair in tmp[str_key]:
			rule.append([pair[0], lib.find_item_by_name(pair[1])])
		parsed_rules[int_key] = rule


func copy_template():
	generated.clear()
	for cell_p in template.get_used_cells():
		var cell_i = template.get_cell_item(cell_p)
		var cell_o = template.get_cell_item_orientation(cell_p)
		if parsed_rules.has(cell_i):
			var x = randf()
			var p = 0.0
			for option in parsed_rules[cell_i]:
				p += option[0]
				if x < p:
					cell_i = option[1]
					break
		generated.set_cell_item(cell_p, cell_i, cell_o)
