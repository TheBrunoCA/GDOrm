class_name GDODbSet
extends Node

#region Private constants
const _PROPERTY_INFO_TEMPLATE:String = "__%s_pi"
const _DATA_TYPE_INT:StringName = "int"
const _DATA_TYPE_REAL:StringName = "real"
const _DATA_TYPE_TEXT:StringName = "text"
const _DATA_TYPE_BLOB:StringName = "blob"
#endregion

#region Private properties
var _entity_model
var _schema_cache:Dictionary[String, Dictionary]
var _sqlite_instance:SQLite
var _property_info_list_cache:Dictionary[String, GDOPropertyInfo]
var _property_list_cache:PackedStringArray
var _column_names_list_cache:PackedStringArray
var _column_to_property:Dictionary[String, String]
#endregion

#region Private inner functions
func __prop_list_filter_usage(dict:Dictionary) -> bool:
	return (dict["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE > 0) and (not dict["name"].begins_with("_"))
func __prop_list_get_name(dict:Dictionary) -> String:
	return dict["name"]
func __get_property_data_type(prop_name:StringName) -> String:
	var type:int = typeof(_entity_model.get(prop_name))
	match type:
		TYPE_BOOL:
			return _DATA_TYPE_INT
		TYPE_INT:
			return _DATA_TYPE_INT
		TYPE_FLOAT:
			return _DATA_TYPE_REAL
		TYPE_STRING:
			return _DATA_TYPE_TEXT
		TYPE_STRING_NAME:
			return _DATA_TYPE_TEXT
		TYPE_OBJECT:
			return _DATA_TYPE_BLOB
		_:
			return _DATA_TYPE_TEXT
func __get_property_getter_for_data_type(data_type:StringName) -> Callable:
	match data_type:
		_DATA_TYPE_BLOB:
			return bytes_to_var_with_objects
		_DATA_TYPE_TEXT:
			return str_to_var
		_:
			return func(x): return x
	return func():pass
func __get_property_setter_for_data_type(data_type:StringName) -> Callable:
	match data_type:
		_DATA_TYPE_BLOB:
			return var_to_bytes_with_objects
		_DATA_TYPE_TEXT:
			return var_to_str
		_:
			return func(x): return x
	return func():pass
#endregion

#region Private overrides
func _init(entity_model) -> void:
	_entity_model = entity_model
	_load_properties_info_cache()
	_load_columns_to_properties()
	_build_schema()
#endregion

#region Private methods
func _get_valid_gdo_property_info(prop_name:String, prop_info:GDOPropertyInfo) -> GDOPropertyInfo:
	prop_info.property_name = prop_name
	prop_info.data_type = __get_property_data_type(prop_name)
	if prop_info.auto_increment and (prop_info.data_type.to_lower() != _DATA_TYPE_INT or not prop_info.primary_key):
		GDOError.new(
			"auto_increment must be int and primary key",
			"auto_increment is not int and/or not primary key",
			"_get_valid_gdo_property_info()",
			"remove the auto_increment or put it in an int primary key property",
		).throw()
	prop_info.getter = __get_property_getter_for_data_type(prop_info.data_type)
	prop_info.setter = __get_property_setter_for_data_type(prop_info.data_type)
	if prop_info.column_name.is_empty():
		prop_info.column_name = prop_name
	return prop_info
func _load_properties_info_cache() -> void:
	var prop_list:Array = get_properties()

	var temp_prop_info_list:Array[GDOPropertyInfo] = []

	for prop:String in prop_list:
		var prop_info_name:String = _PROPERTY_INFO_TEMPLATE % prop
		if prop_info_name not in _entity_model:
			continue
			## Commented to allow for properties to be model-exclusive
			#GDOError.new(
				#"GDOPropertyInfo not found.",
				#"GDOPropertyInfo of %s is missing from entity %s" % [ prop, _entity_model.get_entity_name() ],
				#"_load_properties_info_cache()",
				#"Make sure the GDOPropertyInfo of %s exists with the following format: %s" % [prop, prop_info_name]
			#).throw()
		var prop_info:GDOPropertyInfo = _entity_model.get(prop_info_name)
		_property_info_list_cache.set(prop, _get_valid_gdo_property_info(prop, prop_info))
func _load_columns_to_properties() -> void:
	for prop:String in _property_info_list_cache:
		var prop_info:GDOPropertyInfo = _property_info_list_cache[prop]
		_column_to_property[prop_info.column_name] = prop_info.property_name
func _build_schema() -> void:
	var schema:Dictionary[String, Dictionary] = {}
	for prop_name:String in get_property_info_list():
		var prop_info:GDOPropertyInfo = get_property_info(prop_name)
		var column:Dictionary = {}
		column["data_type"] = prop_info.data_type
		if prop_info.not_null:
			column["not_null"] = prop_info.not_null
		if prop_info.unique:
			column["unique"] = prop_info.unique
		if prop_info.primary_key:
			column["primary_key"] = prop_info.primary_key
		if prop_info.auto_increment:
			column["auto_increment"] = prop_info.auto_increment
		if not prop_info.foreign_key.is_empty():
			column["foreign_key"] = prop_info.foreign_key
		if prop_info.default != null:
			column["default"] = prop_info.default

		schema[prop_info.column_name] = column
	_schema_cache = schema
#endregion

#region Public utility methods
func get_table_schema() -> Dictionary[String, Dictionary]:
	return _schema_cache
func get_column_names() -> PackedStringArray:
	if _column_names_list_cache.is_empty():
		_column_names_list_cache.resize(get_property_info_list().size())
		for prop:String in get_property_info_list():
			var prop_info:GDOPropertyInfo = get_property_info(prop)
			_column_names_list_cache.append(prop_info.column_name)
	return _column_names_list_cache
func get_properties() -> PackedStringArray:
	if _property_list_cache.is_empty():
		_property_list_cache = PackedStringArray(_entity_model.get_property_list() \
			.filter(__prop_list_filter_usage).map(__prop_list_get_name))
	return _property_list_cache
func get_property_info(property_name:String) -> GDOPropertyInfo:
	if property_name not in _property_info_list_cache.keys():
		GDOError.new(
			"Failed to get GDOPropertyInfo",
			"GDOPropertyInfo of the property %s probably does not exist or is malformatted." % property_name,
			"get_property_info()",
			"Make sure the property %s has an GDOPropertyInfo with the correct syntax",
		).throw()
	return _property_info_list_cache[property_name]
func get_property_info_list() -> Dictionary[String, GDOPropertyInfo]:
	return _property_info_list_cache
func get_property_from_column(column_name:String) -> String:
	if column_name not in _column_to_property.keys():
		GDOError.new(
			"Failed to get property_name from column_name",
			"column_name not found in entity's %s GDOPropertyInfo's." % _entity_model,
			"get_property_from_column()",
			"Make sure the property %s has an GDOPropertyInfo with the correct syntax",
		).throw()
	return _column_to_property[column_name]
func get_column_from_property(property_name:String) -> String:
	if property_name not in _property_info_list_cache.keys():
		GDOError.new(
			"Failed to get column_name from property_name",
			"property_name not found in entity's %s GDOPropertyInfo's." % _entity_model,
			"get_column_from_property()",
			"Make sure the property %s has an GDOPropertyInfo with the correct syntax",
		).throw()
	return _property_info_list_cache[property_name].column_name
func get_entity_class_name() -> String:
	return _entity_model.get_script().get_global_name()
func new_model_instance():
	return _entity_model.get_script().new()
func from_row(row:Dictionary):
	var instance = new_model_instance()
	for key in row:
		var prop_name:String = get_property_from_column(key)
		if prop_name not in instance:
			GDOError.new(
				"Property not found in entity",
				"Property %s not found in entity %s" % [prop_name, _entity_model],
				"from_row()",
				"Make sure %s exists in %s and that the syntax is correct" % [prop_name, _entity_model],
			).throw()
		var value := get_property_info(prop_name).getter.call(row[key])
		instance.set(prop_name, value)
	return instance
func to_row(item) -> Dictionary:
	var row:Dictionary = {}
	for prop:String in _property_info_list_cache:
		var prop_info:GDOPropertyInfo = _property_info_list_cache[prop]
		if prop_info.auto_increment:
			continue
		if prop_info.primary_key and prop_info.data_type == _DATA_TYPE_INT:
			continue
		row[prop_info.column_name] = prop_info.setter.call(item.get(prop_info.property_name))
	return row
#endregion

func query() -> GDOQueryBuilder:
	return GDOQueryBuilder.new(get_entity_class_name(), _sqlite_instance, self)

func insert(item:Object) -> int:
	return query().insert(item)

func insert_many(items_array:Array[Object]) -> void:
	for item:Object in items_array:
		insert(item)

func update(columns:PackedStringArray) -> GDOQueryBuilder.UpdateBuilder:
	return query().update(columns)

func delete() -> GDOQueryBuilder:
	return query().delete()

func where(column:String) -> GDOQueryBuilder.WhereBuilder:
	return query().where(column)

func order_by(column:String, ascending:bool = true) -> GDOQueryBuilder:
	return query().order_by(column, ascending)

func invert() -> GDOQueryBuilder:
	return query().invert()

func to_list() -> Array:
	return query().to_list()

func first():
	return query().first()

func last():
	return query().last()
