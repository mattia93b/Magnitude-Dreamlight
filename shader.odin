package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"

loadShader::proc(mRenderer:^Renderer, path:cstring, stage:sdl.GPUShaderStage, num_uniform_buffers:u32, num_storage_buffers:u32) -> ^sdl.GPUShader{

    shaderCodeSize:uint;
    shaderCode := sdl.LoadFile(path, &shaderCodeSize);

    shaderInfo := sdl.GPUShaderCreateInfo{};
    shaderInfo.code = cast(^u8)shaderCode;
    shaderInfo.code_size = shaderCodeSize;
    shaderInfo.entrypoint = SHADER_ENTRY_POINT;
    shaderInfo.format = {SHADER_FORMAT};
    shaderInfo.stage = stage;
    shaderInfo.num_samplers = 0;
    shaderInfo.num_storage_buffers = num_storage_buffers;
    shaderInfo.num_storage_textures = 0;
    shaderInfo.num_uniform_buffers = num_uniform_buffers;
    shader := sdl.CreateGPUShader(mRenderer.device, shaderInfo);

    sdl.free(shaderCode);

    return shader;

}