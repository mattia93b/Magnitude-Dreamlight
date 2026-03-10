package magnitudeCore

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"


VertexInstance :: struct #align(16) {
    position : linalg.Vector3f32,
    _pad0 : f32,
    normals : linalg.Vector3f32,
    _pad1 : f32,
    uv : linalg.Vector2f32,
    _pad2 : [2]f32,
}

InstanceData :: struct #align(16) {
    modelMatrixIndex : u32,
    materialIndex : u32,
    _pad2 : [2]u32,
    //rgba : linalg.Vector4f32,
}

/*
createGraphicPipelineForInstance::proc(mRenderer:^Renderer, vertexShader:^sdl.GPUShader, fragmentShader:^sdl.GPUShader){

    pipelineInfo := sdl.GPUGraphicsPipelineCreateInfo{};
    // bind shaders
    pipelineInfo.vertex_shader = vertexShader;
    pipelineInfo.fragment_shader = fragmentShader;

    pipelineInfo.primitive_type = .TRIANGLELIST;
    //
    vertexBufferDescriptions :[2]sdl.GPUVertexBufferDescription;
    // SLOT 0: Vertex Data
    vertexBufferDescriptions[0].slot = 0;
    vertexBufferDescriptions[0].input_rate = .VERTEX;
    vertexBufferDescriptions[0].instance_step_rate = 0;
    vertexBufferDescriptions[0].pitch = size_of(VertexInstance);
    // SLOT 1: Instance Data
    vertexBufferDescriptions[1].slot = 1;
    vertexBufferDescriptions[1].input_rate = .INSTANCE;
    vertexBufferDescriptions[1].instance_step_rate = 1;
    vertexBufferDescriptions[1].pitch = size_of(InstanceData);

    pipelineInfo.vertex_input_state.num_vertex_buffers = 2;
    pipelineInfo.vertex_input_state.vertex_buffer_descriptions = &vertexBufferDescriptions[0];

    vertexAttributes :[5]sdl.GPUVertexAttribute;
    // SLOT 0 VERTEX
    // Position
    vertexAttributes[0].buffer_slot = 0;
    vertexAttributes[0].location = 0;
    vertexAttributes[0].format = .FLOAT3;
    vertexAttributes[0].offset = 0;
    // Normals
    vertexAttributes[1].buffer_slot = 0;
    vertexAttributes[1].location = 1;
    vertexAttributes[1].format = .FLOAT3;
    vertexAttributes[1].offset = cast(u32)offset_of(VertexInstance, normals); 
    // UVs
    vertexAttributes[2].buffer_slot = 0;
    vertexAttributes[2].location = 2;
    vertexAttributes[2].format = .FLOAT2;
    vertexAttributes[2].offset = cast(u32)offset_of(VertexInstance, uv);

    /// SLOT 1 INSTANCE
    // Model Matrix Index
    vertexAttributes[3].buffer_slot = 1;
    vertexAttributes[3].location = 3;
    vertexAttributes[3].format = .UINT;
    vertexAttributes[3].offset = cast(u32)offset_of(InstanceData, modelMatrixIndex);
    // Material Index
    vertexAttributes[4].buffer_slot = 1;
    vertexAttributes[4].location = 4;
    vertexAttributes[4].format = .UINT;
    vertexAttributes[4].offset = cast(u32)offset_of(InstanceData, materialIndex);

    pipelineInfo.vertex_input_state.num_vertex_attributes = 5;
    pipelineInfo.vertex_input_state.vertex_attributes = &vertexAttributes[0];
    
    // Depth
    depthStencilState := sdl.GPUDepthStencilState{}
    depthStencilState.enable_depth_test = true;
    depthStencilState.enable_depth_write = true;
    depthStencilState.compare_op = .LESS;

    pipelineInfo.depth_stencil_state = depthStencilState;


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
    pipelineInfo.target_info.has_depth_stencil_target = true;
    pipelineInfo.target_info.depth_stencil_format = .D32_FLOAT;
    
    pipelineInfo.rasterizer_state.cull_mode = .NONE
    pipelineInfo.rasterizer_state.fill_mode = .FILL
    
    newPipeline := sdl.CreateGPUGraphicsPipeline(mRenderer.device, pipelineInfo)

    if newPipeline == nil {
        errorMsg := sdl.GetError()
        log.error("---------------------------------------------------")
        log.error("FATAL ERROR: Pipeline Creation failed!")
        log.error("ERROR:", errorMsg)
        log.error("---------------------------------------------------")
        return
    }

    append(&mRenderer.graphicsPipeline, newPipeline)
    log.info("Pipeline creation done") 
    
    // release vertex shader
    sdl.ReleaseGPUShader(mRenderer.device, vertexShader);
    // release fragment shader
    sdl.ReleaseGPUShader(mRenderer.device, fragmentShader);
     
}

pushRenderableInBufferForInstance::proc(mRenderer:^Renderer){

    for numberProcessedVertex:= 0; numberProcessedVertex < len(mRenderer.renderable[0].vertex); numberProcessedVertex = numberProcessedVertex + 1 {
        append(&mRenderer.allVerticesForInstance, VertexInstance{position = mRenderer.renderable[0].vertex[numberProcessedVertex], normals= mRenderer.renderable[0].normals[numberProcessedVertex], uv = {0.0, 0.0}});
    }

    for idx in mRenderer.renderable[0].index {
        append(&mRenderer.allIndices, u16(idx));
    }
    
    for renderable in mRenderer.renderable {
        modelMatrixIndex := cast(u32)len(mRenderer.allModelMatrix);
        append(&mRenderer.allModelMatrix, renderable.modelMatrix);

        materialIndex := cast(u32)len(mRenderer.allMaterials);
        append(&mRenderer.allMaterials, renderable.materialPBR);

        append(&mRenderer.allInstance, InstanceData{
            modelMatrixIndex = modelMatrixIndex,
            materialIndex = materialIndex,
        })
    }

    // VERTEX BUFFER
    vertex_bytes := len(mRenderer.allVerticesForInstance) * size_of(VertexInstance);

    bufferInfo := sdl.GPUBufferCreateInfo{};
    bufferInfo.size = cast(u32)vertex_bytes;
    bufferInfo.usage = {.VERTEX};
    mRenderer.vertexBuffer= sdl.CreateGPUBuffer(mRenderer.device, bufferInfo);

    // INDEX BUFFER
    index_bytes := len(mRenderer.allIndices) * size_of(u16);

    indexBufferInfo := sdl.GPUBufferCreateInfo{};
    indexBufferInfo.size = cast(u32)index_bytes;
    indexBufferInfo.usage = {.INDEX};
    mRenderer.indexBuffer= sdl.CreateGPUBuffer(mRenderer.device, indexBufferInfo);

    // INSTANCE BUFFER
    instance_bytes := len(mRenderer.allInstance) * size_of(InstanceData);

    instanceBufferInfo := sdl.GPUBufferCreateInfo{};
    instanceBufferInfo.size = cast(u32)instance_bytes;
    instanceBufferInfo.usage = {.VERTEX};
    mRenderer.instanceBuffer= sdl.CreateGPUBuffer(mRenderer.device, instanceBufferInfo);

    // MATERIAL BUFFER
    materials_bytes := len(mRenderer.allMaterials) * size_of(Material);

    materialsBufferInfo := sdl.GPUBufferCreateInfo{};
    materialsBufferInfo.size = cast(u32)materials_bytes;
    materialsBufferInfo.usage = {.GRAPHICS_STORAGE_READ};
    mRenderer.materialBuffer= sdl.CreateGPUBuffer(mRenderer.device, materialsBufferInfo);

    vertex_offset_in_transfer := 0;
    index_offset_in_transfer  := alignUp(vertex_bytes, 256);
    instance_offset_in_transfer  := alignUp(index_offset_in_transfer + index_bytes, 256);
    materials_offset_in_transfer := alignUp(instance_offset_in_transfer + instance_bytes, 256);

    total_transfer_size := materials_offset_in_transfer + materials_bytes;

    // Transfer Buffer 
    transferInfo := sdl.GPUTransferBufferCreateInfo{};
    transferInfo.size = cast(u32)total_transfer_size;
    transferInfo.usage = .UPLOAD;
    mRenderer.transferBuffer = sdl.CreateGPUTransferBuffer(mRenderer.device, transferInfo);

    data:= transmute([^]byte)sdl.MapGPUTransferBuffer(mRenderer.device, mRenderer.transferBuffer, false);
    // Vertex copy
    sdl.memcpy(data, raw_data(mRenderer.allVerticesForInstance), cast(uint)vertex_bytes);
    // Index copy
    sdl.memcpy(data[index_offset_in_transfer:], raw_data(mRenderer.allIndices), cast(uint)index_bytes);
    // Instace copy
    sdl.memcpy(data[instance_offset_in_transfer:], raw_data(mRenderer.allInstance), cast(uint)instance_bytes);
    // Materials copy
    sdl.memcpy(data[materials_offset_in_transfer:], raw_data(mRenderer.allMaterials), cast(uint)materials_bytes);

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
    indexLocation.offset = cast(u32)index_offset_in_transfer;//cast(u32)vertex_bytes;
    
    indexRegion := sdl.GPUBufferRegion{};
    indexRegion.buffer = mRenderer.indexBuffer;
    indexRegion.size = cast(u32)index_bytes;
    indexRegion.offset = 0;
    // Upload Index
    sdl.UploadToGPUBuffer(copyPass, indexLocation, indexRegion, true);


    // INSTANCE BUFFER UPLOAD
    instanceLocation:= sdl.GPUTransferBufferLocation{};
    instanceLocation.transfer_buffer = mRenderer.transferBuffer;
    instanceLocation.offset = cast(u32)instance_offset_in_transfer;//cast(u32)vertex_bytes;
    
    instanceRegion := sdl.GPUBufferRegion{};
    instanceRegion.buffer = mRenderer.instanceBuffer;
    instanceRegion.size = cast(u32)instance_bytes;
    instanceRegion.offset = 0;
    // Upload Instance
    sdl.UploadToGPUBuffer(copyPass, instanceLocation, instanceRegion, true);


    // MATERIALS BUFFER UPLOAD
    materialsLocation:= sdl.GPUTransferBufferLocation{};   
    materialsLocation.transfer_buffer = mRenderer.transferBuffer;
    materialsLocation.offset = cast(u32)materials_offset_in_transfer;//cast(u32)vertex_bytes + cast(u32)index_bytes;

    materialsRegion := sdl.GPUBufferRegion{};
    materialsRegion.buffer = mRenderer.materialBuffer;
    materialsRegion.size = cast(u32)materials_bytes;
    materialsRegion.offset = 0;
    // Upload Materials
    sdl.UploadToGPUBuffer(copyPass, materialsLocation, materialsRegion, true);


    sdl.EndGPUCopyPass(copyPass);
    if sdl.SubmitGPUCommandBuffer(mRenderer.buffer){
        log.info("Submit buffert to GPU succesfully", true);
    }

    // Define depth texture
    win_size:[2]i32;
    sdl.GetWindowSize(mRenderer.window, &win_size.x, &win_size.y);
    depthTextureInfo := sdl.GPUTextureCreateInfo{};
    depthTextureInfo.format = .D32_FLOAT;
    depthTextureInfo.usage = {.DEPTH_STENCIL_TARGET};
    depthTextureInfo.width = u32(win_size.x);
    depthTextureInfo.height = u32(win_size.y);
    depthTextureInfo.layer_count_or_depth = 1;
    depthTextureInfo.num_levels = 1;

    mRenderer.depthTexture = sdl.CreateGPUTexture(mRenderer.device, depthTextureInfo);


    // Input handler definition
    mRenderer.inputHandler = mouseKeyboardInput{}
    mRenderer.inputHandler.mouseDown = false;
    mRenderer.inputHandler.first = true;

    // Camera set up
    mRenderer.rCamera.position = linalg.Vector3f32{0, 10, 20};
    mRenderer.rCamera.front = linalg.Vector3f32{0, 0, -10};
    mRenderer.rCamera.up = linalg.Vector3f32{0, 1, 0};
    mRenderer.rCamera.yaw = -90.0;
    mRenderer.rCamera.pitch = 0.0;
    mRenderer.rCamera.firstMouse = true;

    // Light set up
    mRenderer.lightInfo.lightPosition = {0.0, 15.0, -10.0, 0.0};
    mRenderer.lightInfo.lightColor = {1.0, 1.0, 1.0, 1.0};
    mRenderer.lightInfo.lightIntensity = {1.0, 1.0, 1.0, 1.0};
}

updateInstance::proc(mRenderer:^Renderer, deltatime:f32) -> bool{

    mRenderer.buffer = sdl.AcquireGPUCommandBuffer(mRenderer.device);

    // get the swapchain texture
    swapChainTexture : ^sdl.GPUTexture;
    if sdl.WaitAndAcquireGPUSwapchainTexture(mRenderer.buffer, mRenderer.window, &swapChainTexture, nil, nil){
        //log.info("correct bindings between device and window", true);
    }
    // create color target
    color : sdl.GPUColorTargetInfo;
    //color.clear_color = {255/255.0, 219/255.0, 187/255.0, 255/255.0};
    color.clear_color = {0, 0, 0, 0};
    color.load_op = .CLEAR;
    color.store_op = .STORE;
    color.texture = swapChainTexture;
    // Depth
    depthTargetInfo := sdl.GPUDepthStencilTargetInfo{};
    depthTargetInfo.texture = mRenderer.depthTexture;
    depthTargetInfo.load_op = .CLEAR;
    depthTargetInfo.clear_depth = 1;
    depthTargetInfo.store_op = .DONT_CARE;

    // begin render pass
    renderPass := sdl.BeginGPURenderPass(mRenderer.buffer, &color, 1, &depthTargetInfo);

    // Update camera
    updateCamera(mRenderer, &mRenderer.inputHandler, deltatime);
    viewMat := linalg.matrix4_look_at_f32(mRenderer.rCamera.position, mRenderer.rCamera.position + mRenderer.rCamera.front, mRenderer.rCamera.up);

    // Update Light position

    // Get Windows size to calculate the projection Matrix
    win_size:[2]i32;
    sdl.GetWindowSize(mRenderer.window, &win_size.x, &win_size.y);
    uniformBuffer := UBO{
        projMat = linalg.matrix4_perspective_f32(70, f32(win_size.x) / f32(win_size.y), 0.1, 1000),
        viewMat = viewMat,
    }

    n_to_copy := min(len(mRenderer.allModelMatrix), 100);
    
    if n_to_copy > 0 {
        copy(uniformBuffer.modelMat[:n_to_copy], mRenderer.allModelMatrix[:n_to_copy]);
    }

    //log.info("UNIFORM Model Matrix: ", uniformBuffer.modelMat[:]);

    // Bind pipeline
    sdl.BindGPUGraphicsPipeline(renderPass, mRenderer.graphicsPipeline[0]);

    // Uniform 
    sdl.PushGPUVertexUniformData(mRenderer.buffer, 0, &uniformBuffer, size_of(uniformBuffer));
    
    // Light Uniform 
    sdl.PushGPUFragmentUniformData(mRenderer.buffer, 0, &mRenderer.lightInfo, size_of(LightInfo));

    // Camera Uniform
    camera:= linalg.Vector4f32{mRenderer.rCamera.position.x, mRenderer.rCamera.position.y, mRenderer.rCamera.position.z, 0.0};

    sdl.PushGPUFragmentUniformData(mRenderer.buffer, 1, &camera, size_of(camera));

    // Material Buffer
    sdl.BindGPUFragmentStorageBuffers(renderPass, 0, &mRenderer.materialBuffer, 1);

    // bind vertexBuffer
    bufferBindings :[2]sdl.GPUBufferBinding;
    bufferBindings[0].buffer = mRenderer.vertexBuffer;
    bufferBindings[0].offset = 0;
    bufferBindings[1].buffer = mRenderer.instanceBuffer;
    bufferBindings[1].offset = 0;

    sdl.BindGPUVertexBuffers(renderPass, 0, &bufferBindings[0], 2);
    //sdl.DrawGPUPrimitives(renderPass, cast(u32)len(vertices), 1, 0, 0);
    sdl.BindGPUIndexBuffer(renderPass, {buffer = mRenderer.indexBuffer}, ._16BIT);
    num_indices := cast(u32)len(mRenderer.allIndices)
    num_instances := cast(u32)len(mRenderer.allInstance)
    sdl.DrawGPUIndexedPrimitives(renderPass, num_indices, num_instances, 0, 0, 0);

    // Light 
    /*// Bind pipeline
    sdl.BindGPUGraphicsPipeline(renderPass, mRenderer.graphicsPipeline[1]);
    uniformBuffer.modelMat[0] = linalg.matrix4_translate_f32(mRenderer.lightInfo.lightPosition.xyz);
    // Uniform 
    sdl.PushGPUVertexUniformData(mRenderer.buffer, 0, &uniformBuffer, size_of(uniformBuffer));
    sdl.BindGPUVertexBuffers(renderPass, 0, &bufferBindings[0], 1);
    sdl.BindGPUIndexBuffer(renderPass, {buffer = mRenderer.indexBuffer}, ._16BIT);
    sdl.DrawGPUIndexedPrimitives(renderPass, cast(u32)mRenderer.lightNumberOfIndexInBuffer, 1, 0, 0, 0);*/

    // end render pass
    sdl.EndGPURenderPass(renderPass);

    // submit command buffer
    if sdl.SubmitGPUCommandBuffer(mRenderer.buffer){
        //log.info("Send buffer to GPU done correctly", true);
    }

    return inputHandler(&mRenderer.inputHandler);

}*/
