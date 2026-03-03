package magnitudeCore

// logger
import "core:log"
// math
import "core:math/linalg"

MaterialPBR::struct #align(16){
    base_color : linalg.Vector4f32,
    specular_color : linalg.Vector4f32,
    specular_roughness : f32,
    metalness : f32,
    texture_idx : u32,
	_pad0:f32,
}

SR_Aluminum::proc() -> MaterialPBR {
    return MaterialPBR{base_color = {0.916, 0.923, 0.924, 0.0}, specular_color = {0.989, 0.989, 0.972, 0.0}, specular_roughness = 0, metalness = 1, texture_idx = 0};
}

SR_Gold::proc() -> MaterialPBR {
    return MaterialPBR{base_color = {1.059, 0.773, 0.307, 0.0}, specular_color = {1.001, 0.985, 0.523, 0.0}, specular_roughness = 0, metalness = 1, texture_idx = 1};
}

SR_Banana::proc() -> MaterialPBR {
    return MaterialPBR{base_color = {0.634, 0.532, 0.111, 0.0}, specular_color = {0.0, 0.0, 0.0, 0.0}, specular_roughness = 0.0, metalness = 0, texture_idx = 0};
}