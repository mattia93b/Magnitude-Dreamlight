package magnitudeCore

// logger
import "core:log"
// math
import "core:math/linalg"

MaterialPBR::struct #align(16){
    texture_idx_albedo : u32,
    texture_idx_metallic : u32,
    texture_idx_roughness : u32,
    texture_idx_normal : u32,
}

TextureMaterialPBR::struct {
    texture_albedo : cstring,
    texture_metallic : cstring,
    texture_roughness : cstring,
    texture_normal : cstring,
}

createMaterialPBR::proc(albedo:cstring, metallic:cstring, roughness:cstring, normal:cstring) -> TextureMaterialPBR {

    return TextureMaterialPBR{albedo, metallic, roughness, normal};
}

defaultMaterialPBR::proc() -> TextureMaterialPBR {

    return TextureMaterialPBR{"resources/textures/textureDefault.png", "resources/textures/textureDefault_specular.png", "resources/textures/textureDefault.png", "resources/textures/textureDefault.png"};
}

SR_Aluminum::proc() -> MaterialPBR {
    //return MaterialPBR{base_color = {0.916, 0.923, 0.924, 0.0}, specular_color = {0.989, 0.989, 0.972, 0.0}, specular_roughness = 0, metalness = 1, texture_idx = 0};
    return MaterialPBR{texture_idx_albedo = 0, texture_idx_metallic = 1, texture_idx_roughness = 2, texture_idx_normal = 3};
}

SR_Gold::proc() -> MaterialPBR {
    //return MaterialPBR{base_color = {1.059, 0.773, 0.307, 0.0}, specular_color = {1.001, 0.985, 0.523, 0.0}, specular_roughness = 0, metalness = 1, texture_idx = 0};
    return MaterialPBR{texture_idx_albedo = 0, texture_idx_metallic = 1, texture_idx_roughness = 2, texture_idx_normal = 3};
}

SR_Dark_Wood::proc() -> MaterialPBR {
    return MaterialPBR{texture_idx_albedo = 4, texture_idx_metallic = 5, texture_idx_roughness = 6, texture_idx_normal = 7};
    //return MaterialPBR{base_color = {0.634, 0.532, 0.111, 0.0}, specular_color = {0.0, 0.0, 0.0, 0.0}, specular_roughness = 0.0, metalness = 0, texture_idx = 0};
}