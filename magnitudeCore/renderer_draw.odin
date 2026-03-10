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