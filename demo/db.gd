extends Node

var users := GDODbSet.new(User.new())
var posts := GDODbSet.new(Post.new())
var comments := GDODbSet.new(Comment.new())

func _ready() -> void:
	GDO.add_db_set(users)
	GDO.add_db_set(posts)
	GDO.add_db_set(comments)

	GDO.setup()
	GDO.open_connection()
	GDO.ensure_deleted()
	GDO.ensure_created()

	mock_data()

func mock_data() -> void:
	var user := User.new()
	user.nome = "Bruno Correia Almagro"
	user.vector = Vector4(0,1,2,3)
	user.id = users.insert(user)

	var user2 := User.new()
	user2.nome = "Cristiano Souza"
	user2.vector = Vector4(0,1,2,3)
	user2.id = users.insert(user2)

	var post := Post.new()
	post.content = "Random post of Bruno"
	post.user_id = user.id
	post.id = posts.insert(post)

	var comment := Comment.new()
	comment.content = "What a shit post"
	comment.post_id = post.id
	comment.user_id = user.id
	comment.id = comments.insert(comment)
