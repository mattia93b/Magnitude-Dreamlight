package main

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
    mRenderer : Renderer = {device = gpuDevice, window = window}

    dataManager.window = window;
    dataManager.gpuDevice = gpuDevice;   
    dataManager.renderer = mRenderer;

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

