class_name AddScene
extends Resource

enum Type {GUI, DIMENSION_3}

var scene: String;
var dynamic_loading: bool;
var type: Type;
var offset: Vector3 = Vector3.ZERO;
