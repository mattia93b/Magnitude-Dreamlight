package magnitudeCore

import "core:math/linalg"

Player::struct{
    renderableID    : u32,
    speed           : f32,
    yaw             : f32,
    pitch           : f32,
    armLength       : f32,
    armHeight       : f32,
    verticalVelocity : f32,
    isGrounded       : bool,
    jumpForce        : f32,
}

playerInit::proc(dataManager: ^DataManager, x:f32,y:f32,z:f32, materialID:u32) -> Player{
    player := Player{};
    player.renderableID = createCube(dataManager, x,y,z, 1.0, 1.0, 1.0, {0, 0, 0}, 0, {1, 1, 1} ,materialID, is_Static = false);
    player.speed = 8.0;
    player.yaw = 0.0;
    player.pitch = 30.0;
    player.armLength = 8.0;
    player.armHeight = 3.0;
    player.verticalVelocity = 0.0;
    player.isGrounded       = false;
    player.jumpForce        = 10.0;
    return player;
}

GRAVITY :f32: -20.0
GROUND_CHECK_DIST :f32: 0.15

checkGrounded :: proc(player: ^Player, dataManager: ^DataManager) -> bool {
    r := getRenderableObject(dataManager, player.renderableID)
    
    min_pt, max_pt := get_world_aabb(r)
    
    check_min := linalg.Vector3f32{min_pt.x + 0.1, min_pt.y - GROUND_CHECK_DIST, min_pt.z + 0.1}
    check_max := linalg.Vector3f32{max_pt.x - 0.1, min_pt.y,                     max_pt.z - 0.1}

    for _, &other in dataManager.renderer.scene.renderableMap {
        if &other == r do continue
        
        other_min, other_max := get_world_aabb(&other)
        
        if check_max.x < other_min.x || check_min.x > other_max.x do continue
        if check_max.y < other_min.y || check_min.y > other_max.y do continue
        if check_max.z < other_min.z || check_min.z > other_max.z do continue
        
        return true
    }
    return false
}