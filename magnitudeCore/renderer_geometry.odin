package magnitudeCore

import "core:math/linalg/glsl"
// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"
// slcie
import "core:slice"


Vertex::struct #align(16){
    position : linalg.Vector3f32,
    _pad0 : f32,     
    normals : linalg.Vector3f32,
    _pad1 : f32,   
    uv : linalg.Vector2f32,
    _pad2 : [2]f32,
    modelMatrixIndex : u32,
    materialIndex : u32,
    _pad3 : [3]f32,
}


CollisionVertex::struct #align(16){
    position : linalg.Vector3f32,
    modelMatrixIndex : u32,
}


alignUp :: proc(value: int, alignment: int) -> int {
    return (value + alignment - 1) & ~(alignment - 1)
}


//// RENDERABLE

addRenderable::proc(mRenderer:^Renderer, renderable:Renderable){
    //append(&mRenderer.scene.renderable, renderable);
}

renderable_order :: proc(lhs, rhs: Renderable) -> bool {
    return lhs.materialID < rhs.materialID;
}

_sortRenderablesByMaterial::proc(renderer: ^Renderer){

    indexCounter :u32= 0;
    for mat in renderer.scene.material{
        for key, val in renderer.scene.renderableMap {
            if val.materialID == indexCounter{
                append(&renderer.scene.renderableMapIndex, key);
            }
        }
        indexCounter = indexCounter + 1;
    }
    log.infof("orderer renderable for material: ", renderer.scene.renderableMapIndex);

}

_buildLightGeometry::proc(renderer: ^Renderer){

    for el in renderer.scene.light{

        modelMatrixIndex := cast(u32)len(renderer.geometry.allModelMatrix);
        append(&renderer.geometry.allModelMatrix, el.modelMatrix);
        // Calculate the offset before pushing new data to the VertexBuffer
        vertex_offset := u32(len(renderer.geometry.allVertices));
        // Push all vertex indices information inside the IndexBuffer of the renderer
        for idx in el.index {
            append(&renderer.geometry.allIndices, u32(idx) + vertex_offset);
        }
        // Push all vertex information inside a Vertex Object and store it in the VertexBuffer of the renderer
        for numberProcessedVertex:= 0; numberProcessedVertex < len(el.vertex); numberProcessedVertex = numberProcessedVertex + 1 {
            append(&renderer.geometry.allVertices, Vertex{position = el.vertex[numberProcessedVertex], uv = el.UVs[numberProcessedVertex],  modelMatrixIndex = modelMatrixIndex, normals= el.normals[numberProcessedVertex]})
        }
    }

    renderer.scene.lightNumberOfIndexInBuffer = len(renderer.geometry.allIndices);
}


_buildRenderableGeometry::proc(renderer: ^Renderer){
    
    append(&renderer.scene.materialIndexForTexturebind, cast(u32)len(renderer.geometry.allIndices));
    // Push renderable after light object
    //for i in renderer.scene.renderableMapIndex{
    for i:u32=0 ; i < cast(u32)len(renderer.scene.renderableMapIndex); i = i + 1{
        if renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].materialID % 3 == 0 && renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].materialID != 0 && i > 0 {
            if renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i - 1]].materialID != renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].materialID {
                //log.infof("Pre Material ID: ", renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i - 1]].materialID);
                //log.infof("Material ID: ", renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].materialID);
                append(&renderer.scene.materialIndexForTexturebind, cast(u32)len(renderer.geometry.allIndices));
            }
        }

        // calculate model matrix Index and append model matrix to allModelMatrixArray
        modelMatrixIndex := cast(f32)len(renderer.geometry.allModelMatrix);
        append(&renderer.geometry.allModelMatrix, renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].modelMatrix);
        // Calculate the offset before pushing new data to the VertexBuffer
        vertex_offset := u32(len(renderer.geometry.allVertices));
        // Push all vertex indices information inside the IndexBuffer of the renderer
        for idx in renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].index {
            append(&renderer.geometry.allIndices, u32(idx) + vertex_offset);
        }
        // COLLISION INDEX
        vertex_collision_offset := u32(len(renderer.geometry.allCollisionVertices));
        for idx in renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].collisionIndices {
            append(&renderer.geometry.allCollisionIndices, u32(idx) + vertex_collision_offset);
        }

        // Push all vertex information inside a Vertex Object and store it in the VertexBuffer of the renderer
        for numberProcessedVertex:= 0; numberProcessedVertex < len(renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].vertex); numberProcessedVertex = numberProcessedVertex + 1 {
            append(&renderer.geometry.allVertices, Vertex{position = renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].vertex[numberProcessedVertex], uv =  renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].UVs[numberProcessedVertex],  modelMatrixIndex = cast(u32)modelMatrixIndex, normals= renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].normals[numberProcessedVertex], materialIndex = renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].materialID});
            
        }
        // COLLISION BUFFER
        for numberProcessedVertex:= 0; numberProcessedVertex < len(renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].collisionCorners); numberProcessedVertex = numberProcessedVertex + 1 {
            append(&renderer.geometry.allCollisionVertices, CollisionVertex{position= renderer.scene.renderableMap[renderer.scene.renderableMapIndex[i]].collisionCorners[numberProcessedVertex], modelMatrixIndex = cast(u32)modelMatrixIndex});
        }

    } 
    log.infof("change Texture array: ", renderer.scene.materialIndexForTexturebind);
}

