package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"

// SCREEN RESOLUTION
DEFAULT_SCREEN_RES_WIDTH :: 1280;
DEFAULT_SCREEN_RES_HEIGHT :: 720;
// direct3d12 vulkan metal
DEFAULT_RENDER_API :: "direct3d12"
SHADER_EXT :: "spv"  when DEFAULT_RENDER_API == "vulkan" else 
              "dxil" when DEFAULT_RENDER_API == "direct3d12"  else 
              "msl"  when DEFAULT_RENDER_API == "metal"  else "bin"
// Window Name
DEFAULT_WINDOW_TITLE :: "Magnitude Dreamlight";

main::proc(){
    context.logger = log.create_console_logger();
    // Window
    mWindow: ^sdl.Window;

    if !sdl.Init({.VIDEO}){
        log.errorf("Unable to initialize SDL3. Error: %s", sdl.GetError());
    }
    log.infof("Initialize SDL3.");

    mWindow = sdl.CreateWindow(DEFAULT_WINDOW_TITLE + " - " + DEFAULT_RENDER_API, DEFAULT_SCREEN_RES_WIDTH, DEFAULT_SCREEN_RES_HEIGHT, {});
    if mWindow == nil {
        log.errorf("Couldn't create window: %s", sdl.GetError());
    }

    // GPU Device
    mDevice: ^sdl.GPUDevice
    // Check Graphic API
    log.info("Support for VULKAN", sdl.GPUSupportsShaderFormats({.SPIRV}, nil));
    log.info("Support for DXBC", sdl.GPUSupportsShaderFormats({.DXBC}, nil));
    log.info("Support for DXIL", sdl.GPUSupportsShaderFormats({.DXIL}, nil));
    log.info("Support for METAL", sdl.GPUSupportsShaderFormats({.MSL}, nil));
    log.info("Support for METALLIB", sdl.GPUSupportsShaderFormats({.METALLIB}, nil));
    log.info("Set Default Rendering API:", DEFAULT_RENDER_API);
    
    // Device cration with supported API
    if sdl.GPUSupportsShaderFormats({.SPIRV, .MSL, .DXIL}, nil) {
        mDevice = sdl.CreateGPUDevice({.SPIRV, .MSL, .DXIL}, false, DEFAULT_RENDER_API);
    }
    if mDevice == nil
    {
        log.errorf("Couldn't create Device: %s", sdl.GetError());
    }

    if sdl.ClaimWindowForGPUDevice(mDevice, mWindow){
        log.info("correct bindings between device and window", true);
    }

    // Renderer definition
    mRenderer : Renderer = {device = mDevice, window = mWindow}

    // Load vertex shader
    loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/vertex.vert." + SHADER_EXT, .VERTEX, 1);
    // Load fragment shader
    loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/fragment.frag." + SHADER_EXT, .FRAGMENT, 0);
    // Create Graphic Pipeline
    createGraphicPipeline(&mRenderer);

    // Cube 1
    cube := createColoredCube(0.0, -5.0, -10.0, 5.0, 5.0, {1.0, 0.0, 0.0, 1.0})

    addRenderable(&mRenderer, cube)

    // Cube 2
    cube2 := createColoredCube(0.0, 5.0, -20.0, 5.0, 5.0, {1.0, 0.0, 0.0, 1.0})

    addRenderable(&mRenderer, cube2)

    // Upload renderable in buffer
    pushRenderableInBuffer(&mRenderer);

    // Set isRunning true to start the loop
    isRunning := true;

    lastTicks := sdl.GetTicks();

    // GameLoop
    for isRunning {
        
        newTicks:= sdl.GetTicks();
        detaTime := f32(newTicks - lastTicks) / 1000;
        lastTicks = newTicks;


        // Renderer update 
        isRunning = update(&mRenderer, detaTime);
    }

    cleanRenderer(&mRenderer);
}