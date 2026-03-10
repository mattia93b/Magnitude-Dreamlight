package magnitudeCore

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"


Camera::struct {
    position : linalg.Vector3f32,
    front : linalg.Vector3f32,
    up : linalg.Vector3f32,
    yaw : f32,
    pitch : f32,
    firstMouse : bool,
}


initCamera::proc(renderer: ^Renderer){

    // Camera set up
    renderer.camera.position = linalg.Vector3f32{0, 10, 20};
    renderer.camera.front = linalg.Vector3f32{0, 0, -10};
    renderer.camera.up = linalg.Vector3f32{0, 1, 0};
    renderer.camera.yaw = -90.0;
    renderer.camera.pitch = 0.0;
    renderer.camera.firstMouse = true;
}