buildGeometry::proc(renderer: ^Renderer){
    // Sort Renderable by Material
   _sortRenderablesByMaterial(renderer);
    // Push Light inside buffer
    _buildLightGeometry(renderer);
    // Push Renderable inside buffer
    _buildRenderableGeometry(renderer);
}


uploadGeometry::proc(renderer: ^Renderer){

    vertex_bytes := len(renderer.geometry.allVertices) * size_of(Vertex);

    bufferInfo := sdl.GPUBufferCreateInfo{};
    bufferInfo.size = cast(u32)vertex_bytes;
    bufferInfo.usage = {.VERTEX};
    renderer.geometry.vertexBuffer= sdl.CreateGPUBuffer(renderer.gpu.device, bufferInfo);


    index_bytes := len(renderer.geometry.allIndices) * size_of(u32);

    indexBufferInfo := sdl.GPUBufferCreateInfo{};
    indexBufferInfo.size = cast(u32)index_bytes;
    indexBufferInfo.usage = {.INDEX};
    renderer.geometry.indexBuffer= sdl.CreateGPUBuffer(renderer.gpu.device, indexBufferInfo);

    modelMatrix_bytes := len(renderer.geometry.allModelMatrix) * size_of(matrix[4,4]f32);

    modelMatrixBufferInfo := sdl.GPUBufferCreateInfo{};
    modelMatrixBufferInfo.size = cast(u32)modelMatrix_bytes;
    modelMatrixBufferInfo.usage = {.GRAPHICS_STORAGE_READ};
    renderer.geometry.modelMatrixBuffer= sdl.CreateGPUBuffer(renderer.gpu.device, modelMatrixBufferInfo);

    materials_bytes := len(renderer.geometry.allMaterials) * size_of(MaterialPBR);

    materialsBufferInfo := sdl.GPUBufferCreateInfo{};
    materialsBufferInfo.size = cast(u32)materials_bytes;
    materialsBufferInfo.usage = {.GRAPHICS_STORAGE_READ};
    renderer.geometry.materialBuffer= sdl.CreateGPUBuffer(renderer.gpu.device, materialsBufferInfo);

    vertex_offset_in_transfer := 0
    index_offset_in_transfer  := alignUp(vertex_bytes, 256)
    modelMatrix_offset_in_transfer := alignUp(index_offset_in_transfer + index_bytes, 256)
    materials_offset_in_transfer := alignUp(modelMatrix_offset_in_transfer + index_bytes, 256)
    total_transfer_size := materials_offset_in_transfer + materials_bytes

    // Transfer Buffer 
    transferInfo := sdl.GPUTransferBufferCreateInfo{};
    transferInfo.size = cast(u32)total_transfer_size;//cast(u32)(vertex_bytes + index_bytes + materials_bytes);
    transferInfo.usage = .UPLOAD;
    transferBuffer := sdl.CreateGPUTransferBuffer(renderer.gpu.device, transferInfo);

    data:= transmute([^]byte)sdl.MapGPUTransferBuffer(renderer.gpu.device, transferBuffer, false);
    // Vertex copy
    sdl.memcpy(data, raw_data(renderer.geometry.allVertices), cast(uint)vertex_bytes);
    // Index copy
    sdl.memcpy(data[index_offset_in_transfer:], raw_data(renderer.geometry.allIndices), cast(uint)index_bytes);
    // Model Matrix
    sdl.memcpy(data[modelMatrix_offset_in_transfer:], raw_data(renderer.geometry.allModelMatrix), cast(uint)modelMatrix_bytes);
    // Materials copy
    sdl.memcpy(data[materials_offset_in_transfer:], raw_data(renderer.geometry.allMaterials), cast(uint)materials_bytes);

    sdl.UnmapGPUTransferBuffer(renderer.gpu.device, transferBuffer);

    // acquire the command buffer
    buffer := sdl.AcquireGPUCommandBuffer(renderer.gpu.device);
    copyPass := sdl.BeginGPUCopyPass(buffer);
    
    // VERTEX BUFFER UPLOAD
    vertexLocation:= sdl.GPUTransferBufferLocation{};
    vertexLocation.transfer_buffer = transferBuffer;
    vertexLocation.offset = 0;

    vertexRegion := sdl.GPUBufferRegion{};
    vertexRegion.buffer = renderer.geometry.vertexBuffer;
    vertexRegion.size = cast(u32)vertex_bytes;
    vertexRegion.offset = 0;
    // Upload Vertex
    sdl.UploadToGPUBuffer(copyPass, vertexLocation, vertexRegion, true);


    // INDEX BUFFER UPLOAD
    indexLocation:= sdl.GPUTransferBufferLocation{};
    indexLocation.transfer_buffer = transferBuffer;
    indexLocation.offset = cast(u32)index_offset_in_transfer;//cast(u32)vertex_bytes;
    
    indexRegion := sdl.GPUBufferRegion{};
    indexRegion.buffer = renderer.geometry.indexBuffer;
    indexRegion.size = cast(u32)index_bytes;
    indexRegion.offset = 0;
    // Upload Index
    sdl.UploadToGPUBuffer(copyPass, indexLocation, indexRegion, true);

    // MODEL MATRIX BUFFER UPLOAD
    modelMatrixLocation:= sdl.GPUTransferBufferLocation{};   
    modelMatrixLocation.transfer_buffer = transferBuffer;
    modelMatrixLocation.offset = cast(u32)modelMatrix_offset_in_transfer;//cast(u32)vertex_bytes + cast(u32)index_bytes;

    modelMatrixRegion := sdl.GPUBufferRegion{};
    modelMatrixRegion.buffer = renderer.geometry.modelMatrixBuffer;
    modelMatrixRegion.size = cast(u32)modelMatrix_bytes;
    modelMatrixRegion.offset = 0;
    // Upload ModelMatrix
    sdl.UploadToGPUBuffer(copyPass, modelMatrixLocation, modelMatrixRegion, true);

    // MATERIALS BUFFER UPLOAD
    materialsLocation:= sdl.GPUTransferBufferLocation{};   
    materialsLocation.transfer_buffer = transferBuffer;
    materialsLocation.offset = cast(u32)materials_offset_in_transfer;//cast(u32)vertex_bytes + cast(u32)index_bytes;

    materialsRegion := sdl.GPUBufferRegion{};
    materialsRegion.buffer = renderer.geometry.materialBuffer;
    materialsRegion.size = cast(u32)materials_bytes;
    materialsRegion.offset = 0;
    // Upload Materials
    sdl.UploadToGPUBuffer(copyPass, materialsLocation, materialsRegion, true);

    sdl.EndGPUCopyPass(copyPass);
    if sdl.SubmitGPUCommandBuffer(buffer){
        log.info("Submit buffert to GPU succesfully", true);
    }

    sdl.ReleaseGPUTransferBuffer(renderer.gpu.device, transferBuffer);

}

