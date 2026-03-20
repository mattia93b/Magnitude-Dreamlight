package magnitudeCore

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"

DataManager::struct{
    renderer : Renderer,
    window : ^sdl.Window,
    gpuDevice: ^sdl.GPUDevice,
    shader : [dynamic]^sdl.GPUShader,
}

// Private Create Window
createWindow::proc() -> ^sdl.Window {

    mWindow: ^sdl.Window;

    if !sdl.Init({.VIDEO}){
        log.errorf("Unable to initialize SDL3. Error: %s", sdl.GetError());
    }
    log.infof("Initialize SDL3.");

    mWindow = sdl.CreateWindow(DEFAULT_WINDOW_TITLE + " - " + DEFAULT_RENDER_API, DEFAULT_SCREEN_RES_WIDTH, DEFAULT_SCREEN_RES_HEIGHT, {});
    if mWindow == nil {
        log.errorf("Couldn't create window: %s", sdl.GetError());
    }

    return mWindow;
}

// Private Create GPU Device
createGPUDevice::proc(mWindow:^sdl.Window) -> ^sdl.GPUDevice {
    // GPU Device
    mDevice: ^sdl.GPUDevice
    // Check Graphic API
    log.info("Operating System:", ODIN_OS);
    log.info("Default Rendering API:", DEFAULT_RENDER_API);
    log.info("Shader Extension:", SHADER_EXT);
    
    // Device cration with supported API
    if sdl.GPUSupportsShaderFormats({SHADER_FORMAT}, nil) {
        mDevice = sdl.CreateGPUDevice({SHADER_FORMAT}, true, DEFAULT_RENDER_API);
    }
    if mDevice == nil
    {
        log.errorf("Couldn't create Device: %s", sdl.GetError());
    }

    if sdl.ClaimWindowForGPUDevice(mDevice, mWindow){
        log.info("correct bindings between device and window", true);
    }

    return mDevice;
}

// Create Renderer and store in dataManager
createRenderer::proc(dataManager:^DataManager) {

    window := createWindow();
    gpuDevice :=  createGPUDevice(window);

    // Renderer definition
    mRenderer : Renderer //= {gpu.device = gpuDevice, window = window}

    dataManager.window = window;
    dataManager.gpuDevice = gpuDevice;   
    dataManager.renderer = mRenderer;

    initRenderer(&dataManager.renderer, gpuDevice, window);
}

createGraphicPipelineDataManager::proc(dataManager:^DataManager, vertexShaderID:u32, fragmentShaderID:u32){
    createGraphicPipeline(&dataManager.renderer, dataManager.shader[vertexShaderID], dataManager.shader[fragmentShaderID]);
}

// Create a shader and return Index
createShader::proc(dataManager:^DataManager, path:cstring, stage:sdl.GPUShaderStage, num_uniform_buffers:u32, num_storage_buffers:u32, num_samplers:u32 = 0, num_storage_textures:u32 = 0) -> u32 {
    shader := loadShader(dataManager.gpuDevice, path, stage, num_uniform_buffers, num_storage_buffers, num_samplers, num_storage_textures);
    append(&dataManager.shader, shader);
    shaderID := cast(u32)len(dataManager.shader) - 1;
    return shaderID;
}

createCube::proc(dataManager:^DataManager, x:f32, y:f32, z:f32, width:f32, height:f32, materialID:u32 = 0) -> u32 {
    box := createColoredCube(x, y, z, width, height, materialID);
    //addRenderable(&dataManager.renderer, box);
    //cubeIndex := cast(u32)len(dataManager.renderer.scene.renderable) - 1;
    //return cubeIndex;
    mapIndex := cast(u32)len(dataManager.renderer.scene.renderableMap);
    dataManager.renderer.scene.renderableMap[mapIndex] = box;
    return mapIndex;
}

createSphere::proc(dataManager:^DataManager, xPos:f32, yPos:f32, zPos:f32, radius:f64, stackCount:int, sectorCount:int, materialID:u32 = 0)  -> u32 {
    sphere := createColoredSphere(xPos, yPos, zPos, radius, stackCount, sectorCount, materialID);
    //addRenderable(&dataManager.renderer, sphere);
    //sphereIndex := cast(u32)len(dataManager.renderer.scene.renderable) - 1;
    //return sphereIndex;

    mapIndex := cast(u32)len(dataManager.renderer.scene.renderableMap);
    dataManager.renderer.scene.renderableMap[mapIndex] = sphere;
    return mapIndex;
}

getRenderableObject::proc(dataManager:^DataManager, renderableID:u32) -> ^Renderable {
    //return &dataManager.renderer.scene.renderable[renderableID];
    return &dataManager.renderer.scene.renderableMap[renderableID];
}

addLightToScene::proc(dataManager:^DataManager, lightPos: linalg.Vector3f32) -> u32 {
    addLight(&dataManager.renderer, lightPos);
    lightIndex := cast(u32)len(dataManager.renderer.scene.light) - 1;
    return lightIndex;
}

uploadAllDataToGPU::proc(dataManager:^DataManager) {
    pushRenderableInBuffer(&dataManager.renderer);
}

createMaterialInScene::proc(dataManager:^DataManager, albedo:cstring, metallic:cstring, roughness:cstring, normal:cstring, ao:cstring) -> u32 {
    append(&dataManager.renderer.scene.material, createMaterialPBR(albedo, metallic, roughness, normal, ao));
    materialID := cast(u32)len(dataManager.renderer.scene.material) - 1;
    return materialID;
}

checkCollisionRenderable::proc(dataManager:^DataManager, r1:u32, r2:u32) -> bool {
    return resolveCollision(&dataManager.renderer.scene.renderableMap[r1], &dataManager.renderer.scene.renderableMap[r2]);
    
}