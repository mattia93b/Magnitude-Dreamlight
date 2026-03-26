package magnitudeCore

import "core:log"
import "core:os"
import "core:math/linalg"
import "core:encoding/json"

// -----------------------------------------------------------------------
// Load result: returns the Player if the JSON defines one
// -----------------------------------------------------------------------
LevelLoadResult :: struct {
    player     : Player,
    has_player : bool,
}

// -----------------------------------------------------------------------
// loadLevel
//
// Reads a JSON file produced by Magnitude Editor and populates the DataManager
// with materials, objects, lights and (optionally) the player.
//
// Typical usage in main.odin:
//
//   result, ok := magnitudeCore.loadLevel(&dataManager, "levels/my_level.json")
//   if !ok { /* handle error */ }
//   player : magnitudeCore.Player
//   if result.has_player {
//       player = result.player
//   } else {
//       player = magnitudeCore.playerInit(&dataManager, 0, 10, -10, defaultMat)
//   }
//
// -----------------------------------------------------------------------
loadLevel :: proc(dataManager: ^DataManager, path: string) -> (result: LevelLoadResult, ok: bool) {

    // --- Read file ---
    raw_data, file_ok := os.read_entire_file(path)
    if !file_ok {
        log.errorf("[LevelLoader] Cannot read file: %s", path)
        return result, false
    }
    defer delete(raw_data)

    // --- Parse JSON ---
    value, parse_err := json.parse(raw_data)
    if parse_err != .None {
        log.errorf("[LevelLoader] JSON parse error (%v) in: %s", parse_err, path)
        return result, false
    }
    defer json.destroy_value(value)

    root, is_obj := value.(json.Object)
    if !is_obj {
        log.error("[LevelLoader] Root JSON value is not an object")
        return result, false
    }

    // ----------------------------------------------------------------
    // 1. Materials
    //    Builds a map  json_material_id (int) → engine_material_id (u32)
    // ----------------------------------------------------------------
    material_id_map := make(map[int]u32, allocator = context.temp_allocator)

    if mats_val, mats_found := root["materials"]; mats_found {
        if mats_arr, is_arr := mats_val.(json.Array); is_arr {
            for mat_val in mats_arr {
                mat_obj, mat_is_obj := mat_val.(json.Object)
                if !mat_is_obj do continue

                json_id  := int(_json_int(mat_obj, "id", 0))
                albedo   := _json_str(mat_obj, "albedo",    "resources/textures/textureDefault.png")
                metallic := _json_str(mat_obj, "metallic",  "resources/textures/textureDefault_specular.png")
                roughness:= _json_str(mat_obj, "roughness", "resources/textures/textureDefault_specular.png")
                normal   := _json_str(mat_obj, "normal",    "resources/textures/textureDefault.png")
                ao       := _json_str(mat_obj, "ao",        "resources/textures/textureDefault.png")

                // Allocate each path as a heap-allocated null-terminated cstring.
                mat_id := createMaterialInScene(
                    dataManager,
                    _str_to_cstr(albedo),
                    _str_to_cstr(metallic),
                    _str_to_cstr(roughness),
                    _str_to_cstr(normal),
                    _str_to_cstr(ao),
                )
                material_id_map[json_id] = mat_id
                log.infof("[LevelLoader] Material %d loaded → engine id %d", json_id, mat_id)
            }
        }
    }

    // If the JSON defines no materials, create a safety default at slot 0
    if len(material_id_map) == 0 {
        default_id := createMaterialInScene(
            dataManager,
            "resources/textures/textureDefault.png",
            "resources/textures/textureDefault_specular.png",
            "resources/textures/textureDefault_specular.png",
            "resources/textures/textureDefault.png",
            "resources/textures/textureDefault.png",
        )
        material_id_map[0] = default_id
        log.warn("[LevelLoader] No materials in JSON — using engine default material at slot 0")
    }

    // Helper to resolve a JSON material_id to the engine id
    resolve_mat :: proc(m: map[int]u32, json_id: int) -> u32 {
        if id, found := m[json_id]; found do return id
        return 0
    }

    // ----------------------------------------------------------------
    // 2. Objects (cube and sphere)
    // ----------------------------------------------------------------
    if objs_val, objs_found := root["objects"]; objs_found {
        if objs_arr, is_arr := objs_val.(json.Array); is_arr {
            for obj_val in objs_arr {
                obj, obj_is_obj := obj_val.(json.Object)
                if !obj_is_obj do continue

                obj_type    := _json_str(obj, "type", "cube")
                pos         := _json_vec3(obj, "position")
                vel         := _json_vec3(obj, "velocity")
                is_static   := _json_bool(obj, "is_static",   true)
                is_ground   := _json_bool(obj, "is_ground",   false)
                has_gravity := _json_bool(obj, "has_gravity",  false)
                mat_json_id := int(_json_int(obj, "material_id", 0))
                mat_id      := resolve_mat(material_id_map, mat_json_id)

                switch obj_type {
                case "cube":
                    w : f32 = 1.0
                    h : f32 = 1.0
                    if size_val, size_found := obj["size"]; size_found {
                        if size_obj, size_is_obj := size_val.(json.Object); size_is_obj {
                            w = f32(_json_float(size_obj, "width",  1.0))
                            h = f32(_json_float(size_obj, "height", 1.0))
                        }
                    }
                    id := createCube(dataManager, pos.x, pos.y, pos.z, w, h,
                        mat_id, vel, is_static, is_ground, has_gravity)
                    log.infof("[LevelLoader] Cube '%s' → id %d", _json_str(obj, "name", "?"), id)

                case "sphere":
                    radius       := _json_float(obj, "radius",       1.0)
                    stack_count  := int(_json_int(obj, "stack_count",  25))
                    sector_count := int(_json_int(obj, "sector_count", 25))
                    id := createSphere(dataManager, pos.x, pos.y, pos.z,
                        radius, stack_count, sector_count,
                        mat_id, vel, is_static, has_gravity)
                    log.infof("[LevelLoader] Sphere '%s' → id %d", _json_str(obj, "name", "?"), id)

                case:
                    log.warnf("[LevelLoader] Unknown object type '%s', skipping", obj_type)
                }
            }
        }
    }

    // ----------------------------------------------------------------
    // 3. Lights
    // ----------------------------------------------------------------
    if lights_val, lights_found := root["lights"]; lights_found {
        if lights_arr, is_arr := lights_val.(json.Array); is_arr {
            for light_val in lights_arr {
                light_obj, light_is_obj := light_val.(json.Object)
                if !light_is_obj do continue
                pos       := _json_vec3(light_obj, "position")
                color_r   := f32(_json_float(light_obj, "color_r",   1.0))
                color_g   := f32(_json_float(light_obj, "color_g",   1.0))
                color_b   := f32(_json_float(light_obj, "color_b",   1.0))
                intensity := f32(_json_float(light_obj, "intensity", 1000.0))
                color     := linalg.Vector4f32{color_r, color_g, color_b, 1.0}
                id        := addLightToScene(dataManager, pos, color, intensity)
                log.infof("[LevelLoader] Light '%s' → id %d (color %.2f,%.2f,%.2f intensity %.1f)",
                    _json_str(light_obj, "name", "?"), id, color_r, color_g, color_b, intensity)
            }
        }
    }

    // ----------------------------------------------------------------
    // 4. Player (optional)
    // ----------------------------------------------------------------
    if player_val, player_found := root["player"]; player_found {
        if player_obj, player_is_obj := player_val.(json.Object); player_is_obj {
            pos         := _json_vec3(player_obj, "position")
            mat_json_id := int(_json_int(player_obj, "material_id", 0))
            mat_id      := resolve_mat(material_id_map, mat_json_id)
            result.player     = playerInit(dataManager, pos.x, pos.y, pos.z, mat_id)
            result.has_player = true
            log.infof("[LevelLoader] Player loaded at (%.2f, %.2f, %.2f)", pos.x, pos.y, pos.z)
        }
    }

    log.infof("[LevelLoader] Level '%s' loaded successfully", path)
    return result, true
}