uploadCollisionGeometry::proc(renderer: ^Renderer){

    vertex_bytes := len(renderer.geometry.allCollisionVertices) * size_of(CollisionVertex);

    bufferInfo := sdl.GPUBufferCreateInfo{};
    bufferInfo.size = cast(u32)vertex_bytes;
    bufferInfo.usage = {.VERTEX};
    renderer.geometry.collisionBuffer= sdl.CreateGPUBuffer(renderer.gpu.device, bufferInfo);


    index_bytes := len(renderer.geometry.allCollisionIndices) * size_of(u32);

    indexBufferInfo := sdl.GPUBufferCreateInfo{};
    indexBufferInfo.size = cast(u32)index_bytes;
    indexBufferInfo.usage = {.INDEX};
    renderer.geometry.collisionIndexBuffer= sdl.CreateGPUBuffer(renderer.gpu.device, indexBufferInfo);

    vertex_offset_in_transfer := 0
    index_offset_in_transfer  := alignUp(vertex_bytes, 256)
    total_transfer_size := index_offset_in_transfer + index_bytes

    // Transfer Buffer 
    transferInfo := sdl.GPUTransferBufferCreateInfo{};
    transferInfo.size = cast(u32)total_transfer_size;
    transferInfo.usage = .UPLOAD;
    transferBuffer := sdl.CreateGPUTransferBuffer(renderer.gpu.device, transferInfo);

    data:= transmute([^]byte)sdl.MapGPUTransferBuffer(renderer.gpu.device, transferBuffer, false);
    // Vertex copy
    sdl.memcpy(data, raw_data(renderer.geometry.allCollisionVertices), cast(uint)vertex_bytes);
    // Index copy
    sdl.memcpy(data[index_offset_in_transfer:], raw_data(renderer.geometry.allCollisionIndices), cast(uint)index_bytes);

    sdl.UnmapGPUTransferBuffer(renderer.gpu.device, transferBuffer);

    // acquire the command buffer
    buffer := sdl.AcquireGPUCommandBuffer(renderer.gpu.device);
    copyPass := sdl.BeginGPUCopyPass(buffer);
    
    // VERTEX BUFFER UPLOAD
    vertexLocation:= sdl.GPUTransferBufferLocation{};
    vertexLocation.transfer_buffer = transferBuffer;
    vertexLocation.offset = 0;

    vertexRegion := sdl.GPUBufferRegion{};
    vertexRegion.buffer = renderer.geometry.collisionBuffer;
    vertexRegion.size = cast(u32)vertex_bytes;
    vertexRegion.offset = 0;
    // Upload Vertex
    sdl.UploadToGPUBuffer(copyPass, vertexLocation, vertexRegion, true);

    
    // INDEX BUFFER UPLOAD
    indexLocation:= sdl.GPUTransferBufferLocation{};
    indexLocation.transfer_buffer = transferBuffer;
    indexLocation.offset = cast(u32)index_offset_in_transfer;
    
    indexRegion := sdl.GPUBufferRegion{};
    indexRegion.buffer = renderer.geometry.collisionIndexBuffer;
    indexRegion.size = cast(u32)index_bytes;
    indexRegion.offset = 0;
    // Upload Index
    sdl.UploadToGPUBuffer(copyPass, indexLocation, indexRegion, true);

    sdl.EndGPUCopyPass(copyPass);
    if sdl.SubmitGPUCommandBuffer(buffer){
        log.info("Submit buffert to GPU succesfully", true);
    }

    sdl.ReleaseGPUTransferBuffer(renderer.gpu.device, transferBuffer);

}

