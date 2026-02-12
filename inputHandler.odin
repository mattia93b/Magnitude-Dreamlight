package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"

mouseKeyboardInput :: struct {

    keys: map[sdl.Scancode]bool,
    mousePosition: linalg.Vector2f32,
    prevMousePostion: linalg.Vector2f32,
    first:bool,
    mouseDown:bool,
}


inputHandler :: proc(state: ^mouseKeyboardInput) -> bool {

    state.mousePosition.x = 0.0;
    state.mousePosition.y = 0.0;

    event: sdl.Event;
    for sdl.PollEvent(&event) {
        #partial switch event.type {
            case .QUIT:
                return false;
            case .KEY_DOWN:
                state.keys[event.key.scancode] = true;
            case .KEY_UP:
                state.keys[event.key.scancode] = false;
            case .MOUSE_BUTTON_DOWN:
                state.mouseDown = true;
                log.info("Mouse Presed");
            case .MOUSE_BUTTON_UP:
                state.first = true;
                state.mouseDown = false;
                log.info("Mouse Release");
        }
    }

    return true;
}


updateCamera :: proc(mRenderer: ^Renderer, state: ^mouseKeyboardInput, dt: f32){

    cam := &mRenderer.rCamera;
    speed : f32 = 10 * dt;
    sens : f32 = 0.1;

    if state.mouseDown{

        flag := sdl.GetMouseState(&state.mousePosition.x, &state.mousePosition.y)

        if state.first{
            state.prevMousePostion.x = state.mousePosition.x;
            state.prevMousePostion.y = state.mousePosition.y;
            state.first = false;
        }

        xoffset := state.mousePosition.x - state.prevMousePostion.x;
        yoffset := state.prevMousePostion.y - state.mousePosition.y;

        xoffset *= sens;
        yoffset *= sens;

        cam.yaw += xoffset;

        cam.pitch += yoffset;
        cam.pitch = linalg.clamp(cam.pitch, -89.0, 89.0);

        cos_p := linalg.cos(linalg.to_radians(cam.pitch));     
        sin_p := linalg.sin(linalg.to_radians(cam.pitch));
        cos_y := linalg.cos(linalg.to_radians(cam.yaw));
        sin_y := linalg.sin(linalg.to_radians(cam.yaw));

        cam.front = linalg.vector_normalize(linalg.Vector3f32{cos_y * cos_p, sin_p, sin_y * cos_p});

        state.prevMousePostion.x = state.mousePosition.x;
        state.prevMousePostion.y = state.mousePosition.y;

    }

    if state.keys[.W] do cam.position += cam.front * speed;
    if state.keys[.S] do cam.position -= cam.front * speed;
    if state.keys[.D] do cam.position += linalg.cross(cam.front, cam.up)  * speed;
    if state.keys[.A] do cam.position -= linalg.cross(cam.front, cam.up) * speed;
    if state.keys[.E] do cam.position += cam.up * speed;
    if state.keys[.Q] do cam.position -= cam.up * speed;
    
    if state.keys[.DOWN] do mRenderer.lightInfo.lightPosition.z += speed;
    if state.keys[.UP] do mRenderer.lightInfo.lightPosition.z -= speed;
    if state.keys[.RIGHT] do mRenderer.lightInfo.lightPosition.x += speed;
    if state.keys[.LEFT] do mRenderer.lightInfo.lightPosition.x -= speed;
    if state.keys[.PAGEUP] do mRenderer.lightInfo.lightPosition.y += speed;
    if state.keys[.PAGEDOWN] do mRenderer.lightInfo.lightPosition.y -= speed;

}