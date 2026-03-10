package magnitudeCore

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"


GPUResources :: struct {
    device          : ^sdl.GPUDevice,
    window          : ^sdl.Window,
    sampler         : ^sdl.GPUSampler,
    depthTexture    : ^sdl.GPUTexture,
    graphicsPipeline : [dynamic]^sdl.GPUGraphicsPipeline,
}

GeometryBuffers :: struct {
    vertexBuffer    : ^sdl.GPUBuffer,
    indexBuffer     : ^sdl.GPUBuffer,
    materialBuffer  : ^sdl.GPUBuffer,
    allVertices     : [dynamic]Vertex,
    allIndices      : [dynamic]u16,
    allMaterials    : [dynamic]MaterialPBR,
    allModelMatrix  : [dynamic]matrix[4,4]f32,
}

SceneData :: struct {
    renderable              : [dynamic]Renderable,
    light                   : [dynamic]Renderable,
    lightNumberOfIndexInBuffer : int,
    lightInfo               : LightInfo,
}


Renderer :: struct {
    gpu      : GPUResources,
    geometry : GeometryBuffers,
    scene    : SceneData,
    camera   : Camera,
    input    : mouseKeyboardInput,
    allTextures : [16]^sdl.GPUTexture,
    textures : map[cstring]int,
}

initRenderer::proc(renderer: ^Renderer, device: ^sdl.GPUDevice, window: ^sdl.Window){

    renderer.gpu.device = device;
    renderer.gpu.window = window;

    initCamera(renderer);
    initLight(renderer);
    initDepthTexture(renderer);
    initInputHandler(renderer);

}


initDepthTexture::proc(renderer: ^Renderer){
    // Define depth texture
    win_size:[2]i32;
    sdl.GetWindowSize(renderer.gpu.window, &win_size.x, &win_size.y);
    depthTextureInfo := sdl.GPUTextureCreateInfo{};
    depthTextureInfo.format = .D32_FLOAT;
    depthTextureInfo.usage = {.DEPTH_STENCIL_TARGET};
    depthTextureInfo.width = u32(win_size.x);
    depthTextureInfo.height = u32(win_size.y);
    depthTextureInfo.layer_count_or_depth = 1;
    depthTextureInfo.num_levels = 1;

    renderer.gpu.depthTexture = sdl.CreateGPUTexture(renderer.gpu.device, depthTextureInfo);
}

createGraphicPipeline::proc(mRenderer:^Renderer, vertexShader:^sdl.GPUShader, fragmentShader:^sdl.GPUShader){

    pipelineInfo := sdl.GPUGraphicsPipelineCreateInfo{};
    // bind shaders
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

    vertexAttributes :[5]sdl.GPUVertexAttribute;
    // Position
    vertexAttributes[0].buffer_slot = 0;
    vertexAttributes[0].location = 0; // layout (location = 0) in shader
    vertexAttributes[0].format = .FLOAT3;
    vertexAttributes[0].offset = 0;

    // Normals
    vertexAttributes[1].buffer_slot = 0;
    vertexAttributes[1].location = 1; // layout (location = 3) in shader
    vertexAttributes[1].format = .FLOAT3;
    vertexAttributes[1].offset = cast(u32)offset_of(Vertex, normals); // 8th float from current buffer position OLD: size_of(f32) * 7

    // Uv
    vertexAttributes[2].buffer_slot = 0;
    vertexAttributes[2].location = 2; // layout (location = 1) in shader
    vertexAttributes[2].format = .FLOAT2;
    vertexAttributes[2].offset = cast(u32)offset_of(Vertex, uv); // 4th float from current buffer position OLD: size_of(f32) * 3

    // ModelMatrixIndex
    vertexAttributes[3].buffer_slot = 0;
    vertexAttributes[3].location = 3; // layout (location = 2) in shader
    vertexAttributes[3].format = .UINT;
    vertexAttributes[3].offset = cast(u32)offset_of(Vertex, modelMatrixIndex); // 8th float from current buffer position OLD: size_of(f32) * 7

    // Material Index
    vertexAttributes[4].buffer_slot = 0;
    vertexAttributes[4].location = 4; // layout (location = 4) in shader
    vertexAttributes[4].format = .UINT;
    vertexAttributes[4].offset = cast(u32)offset_of(Vertex, materialIndex); // 9th float from current buffer position OLD: size_of(f32) * 7

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
    colorTargetDescriptions[0].format = sdl.GetGPUSwapchainTextureFormat(mRenderer.gpu.device, mRenderer.gpu.window);

    pipelineInfo.target_info.num_color_targets = 1;
    pipelineInfo.target_info.color_target_descriptions = &colorTargetDescriptions[0];
    pipelineInfo.target_info.has_depth_stencil_target = true;
    pipelineInfo.target_info.depth_stencil_format = .D32_FLOAT;
    
    pipelineInfo.rasterizer_state.cull_mode = .NONE
    pipelineInfo.rasterizer_state.fill_mode = .FILL

    // Sampler
    samplerInfo := sdl.GPUSamplerCreateInfo{};
    samplerInfo.min_filter = .LINEAR;
    samplerInfo.mag_filter = .LINEAR;
    samplerInfo.mipmap_mode = .LINEAR;
    samplerInfo.address_mode_u = .REPEAT;
    samplerInfo.address_mode_v = .REPEAT;
    samplerInfo.address_mode_w = .REPEAT;

    if mRenderer.gpu.sampler == nil {
        mRenderer.gpu.sampler = sdl.CreateGPUSampler(mRenderer.gpu.device, samplerInfo);
    }
    
    
    // createGraphicPipeline

    newPipeline := sdl.CreateGPUGraphicsPipeline(mRenderer.gpu.device, pipelineInfo)

    if newPipeline == nil {
        errorMsg := sdl.GetError()
        log.error("---------------------------------------------------")
        log.error("FATAL ERROR: Pipeline Creation failed!")
        log.error("ERROR:", errorMsg)
        log.error("---------------------------------------------------")
        return
    }

    append(&mRenderer.gpu.graphicsPipeline, newPipeline)
    log.info("Pipeline creation done") 
    
    // release vertex shader
    sdl.ReleaseGPUShader(mRenderer.gpu.device, vertexShader);
    // release fragment shader
    sdl.ReleaseGPUShader(mRenderer.gpu.device, fragmentShader);
     
}