uploadModelMatrices :: proc(renderer: ^Renderer, buffer: ^sdl.GPUCommandBuffer) {
    model_bytes := len(renderer.geometry.allModelMatrix) * size_of(matrix[4,4]f32)
    if model_bytes == 0 do return

    transferInfo := sdl.GPUTransferBufferCreateInfo{ size = cast(u32)model_bytes, usage = .UPLOAD }
    tb := sdl.CreateGPUTransferBuffer(renderer.gpu.device, transferInfo)

    data := transmute([^]byte)sdl.MapGPUTransferBuffer(renderer.gpu.device, tb, false)
    sdl.memcpy(data, raw_data(renderer.geometry.allModelMatrix), cast(uint)model_bytes)
    sdl.UnmapGPUTransferBuffer(renderer.gpu.device, tb)

    // Use the passed-in buffer — no separate acquire/submit
    cp := sdl.BeginGPUCopyPass(buffer)
    loc := sdl.GPUTransferBufferLocation{ transfer_buffer = tb }
    reg := sdl.GPUBufferRegion{ buffer = renderer.geometry.modelMatrixBuffer, size = cast(u32)model_bytes }
    sdl.UploadToGPUBuffer(cp, loc, reg, true)
    sdl.EndGPUCopyPass(cp)

    sdl.ReleaseGPUTransferBuffer(renderer.gpu.device, tb)
}


//// LIGHT

initLight::proc(renderer: ^Renderer){
    // Light set up
    renderer.scene.lightInfo.lightPosition = {0.0, 15.0, -10.0, 0.0};
    renderer.scene.lightInfo.lightColor = {1.0, 1.0, 1.0, 1.0};
    renderer.scene.lightInfo.lightIntensity = {1000.0, 1000.0, 1000.0, 1000.0};
}

addLight::proc(mRenderer:^Renderer, lightPos:linalg.Vector3f32, color:linalg.Vector4f32 = {1.0, 1.0, 1.0, 1.0}, intensity:f32 = 1000.0){
    mRenderer.scene.lightInfo.lightPosition = {lightPos.x, lightPos.y, lightPos.z, 0.0};
    mRenderer.scene.lightInfo.lightColor     = color;
    mRenderer.scene.lightInfo.lightIntensity = {intensity, intensity, intensity, 1.0};
    append(&mRenderer.scene.light, createColoredSphere(lightPos.x, lightPos.y, lightPos.z, 0.25, 25.0, 25.0,{0,0,0}, 0, 1.0, 0, is_Static = false));
}