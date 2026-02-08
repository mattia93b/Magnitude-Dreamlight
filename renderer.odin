package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"


// Uniform struct to send to GPU
UBO::struct #align(16){
    projMat:matrix[4,4]f32,
    viewMat:matrix[4,4]f32,
    modelMat:[100]matrix[4,4]f32,
}


Renderer::struct{
    device: ^sdl.GPUDevice,
    window: ^sdl.Window,
    pipelineInfo: sdl.GPUGraphicsPipelineCreateInfo,
    graphicsPipeline: ^sdl.GPUGraphicsPipeline,
    vertexShader: ^sdl.GPUShader,
    fragmentShader: ^sdl.GPUShader,
    renderable:[dynamic]Renderable,
    allVertices:[dynamic]Vertex,
    allIndices:[dynamic]u16,
    buffer:^sdl.GPUCommandBuffer,
    vertexBuffer:^sdl.GPUBuffer,
    indexBuffer:^sdl.GPUBuffer,
    transferBuffer:^sdl.GPUTransferBuffer,
    allModelMatrix:[dynamic]matrix[4,4]f32,
    modelViewPorjectionMatrixUniform:UBO,
}


loadShader::proc(mRenderer:^Renderer, path:cstring, stage:sdl.GPUShaderStage, num_uniform_buffers:u32){

    shaderCodeSize:uint;
    shaderCode := sdl.LoadFile(path, &shaderCodeSize);

    shaderInfo := sdl.GPUShaderCreateInfo{};
    shaderInfo.code = cast(^u8)shaderCode;
    shaderInfo.code_size = shaderCodeSize;
    shaderInfo.entrypoint = "main";
    shaderInfo.format = {.SPIRV, .DXIL, .MSL};
    shaderInfo.stage = stage;
    shaderInfo.num_samplers = 0;
    shaderInfo.num_storage_buffers = 0;
    shaderInfo.num_storage_textures = 0;
    shaderInfo.num_uniform_buffers = num_uniform_buffers;
    shader := sdl.CreateGPUShader(mRenderer.device, shaderInfo);

    sdl.free(shaderCode);

    switch stage {
        case .VERTEX:
            mRenderer.vertexShader = shader
        case .FRAGMENT:
            mRenderer.fragmentShader = shader
    }

}


createGraphicPipeline::proc(mRenderer:^Renderer){

    pipelineInfo := sdl.GPUGraphicsPipelineCreateInfo{};
    //bind shaders
    pipelineInfo.vertex_shader = mRenderer.vertexShader;
    pipelineInfo.fragment_shader = mRenderer.fragmentShader;

    pipelineInfo.primitive_type = .TRIANGLELIST;

    vertexBufferDescriptions :[1]sdl.GPUVertexBufferDescription;
    vertexBufferDescriptions[0].slot = 0;
    vertexBufferDescriptions[0].input_rate = .VERTEX;
    vertexBufferDescriptions[0].instance_step_rate = 0;
    vertexBufferDescriptions[0].pitch = size_of(Vertex);

    pipelineInfo.vertex_input_state.num_vertex_buffers = 1;
    pipelineInfo.vertex_input_state.vertex_buffer_descriptions = &vertexBufferDescriptions[0];


    vertexAttributes :[3]sdl.GPUVertexAttribute;
    // Position
    vertexAttributes[0].buffer_slot = 0;
    vertexAttributes[0].location = 0; // layout (location = 0) in shader
    vertexAttributes[0].format = .FLOAT3;
    vertexAttributes[0].offset = 0;

    // Color
    vertexAttributes[1].buffer_slot = 0;
    vertexAttributes[1].location = 1; // layout (location = 1) in shader
    vertexAttributes[1].format = .FLOAT4;
    vertexAttributes[1].offset = cast(u32)offset_of(Vertex, r); // 4th float from current buffer position OLD: size_of(f32) * 3

    // ModelMatrixIndex
    vertexAttributes[2].buffer_slot = 0;
    vertexAttributes[2].location = 2; // layout (location = 2) in shader
    vertexAttributes[2].format = .UINT;
    vertexAttributes[2].offset = cast(u32)offset_of(Vertex, modelMatrixIndex); // 8th float from current buffer position OLD: size_of(f32) * 7

    pipelineInfo.vertex_input_state.num_vertex_attributes = 3;
    pipelineInfo.vertex_input_state.vertex_attributes = &vertexAttributes[0];


    colorTargetDescriptions :[1]sdl.GPUColorTargetDescription;
    colorTargetDescriptions[0] = {};
    colorTargetDescriptions[0].blend_state.color_blend_op = .ADD;
    colorTargetDescriptions[0].blend_state.alpha_blend_op = .ADD;
    colorTargetDescriptions[0].blend_state.src_color_blendfactor = .SRC_ALPHA;
    colorTargetDescriptions[0].blend_state.dst_color_blendfactor = .ONE_MINUS_SRC_ALPHA;
    colorTargetDescriptions[0].blend_state.src_alpha_blendfactor = .SRC_ALPHA;
    colorTargetDescriptions[0].blend_state.dst_alpha_blendfactor = .ONE_MINUS_SRC_ALPHA;
    colorTargetDescriptions[0].blend_state.enable_blend = true;
    colorTargetDescriptions[0].format = sdl.GetGPUSwapchainTextureFormat(mRenderer.device, mRenderer.window);

    pipelineInfo.target_info.num_color_targets = 1;
    pipelineInfo.target_info.color_target_descriptions = &colorTargetDescriptions[0];

    pipelineInfo.depth_stencil_state.enable_depth_test = true
    pipelineInfo.rasterizer_state.cull_mode = .NONE
    pipelineInfo.rasterizer_state.fill_mode = .FILL
    // createGraphicPipeline
    mRenderer.graphicsPipeline = sdl.CreateGPUGraphicsPipeline(mRenderer.device, pipelineInfo);
    
    // release vertex shader
    sdl.ReleaseGPUShader(mRenderer.device, mRenderer.vertexShader);
    // release fragment shader
    sdl.ReleaseGPUShader(mRenderer.device, mRenderer.fragmentShader);
     
}


