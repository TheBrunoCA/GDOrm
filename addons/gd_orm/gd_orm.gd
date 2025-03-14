extends Node

signal error_ocurred(error:GDOError)

var _db_sets:Array[GDODbSet] = []
var _sqlite:SQLite = SQLite.new()

var drop_all_first:bool = false

func ensure_deleted(delete_sqlite_sequence:bool = false) -> void:
	_sqlite.query("PRAGMA writable_schema = 1;")
	_sqlite.query("DELETE FROM sqlite_master WHERE type IN ('table', 'index', 'trigger');")
	_sqlite.query("PRAGMA writable_schema = 0;")
	if delete_sqlite_sequence:
		_sqlite.query("DELETE FROM sqlite_sequence")
	_sqlite.query("VACUUM")
	_sqlite.query("PRAGMA INTEGRITY_CHECK;")

func ensure_created() -> void:
	for db_set:GDODbSet in _db_sets:
		_sqlite.create_table(db_set.get_entity_class_name(), db_set.get_table_schema())

func add_db_set(db_set:GDODbSet) -> void:
	db_set._sqlite_instance = _sqlite
	_db_sets.append(db_set)

func setup(db_path:String = "res://database", foreign_keys:bool = true,
		verbosity:SQLite.VerbosityLevel = SQLite.QUIET) -> void:
	_sqlite.path = db_path
	_sqlite.foreign_keys = foreign_keys
	_sqlite.verbosity_level = verbosity

func open_connection() -> SQLite:
	_sqlite.open_db()
	return _sqlite

func close_connection() -> bool:
	return _sqlite.close_db()

func begin_transaction() -> void:
	_sqlite.query("BEGIN TRANSACTION;")

func commit() -> void:
	_sqlite.query("COMMIT;")

func rollback() -> void:
	_sqlite.query("ROLLBACK;")
