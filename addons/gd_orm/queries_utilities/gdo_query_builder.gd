class_name GDOQueryBuilder
extends Node

enum Operation {
	SELECT,
	UPDATE,
	DELETE,
}
const SELECT:Operation = Operation.SELECT
const UPDATE:Operation = Operation.UPDATE
const DELETE:Operation = Operation.DELETE

var _table:String
var _sqlite:SQLite
var _db_set:GDODbSet
var _columns:PackedStringArray = ["*"]

var _query_where:String = ""
var _query_order:String = ""

var _invert_order:bool = false
var _limit:int = 0
var _params:Array = []
var _operation:Operation = SELECT

func _init(table_name:String, sqlite:SQLite, db_set:GDODbSet) -> void:
	_table = table_name
	_sqlite = sqlite
	_db_set = db_set

func _check_column_existence(column:String) -> void:
	if column not in _db_set.get_column_names() and column != "*":
		GDOError.new(
			"column not found",
			"column not found in entity %s GDOPropertyInfos" % _db_set.get_entity_class_name(),
			"_check_column_existence()",
			"make sure %s's GDOPropertyInfo is properly formatted" % column,
		).throw()

func _check_multiple_columns_existence(columns:PackedStringArray) -> void:
	for column:String in columns:
		_check_column_existence(column)

func _get_where_sql() -> String:
	if not _query_where.is_empty():
		return " " + _query_where
	return ""

func _get_order_by_sql() -> String:
	if not _query_order.is_empty():
		return " " + _query_order
	return ""

func _get_limit_sql() -> String:
	if _limit > 0:
		return " " + "LIMIT %s" % _limit
	return ""

func _get_update_statement() -> String:
	return "UPDATE %s SET %s" % [_table, " = ? ,".join(_columns) + " = ?"]

func _get_select_statement() -> String:
	return "SELECT %s FROM %s" % [", ".join(_columns), _table]

func _get_delete_statement() -> String:
	return "DELETE FROM %s" % _table

func _build_sql() -> SQL:
	var sql:String = ""
	match _operation:
		UPDATE:
			sql = _get_update_statement()
		DELETE:
			sql = _get_delete_statement()
		_:
			sql = _get_select_statement()

	sql += _get_where_sql()
	sql += _get_order_by_sql()
	sql += _get_limit_sql()
	return SQL.new(sql, _params)


func where(column:String) -> WhereBuilder:
	_check_column_existence(column)
	return WhereBuilder.new(column, self)

func order_by(column:String, ascending:bool = true) -> GDOQueryBuilder:
	_check_column_existence(column)
	if _query_order.is_empty():
		_query_order = "ORDER BY "
	else:
		_query_order += ", "
	_query_order += "%s %s" % [column, "ASC" if ascending else "DESC"]
	return self

func limit(limit:int) -> GDOQueryBuilder:
	_limit = limit
	return self

func select(columns:PackedStringArray = ["*"]) -> GDOQueryBuilder:
	_check_multiple_columns_existence(columns)
	_operation = SELECT
	_columns = columns
	return self

func update(columns:PackedStringArray) -> UpdateBuilder:
	_check_multiple_columns_existence(columns)
	_operation = UPDATE
	_columns = columns
	return UpdateBuilder.new(self)

func delete() -> GDOQueryBuilder:
	_operation = DELETE
	return self

func invert() -> GDOQueryBuilder:
	if _query_order.is_empty():
		order_by("ROWID", false)
	else:
		if _query_order.containsn("ASC"):
			_query_order = _query_order.replacen("ASC", "DESC")
		elif _query_order.containsn("DESC"):
			_query_order = _query_order.replacen("DESC", "ASC")
		else:
			GDOError.new(
			"error while inverting order",
			"neither \"ASC\" nor \"DESC\" present in _order_query",
			"invert()",
			"make sure to use the fluent api correctly",
		).throw()
	return self

func AND() -> GDOQueryBuilder:
	if _query_where.is_empty():
		GDOError.new(
			"error while adding \"AND\" to the \"where\" clause",
			"\"where\" clause is empty",
			"AND()",
			"use \"AND\" only after at least one \"WHERE\"",
		).throw()
	_query_where += " AND "
	return self

func OR() -> GDOQueryBuilder:
	if _query_where.is_empty():
		GDOError.new(
			"error while adding \"OR\" to the \"WHERE\" clause",
			"\"WHERE\" clause is empty",
			"OR()",
			"use \"OR\" only after at least one \"WHERE\"",
		).throw()
	_query_where += " OR "
	return self

func execute() -> String:
	var query:SQL = _build_sql()
	_sqlite.query_with_bindings(query.sql, query.parameters)
	return _sqlite.error_message

func to_list() -> Array:
	var errors:String = execute()
	if not errors.is_empty() and errors != "not an error":
		GDOError.new(
			"error executing query. sqlite msg: %s" % errors,
			errors,
			"to_list()",
			"properly use the fluent api, probably",
		).throw()
	var results:Array[Dictionary] = _sqlite.query_result_by_reference
	var items:Array
	items.resize(results.size())
	for result:Dictionary in results:
		var instance = _db_set.new_model_instance()
		items.append(instance)
	return items

func first(default = null):
	_limit = 1
	var result:Array = to_list()
	if result.is_empty():
		return default
	return result[0]

func last(default = null):
	_limit = 1
	invert()
	var result:Array = to_list()
	if result.is_empty():
		return default
	return result[0]

class WhereBuilder:
	var _column:String
	var _builder:GDOQueryBuilder

	func _init(column:String, builder:GDOQueryBuilder) -> void:
		_column = column
		_builder = builder

	func equals(value) -> GDOQueryBuilder:
		return _build('=', value)

	func like(value) -> GDOQueryBuilder:
		if not str(value).contains('%'):
			value = '%' + str(value) + '%'
		return _build('LIKE', value)

	func bigger_than(value) -> GDOQueryBuilder:
		return _build('>', value)

	func bigger_or_equals_than(value) -> GDOQueryBuilder:
		return _build('>=', value)

	func lesser_than(value) -> GDOQueryBuilder:
		return _build('<', value)

	func lesser_or_equals_than(value) -> GDOQueryBuilder:
		return _build('<=', value)

	func _build(operator:String, value) -> GDOQueryBuilder:
		if _builder._query_where.is_empty():
			_builder._query_where = "WHERE"
		_builder._where_query += ' %s' % _column
		_builder._where_query += ' %s ?' % operator
		_builder._params.append(value)
		return _builder

class UpdateBuilder:
	var _builder:GDOQueryBuilder

	func _init(builder:GDOQueryBuilder) -> void:
		self._builder = builder

	func set_values(values:Array) -> GDOQueryBuilder:
		_builder._parameters.append_array(values)
		return _builder

class SQL:
	var sql:String
	var parameters:Array
	func _init(sql:String, parameters:Array) -> void:
		self.sql = sql
		self.parameters = parameters