addRenderable::proc(mRenderer:^Renderer, renderable:Renderable){
    append(&mRenderer.renderable, renderable)
    log.info("Length of mRenderer.renderable: ", len(mRenderer.renderable));
}


pushRenderableInBuffer::proc(mRenderer:^Renderer){

    for el in mRenderer.renderable{

        modelMatrixIndex := cast(u32)len(mRenderer.allModelMatrix)
        append(&mRenderer.allModelMatrix, el.modelMatrix)

        vertex_offset := u16(len(mRenderer.allVertices));
        //append(&mRenderer.allVertices, ..el.vertex[:]);
        for &vx in el.vertex{
            vx.modelMatrixIndex = modelMatrixIndex;
            //append(&mRenderer.allVertices, vx);
        }

        append(&mRenderer.allVertices, ..el.vertex[:])

        for idx in el.index {
            append(&mRenderer.allIndices, u16(idx) + vertex_offset);
        }
        
    }

    log.info("Model Matrix Index: ", mRenderer.allVertices[30]);
    log.info("Model Matrix: ", mRenderer.allModelMatrix[:]);

    vertex_bytes := len(mRenderer.allVertices) * size_of(Vertex);

    bufferInfo := sdl.GPUBufferCreateInfo{};
    bufferInfo.size = cast(u32)vertex_bytes;
    bufferInfo.usage = {.VERTEX};
    mRenderer.vertexBuffer= sdl.CreateGPUBuffer(mRenderer.device, bufferInfo);


    index_bytes := len(mRenderer.allIndices) * size_of(u16);

    indexBufferInfo := sdl.GPUBufferCreateInfo{};
    indexBufferInfo.size = cast(u32)index_bytes;
    indexBufferInfo.usage = {.INDEX};
    mRenderer.indexBuffer= sdl.CreateGPUBuffer(mRenderer.device, indexBufferInfo);

    // Transfer Buffer 
    transferInfo := sdl.GPUTransferBufferCreateInfo{};
    transferInfo.size = cast(u32)(vertex_bytes + index_bytes);
    transferInfo.usage = .UPLOAD;
    mRenderer.transferBuffer = sdl.CreateGPUTransferBuffer(mRenderer.device, transferInfo);

    data:= transmute([^]byte)sdl.MapGPUTransferBuffer(mRenderer.device, mRenderer.transferBuffer, false);
    // Vertex copy
    sdl.memcpy(data, &mRenderer.allVertices[0], cast(uint)vertex_bytes);
    // Index copy
    sdl.memcpy(data[vertex_bytes:], &mRenderer.allIndices[0], cast(uint)index_bytes);

    sdl.UnmapGPUTransferBuffer(mRenderer.device, mRenderer.transferBuffer);

    // acquire the command buffer
    mRenderer.buffer = sdl.AcquireGPUCommandBuffer(mRenderer.device);
    copyPass := sdl.BeginGPUCopyPass(mRenderer.buffer);
    
    // VERTEX BUFFER UPLOAD
    vertexLocation:= sdl.GPUTransferBufferLocation{};
    vertexLocation.transfer_buffer = mRenderer.transferBuffer;
    vertexLocation.offset = 0;

    vertexRegion := sdl.GPUBufferRegion{};
    vertexRegion.buffer = mRenderer.vertexBuffer;
    vertexRegion.size = cast(u32)vertex_bytes;
    vertexRegion.offset = 0;
    // Upload Vertex
    sdl.UploadToGPUBuffer(copyPass, vertexLocation, vertexRegion, true);


    // INDEX BUFFER UPLOAD
    indexLocation:= sdl.GPUTransferBufferLocation{};
    indexLocation.transfer_buffer = mRenderer.transferBuffer;
    indexLocation.offset = cast(u32)vertex_bytes;
    
    indexRegion := sdl.GPUBufferRegion{};
    indexRegion.buffer = mRenderer.indexBuffer;
    indexRegion.size = cast(u32)index_bytes;
    indexRegion.offset = 0;
    // Upload Index
    sdl.UploadToGPUBuffer(copyPass, indexLocation, indexRegion, true);


    sdl.EndGPUCopyPass(copyPass);
    if sdl.SubmitGPUCommandBuffer(mRenderer.buffer){
        log.info("Submit buffert to GPU succesfully", true);
    }

}


