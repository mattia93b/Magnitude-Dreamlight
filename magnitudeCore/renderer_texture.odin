package magnitudeCore

import "base:intrinsics"
// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"
// string
import "core:strings"


uploadMaterialTexture::proc(renderer: ^Renderer){

    // acquire the command buffer
    buffer := sdl.AcquireGPUCommandBuffer(renderer.gpu.device);
    copyPass := sdl.BeginGPUCopyPass(buffer);
    
    // Texture load
    stagingBuffers : [dynamic]^sdl.GPUTransferBuffer
    defer {
        for buf in stagingBuffers {
            sdl.ReleaseGPUTransferBuffer(renderer.gpu.device, buf)
        }
        delete(stagingBuffers)
    }

    for mat in renderer.scene.material {

        // ALBEDO
        stagingBuffer := loadSingleTexture(renderer, mat.texture_albedo, .R8G8B8A8_UNORM_SRGB, copyPass);
        slot := cast(u32)len(renderer.allTextures) - 1;
        append(&stagingBuffers, stagingBuffer)

        // METALLIC
        stagingBuffer = loadSingleTexture(renderer, mat.texture_metallic, .R8G8B8A8_UNORM, copyPass);
        slot = cast(u32)len(renderer.allTextures) - 1;
        append(&stagingBuffers, stagingBuffer)

        // ROUGHNESS
        stagingBuffer = loadSingleTexture(renderer, mat.texture_roughness, .R8G8B8A8_UNORM, copyPass);
        slot = cast(u32)len(renderer.allTextures) - 1;
        append(&stagingBuffers, stagingBuffer)

        // NORMAL
        stagingBuffer = loadSingleTexture(renderer, mat.texture_normal, .R8G8B8A8_UNORM, copyPass);
        slot = cast(u32)len(renderer.allTextures) - 1;
        append(&stagingBuffers, stagingBuffer)

        // TODO: Handle the index outside 16
        // Push material to buffet to upload to GPU
        append(&renderer.geometry.allMaterials, MaterialPBR{slot - 3, slot - 2, slot - 1, slot});

    }

    for i:= len(renderer.allTextures); i<16; i=i+1{
        append(&renderer.allTextures, sdl.CreateGPUTexture(renderer.gpu.device, sdl.GPUTextureCreateInfo{
            type                 = .D2,
            format               = .R8G8B8A8_UNORM,
            width                = cast(u32)2,
            height               = cast(u32)2,
            layer_count_or_depth = 1,
            num_levels           = 1,
            usage                = {.SAMPLER},
        }));
    }

    sdl.EndGPUCopyPass(copyPass);
    if sdl.SubmitGPUCommandBuffer(buffer){
        log.info("Submit buffert to GPU succesfully", true);
    }

}


loadSingleTexture::proc(renderer:^Renderer ,path:cstring, format:sdl.GPUTextureFormat, copyPass:^sdl.GPUCopyPass) -> ^sdl.GPUTransferBuffer {

    surface := loadTexturePNG(path, 4)

    defer sdl.DestroySurface(surface)

    append(&renderer.allTextures, sdl.CreateGPUTexture(renderer.gpu.device, sdl.GPUTextureCreateInfo{
        type                 = .D2,
        format               = format,
        width                = cast(u32)surface.w,
        height               = cast(u32)surface.h,
        layer_count_or_depth = 1,
        num_levels           = 1,
        usage                = {.SAMPLER},
    }))

    pixel_bytes := cast(u32)(surface.w * surface.h * 4)
    stagingBuffer := sdl.CreateGPUTransferBuffer(renderer.gpu.device, sdl.GPUTransferBufferCreateInfo{
        usage = .UPLOAD,
        size  = pixel_bytes,
    })

    data := sdl.MapGPUTransferBuffer(renderer.gpu.device, stagingBuffer, false)
    sdl.memcpy(data, surface.pixels, cast(uint)pixel_bytes)
    sdl.UnmapGPUTransferBuffer(renderer.gpu.device, stagingBuffer)

    slot := cast(u32)len(renderer.allTextures) - 1;

    sdl.UploadToGPUTexture(
        copyPass,
        {transfer_buffer = stagingBuffer, offset = 0},
        {texture = renderer.allTextures[slot], w = cast(u32)surface.w, h = cast(u32)surface.h, d = 1},
        false,
    )

    return stagingBuffer;
}