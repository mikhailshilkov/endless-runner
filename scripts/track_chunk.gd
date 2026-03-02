extends Node3D

# Track chunk — a segment of road.
# Movement and despawning is handled by TrackSpawner.
# Scenery is spawned procedurally on _ready.

var _building_colors: Array[Color] = [
	Color(0.75, 0.72, 0.68),
	Color(0.65, 0.62, 0.58),
	Color(0.8, 0.75, 0.65),
	Color(0.6, 0.55, 0.5),
	Color(0.7, 0.65, 0.7),
]

var _tree_trunk_color := Color(0.45, 0.3, 0.15)
var _tree_leaf_colors: Array[Color] = [
	Color(0.2, 0.5, 0.15),
	Color(0.15, 0.45, 0.1),
	Color(0.25, 0.55, 0.2),
]


func _ready() -> void:
	_spawn_scenery()


func _spawn_scenery() -> void:
	var scenery_node: Node3D = $Scenery
	var count := randi_range(3, 6)

	for i in range(count):
		var side := 1.0 if randf() > 0.5 else -1.0
		var x_pos: float = side * randf_range(7.0, 18.0)
		var z_pos: float = randf_range(-18.0, 18.0)

		if randf() < 0.5:
			_add_building(scenery_node, x_pos, z_pos)
		else:
			_add_tree(scenery_node, x_pos, z_pos)


func _add_building(parent: Node3D, x: float, z: float) -> void:
	var w: float = randf_range(1.5, 3.5)
	var h: float = randf_range(2.0, 8.0)
	var d: float = randf_range(1.5, 3.5)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(w, h, d)
	mesh_instance.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _building_colors[randi_range(0, _building_colors.size() - 1)]
	mat.roughness = 0.9
	mesh_instance.set_surface_override_material(0, mat)

	mesh_instance.position = Vector3(x, h * 0.5, z)
	parent.add_child(mesh_instance)


func _add_tree(parent: Node3D, x: float, z: float) -> void:
	var trunk_h: float = randf_range(1.0, 2.0)
	var canopy_r: float = randf_range(0.8, 1.5)

	# Trunk
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.12
	trunk_mesh.bottom_radius = 0.15
	trunk_mesh.height = trunk_h
	trunk.mesh = trunk_mesh
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = _tree_trunk_color
	trunk_mat.roughness = 1.0
	trunk.set_surface_override_material(0, trunk_mat)
	trunk.position = Vector3(x, trunk_h * 0.5, z)
	parent.add_child(trunk)

	# Canopy
	var canopy := MeshInstance3D.new()
	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = canopy_r
	canopy_mesh.height = canopy_r * 1.6
	canopy.mesh = canopy_mesh
	var canopy_mat := StandardMaterial3D.new()
	canopy_mat.albedo_color = _tree_leaf_colors[randi_range(0, _tree_leaf_colors.size() - 1)]
	canopy_mat.roughness = 1.0
	canopy.set_surface_override_material(0, canopy_mat)
	canopy.position = Vector3(x, trunk_h + canopy_r * 0.6, z)
	parent.add_child(canopy)
