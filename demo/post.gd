class_name Post
extends Node

@warning_ignore_start('unused_private_class_variable')
var id:int
var __id_pi := GDOPropertyInfo.new(true)

var content:String
var __content_pi := GDOPropertyInfo.new(false, false, true)

var user_id:int
var __user_id_pi := GDOPropertyInfo.new(false, false, true, false, null, "User.id")

var user:User
