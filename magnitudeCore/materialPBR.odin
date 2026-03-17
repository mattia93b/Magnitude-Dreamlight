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