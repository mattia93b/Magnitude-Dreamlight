package magnitudeCore

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"



uploadTexture::proc(renderer: ^Renderer){

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

    slot := 0
    for path in renderer.textures {
        if slot >= 16 do break

        surface := loadTexturePNG(path, 4)
        if surface == nil do continue
        defer sdl.DestroySurface(surface)

        renderer.allTextures[slot] = sdl.CreateGPUTexture(renderer.gpu.device, sdl.GPUTextureCreateInfo{
            type                 = .D2,
            format               = .R8G8B8A8_UNORM_SRGB,
            width                = cast(u32)surface.w,
            height               = cast(u32)surface.h,
            layer_count_or_depth = 1,
            num_levels           = 1,
            usage                = {.SAMPLER},
        })

        pixel_bytes := cast(u32)(surface.w * surface.h * 4)
        stagingBuffer := sdl.CreateGPUTransferBuffer(renderer.gpu.device, sdl.GPUTransferBufferCreateInfo{
            usage = .UPLOAD,
            size  = pixel_bytes,
        })

        data := sdl.MapGPUTransferBuffer(renderer.gpu.device, stagingBuffer, false)
        sdl.memcpy(data, surface.pixels, cast(uint)pixel_bytes)
        sdl.UnmapGPUTransferBuffer(renderer.gpu.device, stagingBuffer)

        sdl.UploadToGPUTexture(
            copyPass,
            {transfer_buffer = stagingBuffer, offset = 0},
            {texture = renderer.allTextures[slot], w = cast(u32)surface.w, h = cast(u32)surface.h, d = 1},
            false,
        )

        append(&stagingBuffers, stagingBuffer) // ← accumula, non rilasciare ora
        slot += 1
    }

    sdl.EndGPUCopyPass(copyPass);
    if sdl.SubmitGPUCommandBuffer(buffer){
        log.info("Submit buffert to GPU succesfully", true);
    }

}