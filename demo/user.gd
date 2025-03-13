class_name User
extends Node

@warning_ignore_start('unused_private_class_variable')
var id:int
var __id_pi := GDOPropertyInfo.new(true)

var nome:String
var __nome_pi := GDOPropertyInfo.new(false, false, true)

var vector:Vector4
var __vector_pi := GDOPropertyInfo.new()
