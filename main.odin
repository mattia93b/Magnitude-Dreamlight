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
//DEFAULT_RENDER_API :: "direct3d12"
DEFAULT_RENDER_API :: "direct3d12" when ODIN_OS == .Windows else 
                      "metal"      when ODIN_OS == .Darwin  else 
                      "vulkan"
SHADER_EXT :: "spv"  when DEFAULT_RENDER_API == "vulkan" else 
              "dxil" when DEFAULT_RENDER_API == "direct3d12"  else 
              "msl"  when DEFAULT_RENDER_API == "metal"  else "bin"

SHADER_FORMAT :: sdl.GPUShaderFormatFlag.SPIRV when DEFAULT_RENDER_API == "vulkan" else 
                sdl.GPUShaderFormatFlag.DXIL when DEFAULT_RENDER_API == "direct3d12"  else 
                sdl.GPUShaderFormatFlag.MSL when DEFAULT_RENDER_API == "metal"  else "bin"
SHADER_ENTRY_POINT :: "main0" when DEFAULT_RENDER_API == "metal" else "main"

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
    log.info("Operating System:", ODIN_OS);
    log.info("Default Rendering API:", DEFAULT_RENDER_API);
    log.info("Shader Extension:", SHADER_EXT);
    
    // Device cration with supported API
    if sdl.GPUSupportsShaderFormats({.SPIRV, .MSL, .DXIL}, nil) {
        mDevice = sdl.CreateGPUDevice({.SPIRV, .MSL, .DXIL}, true, DEFAULT_RENDER_API);
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
    vertexShader := loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/vertex.vert." + SHADER_EXT, .VERTEX, 3, 0);
    // Load fragment shader
    fragmentShader := loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/fragment.frag." + SHADER_EXT, .FRAGMENT, 0, 1);

    // Load Light vertex shader
    lightVertexShader := loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/light.vert." + SHADER_EXT, .VERTEX, 3, 0);
    // Load Light fragment shader
    lightFragmentShader := loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/light.frag." + SHADER_EXT, .FRAGMENT, 0, 0);

    // Create Graphic Pipeline
    createGraphicPipeline(&mRenderer, vertexShader, fragmentShader);
    // Create Light Graphic Pipeline
    createGraphicPipeline(&mRenderer, lightVertexShader, lightFragmentShader);

    // Scene
    box   := createColoredCube(0.0, 10.0, -20.0, 5.0, 5.0, {1.0, 0.5, 0.31, 1.0});
    box.material = jade();
    base  := createColoredCube(0.0, 3.0, -10.0, 32.0, 0.5, {0.2, 0.2, 0.2, 1.0});
    base.material = obsidian();
	cube1 := createColoredCube(2.0, 5.0, -10.0, 3.0, 3.0, {0.8, 0.0, 0.0, 1.0});
    cube1.material = bronze();
	cube2 := createColoredCube(6.0, 5.0, -10.0, 3.0, 3.0, {0.0, 0.8, 0.0, 1.0});
    cube2.material = silver();
	cube3 := createColoredCube(-2.0, 5.0, -10.0, 3.0, 3.0, {0.0, 0.0, 0.8, 1.0});
    cube3.material = emerald();
	cube4 := createColoredCube(-6.0, 5.0, -10.0, 3.0, 3.0, {0.5, 0.5, 0.5, 1.0});
    cube4.material = redPlastic()

    addRenderable(&mRenderer, box);
    addRenderable(&mRenderer, base);
    addRenderable(&mRenderer, cube1);
    addRenderable(&mRenderer, cube2);
    addRenderable(&mRenderer, cube3);
    addRenderable(&mRenderer, cube4);

    sphere1 := createColoredSphere(-6.0, 10.0, -10.0, 2.0, 25.0, 25.0 ,{0.5, 0.5, 0.5, 1.0});

    addRenderable(&mRenderer, sphere1);

    sphere2 := createColoredSphere(6.0, 10.0, -10.0, 2.0, 25.0, 25.0 ,{0.5, 0.5, 0.5, 1.0});

    addRenderable(&mRenderer, sphere2);

    addLight(&mRenderer, {0.0, 15.0, 10.0});

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