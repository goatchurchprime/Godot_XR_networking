extends Node2D


func _ready():
	var project = ProjectManager.add_project()
	ProjectManager.make_project_active(project)
	$InfiniteCanvas.use_project(project)


