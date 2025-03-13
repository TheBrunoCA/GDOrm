class_name GDOError
extends Node

var error:String
var cause:String
var where:String
var fix:String

func _init(error:String, cause:String ,where:String, fix:String) -> void:
	self.error = error
	self.cause = cause
	self.where = where
	self.fix = fix

func emit() -> void:
	GDO.error_ocurred.emit(self)

func throw() -> void:
	emit()
	push_error(_to_string())
	assert(false, _to_string())

func _to_string() -> String:
	return "Error: %s\nWhere: %s\nCause: %s\nFix: %s" % [error, cause, where, fix]
