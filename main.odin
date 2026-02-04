package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"

// SCREEN RESOLUTION
DEFAULT_SCREEN_RES_WIDTH :: 1280;
DEFAULT_SCREEN_RES_HEIGHT :: 720;
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
    // Device cration with supported API
    if sdl.GPUSupportsShaderFormats({.SPIRV, .DXIL, .MSL }, nil) {
        mDevice = sdl.CreateGPUDevice({.SPIRV, .DXIL, .MSL}, true, nil);
    }
    if mDevice == nil
    {
        log.errorf("Couldn't create Device: %s", sdl.GetError());
    }

    if sdl.ClaimWindowForGPUDevice(mDevice, mWindow){
        log.info("correct bindings between device and window", true);
    }


    // load vertex shader
    vertexCodeSize:uint;
    vertexCode := sdl.LoadFile("shaders/compiled/dx12/vertex.vert.dxil", &vertexCodeSize);

    vertexInfo := sdl.GPUShaderCreateInfo{};
    vertexInfo.code = cast(^u8)vertexCode;
    vertexInfo.code_size = vertexCodeSize;
    vertexInfo.entrypoint = "main";
    vertexInfo.format = {.DXIL};
    vertexInfo.stage = .VERTEX;
    vertexInfo.num_samplers = 0;
    vertexInfo.num_storage_buffers = 0;
    vertexInfo.num_storage_textures = 0;
    vertexInfo.num_uniform_buffers = 0;
    vertexShader := sdl.CreateGPUShader(mDevice, vertexInfo);

    sdl.free(vertexCode);

    // load fragment shader
    fragmentCodeSize:uint;
    fragmentCode := sdl.LoadFile("shaders/compiled/dx12/fragment.frag.dxil", &fragmentCodeSize);

    fragmentInfo := sdl.GPUShaderCreateInfo{};
    fragmentInfo.code = cast(^u8)fragmentCode;
    fragmentInfo.code_size = fragmentCodeSize;
    fragmentInfo.entrypoint = "main";
    fragmentInfo.format = {.DXIL};
    fragmentInfo.stage = .FRAGMENT;
    fragmentInfo.num_samplers = 0;
    fragmentInfo.num_storage_buffers = 0;
    fragmentInfo.num_storage_textures = 0;
    fragmentInfo.num_uniform_buffers = 0;
    fragmentShader := sdl.CreateGPUShader(mDevice, fragmentInfo);

    sdl.free(fragmentCode);


    pipelineInfo := sdl.GPUGraphicsPipelineCreateInfo{};
    //bind shaders
    pipelineInfo.vertex_shader = vertexShader;
    pipelineInfo.fragment_shader = fragmentShader;

    pipelineInfo.primitive_type = .TRIANGLELIST;

    vertexBufferDescriptions :[1]sdl.GPUVertexBufferDescription;
    vertexBufferDescriptions[0].slot = 0;
    vertexBufferDescriptions[0].input_rate = .VERTEX;
    vertexBufferDescriptions[0].instance_step_rate = 0;
    vertexBufferDescriptions[0].pitch = size_of(Vertex);

    pipelineInfo.vertex_input_state.num_vertex_buffers = 1;
    pipelineInfo.vertex_input_state.vertex_buffer_descriptions = &vertexBufferDescriptions[0];


     vertexAttributes :[2]sdl.GPUVertexAttribute;
    // Position
    vertexAttributes[0].buffer_slot = 0;
    vertexAttributes[0].location = 0; // layout (location = 0) in shader
    vertexAttributes[0].format = .FLOAT3;
    vertexAttributes[0].offset = 0;

    // Color
    vertexAttributes[1].buffer_slot = 0;
    vertexAttributes[1].location = 1; // layout (location = 1) in shader
    vertexAttributes[1].format = .FLOAT4;
    vertexAttributes[1].offset = size_of(f32) * 3; // 4th float from current buffer position

    pipelineInfo.vertex_input_state.num_vertex_attributes = 2;
    pipelineInfo.vertex_input_state.vertex_attributes = &vertexAttributes[0];


    colorTargetDescriptions :[1]sdl.GPUColorTargetDescription;
    colorTargetDescriptions[0] = {};
    colorTargetDescriptions[0].blend_state.color_blend_op = .ADD;
    colorTargetDescriptions[0].blend_state.alpha_blend_op = .ADD;
    colorTargetDescriptions[0].blend_state.src_color_blendfactor = .SRC_ALPHA;
    colorTargetDescriptions[0].blend_state.dst_color_blendfactor = .ONE_MINUS_SRC_ALPHA;
    colorTargetDescriptions[0].blend_state.src_alpha_blendfactor = .SRC_ALPHA;
    colorTargetDescriptions[0].blend_state.dst_alpha_blendfactor = .ONE_MINUS_SRC_ALPHA;
    colorTargetDescriptions[0].format = sdl.GetGPUSwapchainTextureFormat(mDevice, mWindow);

    pipelineInfo.target_info.num_color_targets = 1;
    pipelineInfo.target_info.color_target_descriptions = &colorTargetDescriptions[0];

    graphicsPipeline := sdl.CreateGPUGraphicsPipeline(mDevice, pipelineInfo);


    // release vertex shader
    sdl.ReleaseGPUShader(mDevice, vertexShader);
    // release fragment shader
    sdl.ReleaseGPUShader(mDevice, fragmentShader);

    // Set up Vertex Buffer
    vertices:=[]Vertex{
        {0.0, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0},     // top vertex
        {-0.5, -0.5, 0.0, 1.0, 1.0, 0.0, 1.0},   // bottom left vertex
        {0.5, -0.5, 0.0, 1.0, 0.0, 1.0, 1.0}     // bottom right vertex
    };

    vertex_bytes := len(vertices) * size_of(Vertex);

    bufferInfo := sdl.GPUBufferCreateInfo{};
    bufferInfo.size = cast(u32)vertex_bytes;
    bufferInfo.usage = {.VERTEX};
    vertexBuffer:= sdl.CreateGPUBuffer(mDevice, bufferInfo);

    transferInfo := sdl.GPUTransferBufferCreateInfo{};
    transferInfo.size = cast(u32)vertex_bytes;
    transferInfo.usage = .UPLOAD;
    transferBuffer := sdl.CreateGPUTransferBuffer(mDevice, transferInfo);

    data:^Vertex = cast(^Vertex)sdl.MapGPUTransferBuffer(mDevice, transferBuffer, false);

    sdl.memcpy(data, &vertices[0], cast(uint)vertex_bytes);

    sdl.UnmapGPUTransferBuffer(mDevice, transferBuffer);

    // acquire the command buffer
    mBuffer := sdl.AcquireGPUCommandBuffer(mDevice);
    copyPass := sdl.BeginGPUCopyPass(mBuffer);
    
    location:= sdl.GPUTransferBufferLocation{};
    location.transfer_buffer = transferBuffer;
    location.offset = 0;

    region := sdl.GPUBufferRegion{};
    region.buffer = vertexBuffer;
    region.size = cast(u32)vertex_bytes;
    region.offset = 0;

    sdl.UploadToGPUBuffer(copyPass, location, region, true);

    sdl.EndGPUCopyPass(copyPass);
    if sdl.SubmitGPUCommandBuffer(mBuffer){
        log.info("Submit buffert to GPU succesfully", true);
    }




    isRunning := true;

    // GameLoop
    for isRunning {
        
        event: sdl.Event;
        mBuffer := sdl.AcquireGPUCommandBuffer(mDevice);

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
        if sdl.WaitAndAcquireGPUSwapchainTexture(mBuffer, mWindow, &swapChainTexture, nil, nil){
            log.info("correct bindings between device and window", true);
        }
        // create color target
        color : sdl.GPUColorTargetInfo;
        color.clear_color = {255/255.0, 219/255.0, 187/255.0, 255/255.0};
        color.load_op = .CLEAR;
        color.store_op = .STORE;
        color.texture = swapChainTexture;
        // begin render pass
        renderPass := sdl.BeginGPURenderPass(mBuffer, &color, 1, nil);

        // bind pipeline
        sdl.BindGPUGraphicsPipeline(renderPass, graphicsPipeline);

        // bind vertexBuffer
        bufferBindings :[1]sdl.GPUBufferBinding;
        bufferBindings[0].buffer = vertexBuffer;
        bufferBindings[0].offset = 0;

        sdl.BindGPUVertexBuffers(renderPass, 0, &bufferBindings[0], 1);

        sdl.DrawGPUPrimitives(renderPass, 3, 1, 0, 0);

        // end render pass
        sdl.EndGPURenderPass(renderPass);

        // submit command buffer
        if sdl.SubmitGPUCommandBuffer(mBuffer){
            log.info("Send buffer to GPU done correctly", true);
        }
    }

    sdl.ReleaseGPUBuffer(mDevice, vertexBuffer);
    sdl.ReleaseGPUTransferBuffer(mDevice, transferBuffer);
    sdl.ReleaseGPUGraphicsPipeline(mDevice, graphicsPipeline);
    sdl.DestroyGPUDevice(mDevice);
    sdl.DestroyWindow(mWindow);
}