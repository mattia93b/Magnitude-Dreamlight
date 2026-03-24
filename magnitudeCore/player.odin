package magnitudeCore

import "core:math/linalg"

Player::struct{
    renderableID    : u32,
    speed           : f32,
    yaw             : f32,
    pitch           : f32,
    armLength       : f32,
    armHeight       : f32,
}

playerInit::proc(dataManager: ^DataManager, x:f32,y:f32,z:f32, materialID:u32) -> Player{
    player := Player{};
    player.renderableID = createCube(dataManager, x,y,z, 1.0, 1.0, materialID);
    player.speed = 8.0;
    player.yaw = 0.0;
    player.pitch = 30.0;
    player.armLength = 8.0;
    player.armHeight = 3.0;
    return player;
}