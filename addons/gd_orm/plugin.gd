@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("GDO", 'res://addons/gd_orm/gd_orm.gd')


func _exit_tree() -> void:
	remove_autoload_singleton("GDO")
