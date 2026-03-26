package magnitudeCore

import "base:intrinsics"
// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"


uploadMaterialTexture::proc(renderer: ^Renderer){

    // acquire the command buffer
    buffer := sdl.AcquireGPUCommandBuffer(renderer.gpu.device);
    copyPass := sdl.BeginGPUCopyPass(buffer);
    
    // Texture load
    stagingBuffers : [dynamic]^sdl.GPUTransferBuffer
    defer {
        for buf in stagingBuffers {
            if buf != nil {
                sdl.ReleaseGPUTransferBuffer(renderer.gpu.device, buf)
            }
        }
        delete(stagingBuffers)
    }

    materiaCounter := 0;

    for mat in renderer.scene.material {

        slot := cast(u32)len(renderer.allTextures);

        // ALBEDO
        stagingBuffer := loadSingleTexture(renderer, mat.texture_albedo, .R8G8B8A8_UNORM_SRGB, copyPass);
        append(&stagingBuffers, stagingBuffer)

        // METALLIC
        stagingBuffer = loadSingleTexture(renderer, mat.texture_metallic, .R8G8B8A8_UNORM, copyPass);
        append(&stagingBuffers, stagingBuffer)

        // ROUGHNESS
        stagingBuffer = loadSingleTexture(renderer, mat.texture_roughness, .R8G8B8A8_UNORM, copyPass);
        append(&stagingBuffers, stagingBuffer)

        // NORMAL
        stagingBuffer = loadSingleTexture(renderer, mat.texture_normal, .R8G8B8A8_UNORM, copyPass);
        append(&stagingBuffers, stagingBuffer)

        // AO
        stagingBuffer = loadSingleTexture(renderer, mat.texture_ao, .R8G8B8A8_UNORM, copyPass);
        append(&stagingBuffers, stagingBuffer)

        // Push material to buffet to upload to GPU
        append(&renderer.geometry.allMaterials, MaterialPBR{slot, slot + 1, slot + 2 , slot + 3 , slot + 4});
        log.infof("Material ID: ", len(renderer.geometry.allMaterials),"Slot: ", renderer.geometry.allMaterials[len(renderer.geometry.allMaterials)-1])

        materiaCounter = materiaCounter + 1;

        if materiaCounter == 3{
            materiaCounter = 0
            // empty texture
            stagingBuffer = loadSingleTexture(renderer, "resources/textures/textureDefault.png", .R8G8B8A8_UNORM, copyPass);
            append(&stagingBuffers, stagingBuffer)
        }

    }

    sdl.EndGPUCopyPass(copyPass);
    if sdl.SubmitGPUCommandBuffer(buffer){
        log.info("Submit buffert to GPU succesfully", true);
    }

}


DEFAULT_TEXTURE_PATH :: "resources/textures/textureDefault.png"

loadSingleTexture::proc(renderer:^Renderer ,path:cstring, format:sdl.GPUTextureFormat, copyPass:^sdl.GPUCopyPass) -> ^sdl.GPUTransferBuffer {

    // Fall back to default texture if path is empty
    effective_path := path
    if path == nil || len(path) == 0 {
        effective_path = DEFAULT_TEXTURE_PATH
    }

    surface := loadTexturePNG(effective_path, 4)

    // If loading still failed, try the default texture as last resort
    if surface == nil && effective_path != DEFAULT_TEXTURE_PATH {
        log.warnf("Texture '%s' failed to load, using default.", effective_path)
        surface = loadTexturePNG(DEFAULT_TEXTURE_PATH, 4)
    }

    // If even the default fails, we cannot continue
    if surface == nil {
        log.error("FATAL: Default texture also failed to load.")
        return nil
    }

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