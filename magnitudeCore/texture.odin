package magnitudeCore

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
import "core:mem"
import "vendor:stb/image"


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

TEXTURE_ATLAS_SIZE :: 10000; // 4096
TEXTURE_ATLAS_CHANNELS :: 4;


createTextureAtlas::proc(){

    log.infof("texture Atlas demo");
    paths := []cstring {"resources/textures/container2_specular.png", "resources/textures/container2.png", "resources/textures/textureDefault.png", "resources/textures/textureDefault_specular.png"};
    
    atlas_teture := make([]u8, TEXTURE_ATLAS_SIZE * TEXTURE_ATLAS_SIZE * TEXTURE_ATLAS_CHANNELS);
    
    cursorX, cursorY := 0, 0;

    for path in paths {
        w, h, channels : i32;

        imgData := image.load(path, &w, &h, &channels, TEXTURE_ATLAS_CHANNELS);

        for row in 0..<int(h){

            destOffset := ((cursorY + row) * TEXTURE_ATLAS_SIZE + cursorX) * TEXTURE_ATLAS_CHANNELS;
            sourceOffset := (row * int(w)) * TEXTURE_ATLAS_CHANNELS;

            mem.copy(&atlas_teture[destOffset], &imgData[sourceOffset], int(w) * TEXTURE_ATLAS_CHANNELS);
        }

        u_min := f32(cursorX) / f32(TEXTURE_ATLAS_SIZE)
        v_min := f32(cursorY) / f32(TEXTURE_ATLAS_SIZE)
        u_max := f32(cursorX + int(w)) / f32(TEXTURE_ATLAS_SIZE)
        v_max := f32(cursorY + int(h)) / f32(TEXTURE_ATLAS_SIZE)
        
        log.infof("TEXTURE: ", path, "UV: ", u_min, v_min, u_max, v_max);
        
        cursorX += int(w);

    }

    image.write_png("atlas_10k.png", TEXTURE_ATLAS_SIZE, TEXTURE_ATLAS_SIZE, TEXTURE_ATLAS_CHANNELS, raw_data(atlas_teture), TEXTURE_ATLAS_SIZE * TEXTURE_ATLAS_CHANNELS);

}