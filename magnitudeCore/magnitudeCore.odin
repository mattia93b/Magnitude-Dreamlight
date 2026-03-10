package magnitudeCore

// SDL3 bindings
import sdl "vendor:sdl3"

// SCREEN RESOLUTION
DEFAULT_SCREEN_RES_WIDTH :: 1280;
DEFAULT_SCREEN_RES_HEIGHT :: 720;
// direct3d12 vulkan metal
//DEFAULT_RENDER_API :: "direct3d12"
DEFAULT_RENDER_API :: "vulkan" when ODIN_OS == .Windows else 
                      "metal"      when ODIN_OS == .Darwin  else 
                      "vulkan"
SHADER_EXT :: "spv"  when DEFAULT_RENDER_API == "vulkan" else 
              "dxil" when DEFAULT_RENDER_API == "direct3d12"  else 
              "msl"  when DEFAULT_RENDER_API == "metal"  else "bin"

SHADER_FORMAT :: sdl.GPUShaderFormatFlag.SPIRV when DEFAULT_RENDER_API == "vulkan" else 
                sdl.GPUShaderFormatFlag.DXIL when DEFAULT_RENDER_API == "direct3d12"  else 
                sdl.GPUShaderFormatFlag.MSL when DEFAULT_RENDER_API == "metal"  else "bin"
SHADER_ENTRY_POINT :: "main0" when DEFAULT_RENDER_API == "metal" else "main"

// Window Name
DEFAULT_WINDOW_TITLE :: "Magnitude Dreamlight";