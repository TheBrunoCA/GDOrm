class_name GDOPropertyInfo
extends Node

var property_name:String
var data_type:String
var column_name:String
var primary_key:bool
var auto_increment:bool
var not_null:bool
var unique:bool
var default:Variant
var getter:Callable
var setter:Callable
var foreign_key:String

func _init(
	primary_key:bool = false,
	auto_increment:bool = false,
	not_null:bool = false,
	unique:bool = false,
	default:Variant = null,
	foreign_key:StringName = "",
	column_name:StringName = ""
) -> void:
	self.column_name = column_name
	self.primary_key = primary_key
	self.auto_increment = auto_increment
	self.not_null = not_null
	self.unique = unique
	self.default = default
	self.foreign_key = foreign_key

#region _to_string()

func _to_string() -> String:
	return "column_name: %s,
data_type: %s,
primary_key: %s,
auto_increment: %s,
not_null: %s,
unique: %s,
default: %s,
getter: %s,
setter: %s,
foreign_key: %s
" % [
	column_name,
	data_type,
	primary_key,
	auto_increment,
	not_null,
	unique,
	default,
	getter,
	setter,
	foreign_key,
]
#endregion
