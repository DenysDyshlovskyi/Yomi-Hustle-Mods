class_name EC_CreateCategory
extends EditorProperty

var category_material = preload("res://addons/export_categories/ec_category_material.tres")


func _init():
	set_process(false)


func _process(_delta: float)->void :
	pass


func update_property()->void :
	label = update_label(label)
	
	
	read_only = true
	
	
	material = category_material
	
	
	draw_red = true
	


func update_label(label: String)->String:
	var previous_label = label
	var trimmed_label = previous_label.trim_prefix("C").trim_prefix(" ")
	
	
	var new_label = trimmed_label
	
	
	var prefix = "[ "
	var suffix = " ]"
	
	
	new_label = str(prefix, new_label, suffix)
	
	
	
	return new_label