// -----------------------------------------------------------------------
// Internal helpers for safely navigating a json.Object
// -----------------------------------------------------------------------

_json_str :: proc(obj: json.Object, key: string, default_val: string) -> string {
    val, found := obj[key]
    if !found do return default_val
    str, is_str := val.(string)
    if !is_str do return default_val
    return str
}

_json_float :: proc(obj: json.Object, key: string, default_val: f64) -> f64 {
    val, found := obj[key]
    if !found do return default_val
    if f, ok := val.(json.Float);   ok do return f
    if i, ok := val.(json.Integer); ok do return f64(i)
    return default_val
}

_json_int :: proc(obj: json.Object, key: string, default_val: i64) -> i64 {
    val, found := obj[key]
    if !found do return default_val
    if i, ok := val.(json.Integer); ok do return i
    if f, ok := val.(json.Float);   ok do return i64(f)
    return default_val
}

_json_bool :: proc(obj: json.Object, key: string, default_val: bool) -> bool {
    val, found := obj[key]
    if !found do return default_val
    b, is_bool := val.(bool)
    if !is_bool do return default_val
    return b
}

// Copies an Odin string into a heap-allocated null-terminated buffer and
// returns it as a cstring. Avoids any allocator ambiguity.
_str_to_cstr :: proc(s: string) -> cstring {
    n   := len(s)
    buf := make([]u8, n + 1)   // heap allocator, never freed
    copy(buf[:n], transmute([]u8)s)
    buf[n] = 0
    return cstring(raw_data(buf))
}

// Reads a sub-object {"x":..., "y":..., "z":...} as a Vector3f32
_json_vec3 :: proc(obj: json.Object, key: string) -> linalg.Vector3f32 {
    val, found := obj[key]
    if !found do return {}
    vec_obj, is_obj := val.(json.Object)
    if !is_obj do return {}
    return linalg.Vector3f32{
        f32(_json_float(vec_obj, "x", 0)),
        f32(_json_float(vec_obj, "y", 0)),
        f32(_json_float(vec_obj, "z", 0)),
    }
}
