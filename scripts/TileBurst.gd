extends Node2D


func fire(colour: Color) -> void:
	var mat := $Particles.process_material as ParticleProcessMaterial
	mat.color = colour
	$Particles.emitting = true
	await get_tree().create_timer($Particles.lifetime + 0.1).timeout
	if is_instance_valid(self):
		queue_free()