pushRenderableInBuffer::proc(mRenderer:^Renderer){
    
    buildGeometry(mRenderer);
    uploadGeometry(mRenderer);
    
}


update::proc(mRenderer:^Renderer, deltatime:f32) -> bool{

    buffer := sdl.AcquireGPUCommandBuffer(mRenderer.gpu.device);

    // get the swapchain texture
    swapChainTexture : ^sdl.GPUTexture;
    if sdl.WaitAndAcquireGPUSwapchainTexture(buffer, mRenderer.gpu.window, &swapChainTexture, nil, nil){
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
    depthTargetInfo.texture = mRenderer.gpu.depthTexture;
    depthTargetInfo.load_op = .CLEAR;
    depthTargetInfo.clear_depth = 1;
    depthTargetInfo.store_op = .DONT_CARE;

    // begin render pass
    renderPass := sdl.BeginGPURenderPass(buffer, &color, 1, &depthTargetInfo);

    // Update camera
    updateCamera(mRenderer, &mRenderer.input, deltatime);
    viewMat := linalg.matrix4_look_at_f32(mRenderer.camera.position, mRenderer.camera.position + mRenderer.camera.front, mRenderer.camera.up);

    // Update Light position
    for i := 0; i < len(mRenderer.scene.light); i = i + 1 {
        mRenderer.geometry.allModelMatrix[i] = mRenderer.scene.light[i].modelMatrix;
    }
    // Update model position
    for i := 0; i < len(mRenderer.scene.renderable); i = i + 1 {
        mRenderer.geometry.allModelMatrix[i + len(mRenderer.scene.light)] = mRenderer.scene.renderable[i].modelMatrix;
    }

    // Get Windows size to calculate the projection Matrix
    win_size:[2]i32;
    sdl.GetWindowSize(mRenderer.gpu.window, &win_size.x, &win_size.y);
    uniformBuffer := UBO{
        projMat = linalg.matrix4_perspective_f32(70, f32(win_size.x) / f32(win_size.y), 0.1, 1000),
        viewMat = viewMat,
    }

    n_to_copy := min(len(mRenderer.geometry.allModelMatrix), 100);
    
    if n_to_copy > 0 {
        copy(uniformBuffer.modelMat[:n_to_copy], mRenderer.geometry.allModelMatrix[:n_to_copy]);
    }

    //log.info("UNIFORM Model Matrix: ", uniformBuffer.modelMat[:]);

    // Bind pipeline
    sdl.BindGPUGraphicsPipeline(renderPass, mRenderer.gpu.graphicsPipeline[0]);

    // Uniform 
    sdl.PushGPUVertexUniformData(buffer, 0, &uniformBuffer, size_of(uniformBuffer));
    
    // Light Uniform 
    sdl.PushGPUFragmentUniformData(buffer, 0, &mRenderer.scene.lightInfo, size_of(LightInfo));

    // Camera Uniform
    camera:= linalg.Vector4f32{mRenderer.camera.position.x, mRenderer.camera.position.y, mRenderer.camera.position.z, 0.0};

    sdl.PushGPUFragmentUniformData(buffer, 1, &camera, size_of(camera));


    sdl.BindGPUFragmentStorageBuffers(renderPass, 0, &mRenderer.geometry.materialBuffer, 1);

    textureBindings: [16]sdl.GPUTextureSamplerBinding;

    for i in 0..<16 {
        tex := mRenderer.allTextures[i]
        if tex == nil {
            tex = mRenderer.allTextures[0];
        }
        
        textureBindings[i].texture = tex
        textureBindings[i].sampler = mRenderer.gpu.sampler
    }

    sdl.BindGPUFragmentSamplers(renderPass, 0, &textureBindings[0], 16)

    // bind vertexBuffer
    bufferBindings :[1]sdl.GPUBufferBinding;
    bufferBindings[0].buffer = mRenderer.geometry.vertexBuffer;
    bufferBindings[0].offset = 0;

    sdl.BindGPUVertexBuffers(renderPass, 0, &bufferBindings[0], 1);
    //sdl.DrawGPUPrimitives(renderPass, cast(u32)len(vertices), 1, 0, 0);
    sdl.BindGPUIndexBuffer(renderPass, {buffer = mRenderer.geometry.indexBuffer}, ._16BIT);
    sdl.DrawGPUIndexedPrimitives(renderPass, cast(u32)len(mRenderer.geometry.allIndices[mRenderer.scene.lightNumberOfIndexInBuffer:]), 1, cast(u32)mRenderer.scene.lightNumberOfIndexInBuffer, 0, 0);

    // Light 
    // Bind pipeline
    sdl.BindGPUGraphicsPipeline(renderPass, mRenderer.gpu.graphicsPipeline[1]);
    uniformBuffer.modelMat[0] = linalg.matrix4_translate_f32(mRenderer.scene.lightInfo.lightPosition.xyz);
    // Uniform 
    sdl.PushGPUVertexUniformData(buffer, 0, &uniformBuffer, size_of(uniformBuffer));
    sdl.BindGPUVertexBuffers(renderPass, 0, &bufferBindings[0], 1);
    sdl.BindGPUIndexBuffer(renderPass, {buffer = mRenderer.geometry.indexBuffer}, ._16BIT);
    sdl.DrawGPUIndexedPrimitives(renderPass, cast(u32)mRenderer.scene.lightNumberOfIndexInBuffer, 1, 0, 0, 0);

    // end render pass
    sdl.EndGPURenderPass(renderPass);

    // submit command buffer
    if sdl.SubmitGPUCommandBuffer(buffer){
        //log.info("Send buffer to GPU done correctly", true);
    }

    return inputHandler(&mRenderer.input);

}


cleanRenderer::proc(mRenderer:^Renderer){
    sdl.ReleaseGPUBuffer(mRenderer.gpu.device, mRenderer.geometry.vertexBuffer);
    sdl.ReleaseGPUBuffer(mRenderer.gpu.device, mRenderer.geometry.indexBuffer);
    sdl.ReleaseGPUBuffer(mRenderer.gpu.device, mRenderer.geometry.materialBuffer);

    sdl.ReleaseGPUTexture(mRenderer.gpu.device, mRenderer.gpu.depthTexture);

    sdl.ReleaseGPUSampler(mRenderer.gpu.device, mRenderer.gpu.sampler);
    //sdl.ReleaseGPUTexture(mRenderer.gpu.device, mRenderer.defaultTexture);
    for tex in mRenderer.allTextures {
        if tex != nil {
            sdl.ReleaseGPUTexture(mRenderer.gpu.device, tex);
        }
    }
    sdl.ReleaseGPUGraphicsPipeline(mRenderer.gpu.device, mRenderer.gpu.graphicsPipeline[0]);
    sdl.ReleaseGPUGraphicsPipeline(mRenderer.gpu.device, mRenderer.gpu.graphicsPipeline[1]);
    sdl.DestroyGPUDevice(mRenderer.gpu.device);
    sdl.DestroyWindow(mRenderer.gpu.window);
}
