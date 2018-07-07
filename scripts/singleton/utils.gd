extends Node

var rotate_forward = Basis().rotated(Vector3(-1, 0, 0), PI / 2.0);

func align_to_normal(transform, normal):
	if (typeof(transform) != TYPE_TRANSFORM):
		return Transform();
	
	transform = transform.looking_at(normal, Vector3(0, 1, 0));
	transform.basis = transform.basis * rotate_forward;
	return transform;
