package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"

// SCREEN RESOLUTION
DEFAULT_SCREEN_RES_WIDTH :: 1280
DEFAULT_SCREEN_RES_HEIGHT :: 720
DEFAULT_WINDOW_TITLE :: "Magnitude Dreamlight"

main::proc(){
    context.logger = log.create_console_logger()
    // Window
    mWindow: ^sdl.Window

    if !sdl.Init({.VIDEO}){
        log.errorf("Unable to initialize SDL3. Error: %s", sdl.GetError())
    }
    log.infof("Initialize SDL3.")

    mWindow = sdl.CreateWindow(DEFAULT_WINDOW_TITLE, DEFAULT_SCREEN_RES_WIDTH, DEFAULT_SCREEN_RES_HEIGHT, {})
    if mWindow == nil {
        log.errorf("Couldn't create window: %s", sdl.GetError())
    }
    // Device
    mDevice: ^sdl.GPUDevice
    // check API
    log.info("Support for VULKAN", sdl.GPUSupportsShaderFormats({.SPIRV}, nil))
    log.info("Support for DXBC", sdl.GPUSupportsShaderFormats({.DXBC}, nil))
    log.info("Support for DXIL", sdl.GPUSupportsShaderFormats({.DXIL}, nil))
    log.info("Support for METAL", sdl.GPUSupportsShaderFormats({.MSL}, nil))
    log.info("Support for METALLIB", sdl.GPUSupportsShaderFormats({.METALLIB}, nil))
    // Device cration with supported API
    if sdl.GPUSupportsShaderFormats({.SPIRV}, nil) {
        mDevice = sdl.CreateGPUDevice({.SPIRV}, true, nil)
    }
    if mDevice == nil
    {
        log.errorf("Couldn't create Device: %s", sdl.GetError());
    }

    if sdl.ClaimWindowForGPUDevice(mDevice, mWindow){
        log.info("correct bindings between device and window", true);
    }

    isRunning := true;

    for isRunning {
        
        event: sdl.Event

        // Read all event loop
        for sdl.PollEvent(&event) {

            #partial switch event.type {
            case .QUIT:
                isRunning = false

            case .KEY_DOWN:
                if event.key.scancode == .ESCAPE {
                    isRunning = false
                }
            }
        }

        mBuffer : ^sdl.GPUCommandBuffer;
        
        mBuffer = sdl.AcquireGPUCommandBuffer(mDevice);

        swapChainTexture : ^sdl.GPUTexture;

        if sdl.WaitAndAcquireGPUSwapchainTexture(mBuffer, mWindow, &swapChainTexture, nil, nil){
            log.info("correct bindings between device and window", true);
        }

        color : sdl.GPUColorTargetInfo;

        color.clear_color = {255/255.0, 219/255.0, 187/255.0, 255/255.0};
        color.load_op = .CLEAR;

        color.store_op = .STORE;

        color.texture = swapChainTexture;

        renderPass := sdl.BeginGPURenderPass(mBuffer, &color, 1, nil);

        sdl.EndGPURenderPass(renderPass);

        if sdl.SubmitGPUCommandBuffer(mBuffer){
            log.info("Send buffer to GPU done correctly", true)
        }


    }

}