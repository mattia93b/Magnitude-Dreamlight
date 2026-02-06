package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"

// SCREEN RESOLUTION
DEFAULT_SCREEN_RES_WIDTH :: 1280;
DEFAULT_SCREEN_RES_HEIGHT :: 720;
// direct3d12 vulkan metal
DEFAULT_RENDER_API :: "vulkan"
DEFAULT_WINDOW_TITLE :: "Magnitude Dreamlight";

Vertex::struct{
    x,y,z :f32,     // vec3 position
    r,g,b,a: f32,   // vec4 color
}

main::proc(){
    context.logger = log.create_console_logger();
    // Window
    mWindow: ^sdl.Window;

    if !sdl.Init({.VIDEO}){
        log.errorf("Unable to initialize SDL3. Error: %s", sdl.GetError());
    }
    log.infof("Initialize SDL3.");

    mWindow = sdl.CreateWindow(DEFAULT_WINDOW_TITLE, DEFAULT_SCREEN_RES_WIDTH, DEFAULT_SCREEN_RES_HEIGHT, {});
    if mWindow == nil {
        log.errorf("Couldn't create window: %s", sdl.GetError());
    }
    // Device
    mDevice: ^sdl.GPUDevice
    // check API
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

    mRenderer : Renderer
    mRenderer.device = mDevice
    mRenderer.window = mWindow

    // load vertex shader
    loadShader(&mRenderer, "shaders/compiled/vulkan/vertex.vert.spv", .VERTEX);
    // load fragment shader
    loadShader(&mRenderer, "shaders/compiled/vulkan/fragment.frag.spv", .FRAGMENT);
    createGraphicPipeline(&mRenderer);
    // release vertex shader
    sdl.ReleaseGPUShader(mRenderer.device, mRenderer.vertexShader);
    // release fragment shader
    sdl.ReleaseGPUShader(mRenderer.device, mRenderer.fragmentShader);

    // Vertex Buffer
    vertices:=[]Vertex{
        {-0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0},  // 0 top left vertex             0 ------ 1
        {0.5, 0.5, 0.0, 1.0, 1.0, 0.0, 1.0},   // 1 top right vertex            |        |
        {0.5, -0.5, 0.0, 1.0, 0.0, 1.0, 1.0},  // 2 bottom right vertex         |        |
        {-0.5, -0.5, 0.0, 1.0, 1.0, 0.0, 1.0}, // 3 bottom left vertex          3 ------ 2
    };

    // Index Buffer
    indices:= []u16{
        0, 1, 2,
        2, 3, 0 };

    vertices2:=[]Vertex{
        {0.0, 0.7, 0.0, 1.0, 0.0, 0.0, 1.0},  
        {-0.7, -0.7, 0.0, 1.0, 1.0, 0.0, 1.0},
        {0.7, -0.7, 0.0, 1.0, 0.0, 1.0, 1.0},
    };

    indices2:= []u16{
        0, 1, 2,
    };

    addRenderable(&mRenderer, {vertices,indices});

    addRenderable(&mRenderer, {vertices2,indices2});

    pushRenderableInBuffer(&mRenderer);

    isRunning := true;

    // GameLoop
    for isRunning {
        
        event: sdl.Event;
        mRenderer.buffer = sdl.AcquireGPUCommandBuffer(mRenderer.device);

        // Read all event loop
        for sdl.PollEvent(&event) {

            #partial switch event.type {
            case .QUIT:
                isRunning = false;

            case .KEY_DOWN:
                if event.key.scancode == .ESCAPE {
                    isRunning = false;
                }
            }
        }

        // get the swapchain texture
        swapChainTexture : ^sdl.GPUTexture;
        if sdl.WaitAndAcquireGPUSwapchainTexture(mRenderer.buffer, mRenderer.window, &swapChainTexture, nil, nil){
            //log.info("correct bindings between device and window", true);
        }
        // create color target
        color : sdl.GPUColorTargetInfo;
        color.clear_color = {255/255.0, 219/255.0, 187/255.0, 255/255.0};
        color.load_op = .CLEAR;
        color.store_op = .STORE;
        color.texture = swapChainTexture;
        // begin render pass
        renderPass := sdl.BeginGPURenderPass(mRenderer.buffer, &color, 1, nil);

        // bind pipeline
        sdl.BindGPUGraphicsPipeline(renderPass, mRenderer.graphicsPipeline);

        // bind vertexBuffer
        bufferBindings :[1]sdl.GPUBufferBinding;
        bufferBindings[0].buffer = mRenderer.vertexBuffer;
        bufferBindings[0].offset = 0;

        sdl.BindGPUVertexBuffers(renderPass, 0, &bufferBindings[0], 1);
        //sdl.DrawGPUPrimitives(renderPass, cast(u32)len(vertices), 1, 0, 0);
        sdl.BindGPUIndexBuffer(renderPass, {buffer = mRenderer.indexBuffer}, ._16BIT)
        sdl.DrawGPUIndexedPrimitives(renderPass, 6, 1, 0, 0, 0);

        // end render pass
        sdl.EndGPURenderPass(renderPass);

        // submit command buffer
        if sdl.SubmitGPUCommandBuffer(mRenderer.buffer){
            //log.info("Send buffer to GPU done correctly", true);
        }
    }

    sdl.ReleaseGPUBuffer(mRenderer.device, mRenderer.vertexBuffer);
    sdl.ReleaseGPUTransferBuffer(mRenderer.device, mRenderer.transferBuffer);
    sdl.ReleaseGPUGraphicsPipeline(mRenderer.device, mRenderer.graphicsPipeline);
    sdl.DestroyGPUDevice(mRenderer.device);
    sdl.DestroyWindow(mRenderer.window);
}