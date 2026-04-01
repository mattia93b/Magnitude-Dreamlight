package magnitudeCore

import "core:prof/spall"
// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"

GameObject::struct{
    id              : u32,
    name            : string,
    tag             : string,
    position        : linalg.Vector3f32,
    rotation        : linalg.Vector3f32,
    scale           : linalg.Vector3f32,
    velocity        : linalg.Vector3f32,
    is_static       : bool,
    has_gravity     : bool,
    is_ground       : bool,
    renderableID    : u32,
}


setGameObjectPosition::proc(x:f32, y:f32, z:f32, gameObject:^GameObject){
    // POSITION
    gameObject.position = {x, y, z};
    // MODEL MATRIX
    //gameObject.modelMatrix = linalg.matrix4_translate_f32({x, y, z});
}

setGameObjectVelocity::proc(Vx:f32, Vy:f32, Vz:f32, renderable:^Renderable){
    // VELOCITY
    renderable.velocity = {Vx, Vy, Vz};
}






