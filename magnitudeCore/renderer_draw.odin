package magnitudeCore

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"

// Uniform struct to send to GPU
UBO::struct #align(16){
    projMat : matrix[4,4]f32,
    viewMat : matrix[4,4]f32,
    modelMat : [100]matrix[4,4]f32,
}

// Light info
LightInfo::struct #align(16){
    lightPosition : linalg.Vector4f32,
    lightColor : linalg.Vector4f32, 
    lightIntensity : linalg.Vector4f32, 
}


_syncModelMatrices :: proc(renderer: ^Renderer) {
    // Update Light position
    for i in 0..<len(renderer.scene.light) {
        renderer.geometry.allModelMatrix[i] = renderer.scene.light[i].modelMatrix
    }
    // Update model position
    for i: u32 = 0; i < cast(u32)len(renderer.scene.renderableMap); i += 1 {
        idx := renderer.scene.renderableMapIndex[i]
        renderer.geometry.allModelMatrix[i + cast(u32)len(renderer.scene.light)] = renderer.scene.renderableMap[idx].modelMatrix
    }
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
    //updateCamera(mRenderer, &mRenderer.input, deltatime);
    viewMat := linalg.matrix4_look_at_f32(mRenderer.camera.position, mRenderer.camera.position + mRenderer.camera.front, mRenderer.camera.up);

    // Update Renderable position
    _syncModelMatrices(mRenderer);

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

    // bind vertexBuffer
    bufferBindings :[1]sdl.GPUBufferBinding;
    bufferBindings[0].buffer = mRenderer.geometry.vertexBuffer;
    bufferBindings[0].offset = 0;

    // Texture Bindings

    for numOfTexturebinds := 0 ; numOfTexturebinds < len(mRenderer.scene.materialIndexForTexturebind); numOfTexturebinds = numOfTexturebinds + 1{

        begin := mRenderer.scene.materialIndexForTexturebind[numOfTexturebinds];
        end := len(mRenderer.geometry.allIndices);
        if numOfTexturebinds + 1 < len(mRenderer.scene.materialIndexForTexturebind) {
            end = cast(int)mRenderer.scene.materialIndexForTexturebind[numOfTexturebinds + 1];
        }   

        sdl.BindGPUFragmentSamplers(renderPass, 0, &mRenderer.cachedTextureBindings[16 * numOfTexturebinds], 16)

        sdl.BindGPUVertexBuffers(renderPass, 0, &bufferBindings[0], 1);
        sdl.BindGPUIndexBuffer(renderPass, {buffer = mRenderer.geometry.indexBuffer}, ._16BIT);
        sdl.DrawGPUIndexedPrimitives(renderPass, cast(u32)len(mRenderer.geometry.allIndices[begin:end]), 1, cast(u32)begin, 0, 0);
        
    }

    // Light 
    // Bind pipeline
    sdl.BindGPUGraphicsPipeline(renderPass, mRenderer.gpu.graphicsPipeline[1]);
    uniformBuffer.modelMat[0] = linalg.matrix4_translate_f32(mRenderer.scene.lightInfo.lightPosition.xyz);
    // Uniform 
    sdl.PushGPUVertexUniformData(buffer, 0, &uniformBuffer, size_of(uniformBuffer));
    sdl.BindGPUVertexBuffers(renderPass, 0, &bufferBindings[0], 1);
    sdl.BindGPUIndexBuffer(renderPass, {buffer = mRenderer.geometry.indexBuffer}, ._16BIT);
    sdl.DrawGPUIndexedPrimitives(renderPass, cast(u32)mRenderer.scene.lightNumberOfIndexInBuffer, 1, 0, 0, 0);


    // Collision Boundig Box
    //if mRenderer.debugCollisionIsActive {
        // bind vertexBuffer
        collisionBufferBindings :[1]sdl.GPUBufferBinding;
        collisionBufferBindings[0].buffer = mRenderer.geometry.collisionBuffer;
        collisionBufferBindings[0].offset = 0;
        // Bind pipeline
        sdl.BindGPUGraphicsPipeline(renderPass, mRenderer.gpu.graphicsPipeline[2]);
        // Uniform 
        sdl.PushGPUVertexUniformData(buffer, 0, &uniformBuffer, size_of(uniformBuffer));
        sdl.BindGPUVertexBuffers(renderPass, 0, &collisionBufferBindings[0], 1);
        sdl.BindGPUIndexBuffer(renderPass, {buffer = mRenderer.geometry.collisionIndexBuffer}, ._16BIT);
        sdl.DrawGPUIndexedPrimitives(renderPass, cast(u32)len(mRenderer.geometry.allCollisionIndices[:]), 1, 0, 0, 0);
    //}
   


    // end render pass
    sdl.EndGPURenderPass(renderPass);

    // submit command buffer
    if sdl.SubmitGPUCommandBuffer(buffer){
        //log.info("Send buffer to GPU done correctly", true);
    }

    return inputHandler(&mRenderer.input);

}