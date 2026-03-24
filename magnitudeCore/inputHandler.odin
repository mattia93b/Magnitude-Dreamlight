package magnitudeCore

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
    // 
    mouseDeltaX  : f32,
    mouseDeltaY  : f32,
    moveForward  : bool,
    moveBackward : bool,
    moveLeft     : bool,
    moveRight    : bool,
}

initInputHandler::proc(renderer: ^Renderer){
    // Input handler definition
    renderer.input = mouseKeyboardInput{}
    renderer.input.mouseDown = false;
    renderer.input.first = true;
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
            case .MOUSE_BUTTON_UP:
                state.first = true;
                state.mouseDown = false;
        }
    }

    return true;
}


updateCamera :: proc(mRenderer: ^Renderer, state: ^mouseKeyboardInput, dt: f32){

    cam := &mRenderer.camera;
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
    
    if state.keys[.DOWN] do mRenderer.scene.lightInfo.lightPosition.z += speed;
    if state.keys[.UP] do mRenderer.scene.lightInfo.lightPosition.z -= speed;
    if state.keys[.RIGHT] do mRenderer.scene.lightInfo.lightPosition.x += speed;
    if state.keys[.LEFT] do mRenderer.scene.lightInfo.lightPosition.x -= speed;
    if state.keys[.PAGEUP] do mRenderer.scene.lightInfo.lightPosition.y += speed;
    if state.keys[.PAGEDOWN] do mRenderer.scene.lightInfo.lightPosition.y -= speed;
}


updateThirdPersonCamera :: proc(player: ^Player, dataManager: ^DataManager, input: ^mouseKeyboardInput, dt: f32) {

    mx, my : f32
    flag2 := sdl.GetRelativeMouseState(&mx, &my)
    input.mouseDeltaX = mx
    input.mouseDeltaY = -my

    input.moveForward  = sdl.GetKeyboardState(nil)[sdl.Scancode.W]
    input.moveBackward = sdl.GetKeyboardState(nil)[sdl.Scancode.S]
    input.moveLeft     = sdl.GetKeyboardState(nil)[sdl.Scancode.A]
    input.moveRight    = sdl.GetKeyboardState(nil)[sdl.Scancode.D]

    sensitivity :f32= 0.15
    player.yaw   += input.mouseDeltaX * sensitivity
    player.pitch -= input.mouseDeltaY * sensitivity
    player.pitch  = clamp(player.pitch, 5.0, 80.0)
    r := getRenderableObject(dataManager, player.renderableID)
    pivot := r.position
    yawRad   := linalg.to_radians(player.yaw)
    pitchRad := linalg.to_radians(player.pitch)

    camOffset := linalg.Vector3f32{
        player.armLength * linalg.cos(pitchRad) * linalg.sin(yawRad),
        player.armLength * linalg.sin(pitchRad),
        player.armLength * linalg.cos(pitchRad) * linalg.cos(yawRad),
    }

    renderer := &dataManager.renderer
    renderer.camera.position = pivot + camOffset
    renderer.camera.front    = linalg.normalize(pivot - renderer.camera.position)
    renderer.camera.up       = {0, 1, 0}
}


updatePlayer :: proc(player: ^Player, dataManager: ^DataManager, input: ^mouseKeyboardInput, dt: f32) {

    r := getRenderableObject(dataManager, player.renderableID)

    yawRad := linalg.to_radians(player.yaw)
    forward := linalg.Vector3f32{-linalg.sin(yawRad), 0, -linalg.cos(yawRad)}
    right   := linalg.Vector3f32{ linalg.cos(yawRad), 0, -linalg.sin(yawRad)}

    move := linalg.Vector3f32{0, 0, 0}
    if input.moveForward  do move += forward
    if input.moveBackward do move -= forward
    if input.moveRight    do move += right
    if input.moveLeft     do move -= right

    if linalg.length(move) > 0 {
        move = linalg.normalize(move)
    }

    r.position += move * player.speed * dt

    r.position.y = 5
    r.modelMatrix = linalg.matrix4_translate_f32(r.position)
}