update::proc(mRenderer:^Renderer, deltatime:f32){

    mRenderer.buffer = sdl.AcquireGPUCommandBuffer(mRenderer.device);

    // get the swapchain texture
    swapChainTexture : ^sdl.GPUTexture;
    if sdl.WaitAndAcquireGPUSwapchainTexture(mRenderer.buffer, mRenderer.window, &swapChainTexture, nil, nil){
        //log.info("correct bindings between device and window", true);
    }
    // create color target
    color : sdl.GPUColorTargetInfo;
    color.clear_color = {255/255.0, 219/255.0, 187/255.0, 255/255.0};
    //color.clear_color = {0, 0, 0, 0};
    color.load_op = .CLEAR;
    color.store_op = .STORE;
    color.texture = swapChainTexture;
    // begin render pass
    renderPass := sdl.BeginGPURenderPass(mRenderer.buffer, &color, 1, nil);

    // bind pipeline
    sdl.BindGPUGraphicsPipeline(renderPass, mRenderer.graphicsPipeline);

    // Get Windows size to calculate the projection Matrix
    win_size:[2]i32;
    sdl.GetWindowSize(mRenderer.window, &win_size.x, &win_size.y);
    uniformBuffer := UBO{
        projMat = linalg.matrix4_perspective_f32(70, f32(win_size.x) / f32(win_size.y), 0.1, 1000),
        viewMat = linalg.matrix4_translate_f32({0, 0, -5}),
    }

    n_to_copy := min(len(mRenderer.allModelMatrix), 100)
    
    if n_to_copy > 0 {
        copy(uniformBuffer.modelMat[:n_to_copy], mRenderer.allModelMatrix[:n_to_copy])
    }

    //log.info("UNIFORM Model Matrix: ", uniformBuffer.modelMat[:]);

    sdl.PushGPUVertexUniformData(mRenderer.buffer, 0, &uniformBuffer, size_of(uniformBuffer));

    // bind vertexBuffer
    bufferBindings :[1]sdl.GPUBufferBinding;
    bufferBindings[0].buffer = mRenderer.vertexBuffer;
    bufferBindings[0].offset = 0;

    sdl.BindGPUVertexBuffers(renderPass, 0, &bufferBindings[0], 1);
    //sdl.DrawGPUPrimitives(renderPass, cast(u32)len(vertices), 1, 0, 0);
    sdl.BindGPUIndexBuffer(renderPass, {buffer = mRenderer.indexBuffer}, ._16BIT)
    sdl.DrawGPUIndexedPrimitives(renderPass, cast(u32)len(mRenderer.allIndices), 1, 0, 0, 0);

    // end render pass
    sdl.EndGPURenderPass(renderPass);

    // submit command buffer
    if sdl.SubmitGPUCommandBuffer(mRenderer.buffer){
        //log.info("Send buffer to GPU done correctly", true);
    }

}


cleanRenderer::proc(mRenderer:^Renderer){
    sdl.ReleaseGPUBuffer(mRenderer.device, mRenderer.vertexBuffer);
    sdl.ReleaseGPUTransferBuffer(mRenderer.device, mRenderer.transferBuffer);
    sdl.ReleaseGPUGraphicsPipeline(mRenderer.device, mRenderer.graphicsPipeline);
    sdl.DestroyGPUDevice(mRenderer.device);
    sdl.DestroyWindow(mRenderer.window);
}