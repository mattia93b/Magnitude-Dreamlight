package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"


vec3 :: struct {
    x,y,z:f32
}

Renderable::struct{
    vertex:[]Vertex,
    index:[]u16
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
}


loadShader::proc(mRenderer:^Renderer, path:cstring, stage:sdl.GPUShaderStage){

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
    colorTargetDescriptions[0].format = sdl.GetGPUSwapchainTextureFormat(mRenderer.device, mRenderer.window);

    pipelineInfo.target_info.num_color_targets = 1;
    pipelineInfo.target_info.color_target_descriptions = &colorTargetDescriptions[0];

    mRenderer.pipelineInfo = pipelineInfo;

    mRenderer.graphicsPipeline = sdl.CreateGPUGraphicsPipeline(mRenderer.device, pipelineInfo);
     
}


addRenderable::proc(mRenderer:^Renderer, renderable:Renderable){
    append(&mRenderer.renderable, renderable)
    log.info("Length of mRenderer.renderable: ", len(mRenderer.renderable));
}


pushRenderableInBuffer::proc(mRenderer:^Renderer){

    for el in mRenderer.renderable{

        vertex_offset := u16(len(mRenderer.allVertices))

        append(&mRenderer.allVertices, ..el.vertex)

        for idx in el.index {
            append(&mRenderer.allIndices, u16(idx) + vertex_offset)
        }
        log.info("Length of mRenderer.allVertices: ", len(mRenderer.allVertices));
        log.info("Length of mRenderer.allIndices: ", len(mRenderer.allIndices));
    }

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