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

loadShader::proc(mDevice:^sdl.GPUDevice, path:cstring, stage:sdl.GPUShaderStage) -> ^sdl.GPUShader {

    shaderCodeSize:uint;
    shaderCode := sdl.LoadFile(path, &shaderCodeSize);

    shaderInfo := sdl.GPUShaderCreateInfo{};
    shaderInfo.code = cast(^u8)shaderCode;
    shaderInfo.code_size = shaderCodeSize;
    shaderInfo.entrypoint = "main";
    shaderInfo.format = {.SPIRV};
    shaderInfo.stage = stage;
    shaderInfo.num_samplers = 0;
    shaderInfo.num_storage_buffers = 0;
    shaderInfo.num_storage_textures = 0;
    shaderInfo.num_uniform_buffers = 0;
    shader := sdl.CreateGPUShader(mDevice, shaderInfo);

    sdl.free(shaderCode);

    return shader;

}


getPipelineInfo::proc(mDevice:^sdl.GPUDevice, mWindow:^sdl.Window, vertexShader:^sdl.GPUShader, fragmentShader:^sdl.GPUShader) -> sdl.GPUGraphicsPipelineCreateInfo{

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

    return pipelineInfo;
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

    // load vertex shader
    vertexShader := loadShader(mDevice, "shaders/compiled/vulkan/vertex.vert.spv", .VERTEX);
    // load fragment shader
    fragmentShader := loadShader(mDevice, "shaders/compiled/vulkan/fragment.frag.spv", .FRAGMENT);
    // create pipeline Info object
    pipelineInfo:= getPipelineInfo(mDevice,mWindow,vertexShader,fragmentShader);
    // create Graphics Pipeline
    graphicsPipeline:= sdl.CreateGPUGraphicsPipeline(mDevice, pipelineInfo);
    // release vertex shader
    sdl.ReleaseGPUShader(mDevice, vertexShader);
    // release fragment shader
    sdl.ReleaseGPUShader(mDevice, fragmentShader);

    // Vertex Buffer
    vertices:=[]Vertex{
        {-0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0},  // 0 top left vertex             0 ------ 1
        {0.5, 0.5, 0.0, 1.0, 1.0, 0.0, 1.0},   // 1 top right vertex            |        |
        {0.5, -0.5, 0.0, 1.0, 0.0, 1.0, 1.0},  // 2 bottom right vertex         |        |
        {-0.5, -0.5, 0.0, 1.0, 1.0, 0.0, 1.0}, // 3 bottom left vertex          3 ------ 2
    };

    vertex_bytes := len(vertices) * size_of(Vertex);

    bufferInfo := sdl.GPUBufferCreateInfo{};
    bufferInfo.size = cast(u32)vertex_bytes;
    bufferInfo.usage = {.VERTEX};
    vertexBuffer:= sdl.CreateGPUBuffer(mDevice, bufferInfo);

    // Index Buffer
    indices:= []u16{
        0, 1, 2,
        2, 3, 0 };

    index_bytes := len(indices) * size_of(u16);

    indexBufferInfo := sdl.GPUBufferCreateInfo{};
    indexBufferInfo.size = cast(u32)index_bytes;
    indexBufferInfo.usage = {.INDEX};
    indexBuffer:= sdl.CreateGPUBuffer(mDevice, indexBufferInfo);

    // Transfer Buffer 
    transferInfo := sdl.GPUTransferBufferCreateInfo{};
    transferInfo.size = cast(u32)(vertex_bytes + index_bytes);
    transferInfo.usage = .UPLOAD;
    transferBuffer := sdl.CreateGPUTransferBuffer(mDevice, transferInfo);

    data:= transmute([^]byte)sdl.MapGPUTransferBuffer(mDevice, transferBuffer, false);
    // Vertex copy
    sdl.memcpy(data, &vertices[0], cast(uint)vertex_bytes);
    // Index copy
    sdl.memcpy(data[vertex_bytes:], &indices[0], cast(uint)index_bytes);

    sdl.UnmapGPUTransferBuffer(mDevice, transferBuffer);

    // acquire the command buffer
    mBuffer := sdl.AcquireGPUCommandBuffer(mDevice);
    copyPass := sdl.BeginGPUCopyPass(mBuffer);
    
    // VERTEX BUFFER UPLOAD
    vertexLocation:= sdl.GPUTransferBufferLocation{};
    vertexLocation.transfer_buffer = transferBuffer;
    vertexLocation.offset = 0;

    vertexRegion := sdl.GPUBufferRegion{};
    vertexRegion.buffer = vertexBuffer;
    vertexRegion.size = cast(u32)vertex_bytes;
    vertexRegion.offset = 0;
    // Upload Vertex
    sdl.UploadToGPUBuffer(copyPass, vertexLocation, vertexRegion, true);


    // INDEX BUFFER UPLOAD
    indexLocation:= sdl.GPUTransferBufferLocation{};
    indexLocation.transfer_buffer = transferBuffer;
    indexLocation.offset = cast(u32)vertex_bytes;
    
    indexRegion := sdl.GPUBufferRegion{};
    indexRegion.buffer = indexBuffer;
    indexRegion.size = cast(u32)index_bytes;
    indexRegion.offset = 0;
    // Upload Index
    sdl.UploadToGPUBuffer(copyPass, indexLocation, indexRegion, true);



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
        //sdl.DrawGPUPrimitives(renderPass, cast(u32)len(vertices), 1, 0, 0);
        sdl.BindGPUIndexBuffer(renderPass, {buffer = indexBuffer}, ._16BIT)
        sdl.DrawGPUIndexedPrimitives(renderPass, 6, 1, 0, 0, 0);

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