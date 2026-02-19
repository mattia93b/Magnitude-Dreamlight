package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"


loadTexturePNG::proc(path:cstring, desiredChannels:int) -> ^sdl.Surface {

    //result := sdl.LoadBMP(path);
    result := sdl.LoadPNG(path);
    format:sdl.PixelFormat
    
    if result == nil {
        log.error("---------------------------------------------------");
        log.error("FATAL ERROR: Texture Loading failed!");
        log.error("ERROR:", sdl.GetError());
        log.error("---------------------------------------------------");
        return nil;
    }

    if desiredChannels == 4 {
        format = .ABGR8888;
    } else{
        sdl.DestroySurface(result);
        return nil;
    }

    if result.format != format {
        next := sdl.ConvertSurface(result, format);
        sdl.DestroySurface(result); 
        result = next; 
    }

    return result;

}