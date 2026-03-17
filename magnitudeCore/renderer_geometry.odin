package magnitudeCore

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"


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


alignUp :: proc(value: int, alignment: int) -> int {
    return (value + alignment - 1) & ~(alignment - 1)
}


//// RENDERABLE

addRenderable::proc(mRenderer:^Renderer, renderable:Renderable){
    append(&mRenderer.scene.renderable, renderable)
}

buildGeometry::proc(renderer: ^Renderer){


    uploadMaterialTexture(renderer);


    for el in renderer.scene.light{

        modelMatrixIndex := cast(f32)len(renderer.geometry.allModelMatrix)
        append(&renderer.geometry.allModelMatrix, el.modelMatrix)
        // Calculate the offset before pushing new data to the VertexBuffer
        vertex_offset := u16(len(renderer.geometry.allVertices));
        // Push all vertex indices information inside the IndexBuffer of the renderer
        for idx in el.index {
            append(&renderer.geometry.allIndices, u16(idx) + vertex_offset);
        }
        // Push all vertex information inside a Vertex Object and store it in the VertexBuffer of the renderer
        for numberProcessedVertex:= 0; numberProcessedVertex < len(el.vertex); numberProcessedVertex = numberProcessedVertex + 1 {
            append(&renderer.geometry.allVertices, Vertex{position = el.vertex[numberProcessedVertex], uv = el.UVs[numberProcessedVertex],  modelMatrixIndex = cast(u32)modelMatrixIndex, normals= el.normals[numberProcessedVertex]})
        }
    }

    renderer.scene.lightNumberOfIndexInBuffer = len(renderer.geometry.allIndices);

    textureCount := 0;

    // Push renderable after light object
    for el in renderer.scene.renderable{
        // calculate model matrix Index and append model matrix to allModelMatrixArray
        modelMatrixIndex := cast(f32)len(renderer.geometry.allModelMatrix);
        append(&renderer.geometry.allModelMatrix, el.modelMatrix);
        // Calculate the materia Index and append material to allMaterialsArray
        //materialIndex := cast(f32)len(renderer.geometry.allMaterials);
        //append(&renderer.geometry.allMaterials, el.materialPBR);
        // Calculate the offset before pushing new data to the VertexBuffer
        vertex_offset := u16(len(renderer.geometry.allVertices));
        // Push all vertex indices information inside the IndexBuffer of the renderer
        for idx in el.index {
            append(&renderer.geometry.allIndices, u16(idx) + vertex_offset);
        }
        // Push all vertex information inside a Vertex Object and store it in the VertexBuffer of the renderer
        for numberProcessedVertex:= 0; numberProcessedVertex < len(el.vertex); numberProcessedVertex = numberProcessedVertex + 1 {
            append(&renderer.geometry.allVertices, Vertex{position = el.vertex[numberProcessedVertex], uv =  el.UVs[numberProcessedVertex],  modelMatrixIndex = cast(u32)modelMatrixIndex, normals= el.normals[numberProcessedVertex], materialIndex = el.materialID});
        }

        /*if el.albedo != ""{
            if !(el.albedo in renderer.textures){
                renderer.textures[el.albedo] = textureCount;
                textureCount += 1;
            }
        }
        if el.metallic != ""{
            if !(el.metallic in renderer.textures){
                renderer.textures[el.metallic] = textureCount;
                textureCount += 1;
            }
        }
        if el.roughness != ""{
            if !(el.roughness in renderer.textures){
                renderer.textures[el.roughness] = textureCount;
                textureCount += 1;
            }
        }
        if el.normal != ""{
            if !(el.normal in renderer.textures){
                renderer.textures[el.normal] = textureCount;
                textureCount += 1;
            }
        }*/
    }
}


uploadGeometry::proc(renderer: ^Renderer){

    vertex_bytes := len(renderer.geometry.allVertices) * size_of(Vertex);

    bufferInfo := sdl.GPUBufferCreateInfo{};
    bufferInfo.size = cast(u32)vertex_bytes;
    bufferInfo.usage = {.VERTEX};
    renderer.geometry.vertexBuffer= sdl.CreateGPUBuffer(renderer.gpu.device, bufferInfo);


    index_bytes := len(renderer.geometry.allIndices) * size_of(u16);

    indexBufferInfo := sdl.GPUBufferCreateInfo{};
    indexBufferInfo.size = cast(u32)index_bytes;
    indexBufferInfo.usage = {.INDEX};
    renderer.geometry.indexBuffer= sdl.CreateGPUBuffer(renderer.gpu.device, indexBufferInfo);


    materials_bytes := len(renderer.geometry.allMaterials) * size_of(MaterialPBR);

    materialsBufferInfo := sdl.GPUBufferCreateInfo{};
    materialsBufferInfo.size = cast(u32)materials_bytes;
    materialsBufferInfo.usage = {.GRAPHICS_STORAGE_READ};
    renderer.geometry.materialBuffer= sdl.CreateGPUBuffer(renderer.gpu.device, materialsBufferInfo);

    vertex_offset_in_transfer := 0
    index_offset_in_transfer  := alignUp(vertex_bytes, 256)
    materials_offset_in_transfer := alignUp(index_offset_in_transfer + index_bytes, 256)
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


//// LIGHT

initLight::proc(renderer: ^Renderer){
    // Light set up
    renderer.scene.lightInfo.lightPosition = {0.0, 15.0, -10.0, 0.0};
    renderer.scene.lightInfo.lightColor = {1.0, 1.0, 1.0, 1.0};
    renderer.scene.lightInfo.lightIntensity = {1000.0, 1000.0, 1000.0, 1000.0};
}

addLight::proc(mRenderer:^Renderer, lightPos:linalg.Vector3f32){
    append(&mRenderer.scene.light, createColoredSphere(mRenderer.scene.lightInfo.lightPosition.x, mRenderer.scene.lightInfo.lightPosition.y, mRenderer.scene.lightInfo.lightPosition.z,0.25, 25.0, 25.0, 0));
}