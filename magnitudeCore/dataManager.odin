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

createDebugGraphicPipelineDataManager::proc(dataManager:^DataManager, vertexShaderID:u32, fragmentShaderID:u32){
    createDebugGraphicPipeline(&dataManager.renderer, dataManager.shader[vertexShaderID], dataManager.shader[fragmentShaderID]);
}

// Create a shader and return Index
createShader::proc(dataManager:^DataManager, path:cstring, stage:sdl.GPUShaderStage, num_uniform_buffers:u32, num_storage_buffers:u32, num_samplers:u32 = 0, num_storage_textures:u32 = 0) -> u32 {
    shader := loadShader(dataManager.gpuDevice, path, stage, num_uniform_buffers, num_storage_buffers, num_samplers, num_storage_textures);
    append(&dataManager.shader, shader);
    shaderID := cast(u32)len(dataManager.shader) - 1;
    return shaderID;
}

createCube::proc(dataManager:^DataManager, x:f32, y:f32, z:f32, width:f32, height:f32, materialID:u32 = 0, velocity:linalg.Vector3f32={0,0,0}, is_Static:bool = true) -> u32 {
    box := createColoredCube(x, y, z, width, height, materialID, velocity, is_Static);
    mapIndex := cast(u32)len(dataManager.renderer.scene.renderableMap);
    dataManager.renderer.scene.renderableMap[mapIndex] = box;
    return mapIndex;
}

createSphere::proc(dataManager:^DataManager, xPos:f32, yPos:f32, zPos:f32, radius:f64, stackCount:int, sectorCount:int, materialID:u32 = 0, velocity:linalg.Vector3f32={0,0,0}, is_Static:bool = true)  -> u32 {
    sphere := createColoredSphere(xPos, yPos, zPos, radius, stackCount, sectorCount, materialID, velocity, is_Static);
    mapIndex := cast(u32)len(dataManager.renderer.scene.renderableMap);
    dataManager.renderer.scene.renderableMap[mapIndex] = sphere;
    return mapIndex;
}

getRenderableObject::proc(dataManager:^DataManager, renderableID:u32) -> ^Renderable {
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


updateAllPhysics :: proc(dataManager: ^DataManager, deltaTime: f32) {
    for _, &r in dataManager.renderer.scene.renderableMap {
        updatePhysics(&r, deltaTime);
    }
}

updateAllCollisions :: proc(dataManager: ^DataManager, dt: f32) {

    keys := make([dynamic]u32, context.temp_allocator)
    for key, _ in dataManager.renderer.scene.renderableMap {
        append(&keys, key)
    }

    n := len(keys)
    for i := 0; i < n; i += 1 {
        for j := i + 1; j < n; j += 1 {

            r1 := &dataManager.renderer.scene.renderableMap[keys[i]]
            r2 := &dataManager.renderer.scene.renderableMap[keys[j]]

            if r1.is_static && r2.is_static do continue

            if !aabb_overlap_check(r1, r2, dt) do continue

            resolve_swept(r1, r2, dt)
        }
    }
}