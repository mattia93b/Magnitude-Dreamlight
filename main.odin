package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"

// SCREEN RESOLUTION
DEFAULT_SCREEN_RES_WIDTH :: 1280;
DEFAULT_SCREEN_RES_HEIGHT :: 720;
// direct3d12 vulkan metal
//DEFAULT_RENDER_API :: "direct3d12"
DEFAULT_RENDER_API :: "direct3d12" when ODIN_OS == .Windows else 
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

main::proc(){
    context.logger = log.create_console_logger();
    // Texture Atlas Demo
    //createTextureAtlas();

    // Data Manager Creation
    dataManager : DataManager;
    // Create Renderer
    createRenderer(&dataManager);

    // Load vertex shader
    vertexShaderIndex := createShader(&dataManager, "shaders/compiled/"+ DEFAULT_RENDER_API +"/vertex.vert." + SHADER_EXT, .VERTEX, 1, 0);
    // Load fragment shader
    fragmentShaderIndex := createShader(&dataManager, "shaders/compiled/"+ DEFAULT_RENDER_API +"/fragmentMaterialPBR.frag." + SHADER_EXT, .FRAGMENT, 2, 1, 16);
    // Load Light vertex shader
    lightVertexShaderIndex := createShader(&dataManager, "shaders/compiled/"+ DEFAULT_RENDER_API +"/light.vert." + SHADER_EXT, .VERTEX, 3, 0);
    // Load Light fragment shader
    lightFragmentShaderIndex := createShader(&dataManager, "shaders/compiled/"+ DEFAULT_RENDER_API +"/light.frag." + SHADER_EXT, .FRAGMENT, 0, 0);

    // Load Light vertex shader
    //instanceVertexShader := loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/instanceVertex.vert." + SHADER_EXT, .VERTEX, 1, 0);
    // Load Light fragment shader
    //instanceFragmentShader := loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/instanceFragment.frag." + SHADER_EXT, .FRAGMENT, 2, 1);

    // Create Graphic Pipeline
    //createGraphicPipeline(&mRenderer, vertexShader, fragmentShader);
    // New datamanger System
    createGraphicPipelineDataManager(&dataManager, vertexShaderIndex, fragmentShaderIndex);
    // Create Light Graphic Pipeline
    createGraphicPipelineDataManager(&dataManager, lightVertexShaderIndex, lightFragmentShaderIndex);
    // Create Instance Graphic Pipeline
    //createGraphicPipeline(&mRenderer, instanceVertexShader, instanceFragmentShader);

    // Scene
    boxId := createCube(&dataManager, 0.0, 10.0, -20.0, 5.0, 5.0);
    baseId  := createCube(&dataManager, 0.0, 3.0, -10.0, 32.0, 0.5, "resources/textures/textureDefault.png");
    cube1Id := createCube(&dataManager, 2.0, 5.0, -10.0, 3.0, 3.0);
	cube2Id := createCube(&dataManager, 6.0, 5.0, -10.0, 3.0, 3.0);
	cube3Id := createCube(&dataManager, -2.0, 5.0, -10.0, 3.0, 3.0);
	cube4Id := createCube(&dataManager, -6.0, 5.0, -10.0, 3.0, 3.0);


    sphere1Id := createSphere(&dataManager, -6.0, 10.0, -10.0, 2.0, 25.0, 25.0);
    sphere2Id := createSphere(&dataManager, 6.0, 10.0, -10.0, 2.0, 25.0, 25.0);

    addLightToScene(&dataManager, {0.0, 15.0, 10.0});

    // Upload renderable in buffer
    //pushRenderableInBuffer(mRenderer);
    //pushRenderableInBufferForInstance(&mRenderer);
    uploadAllDataToGPU(&dataManager);


    // Set isRunning true to start the loop
    isRunning := true;

    lastTicks := sdl.GetTicks();

    x :f32= -2.0; 
	y :f32= 5.0;
	z :f32= -2.0;
	k :f32= 1;
    velocity :f32= 5;

    // GameLoop
    for isRunning {
        
        newTicks:= sdl.GetTicks();
        deltaTime := f32(newTicks - lastTicks) / 1000;
        lastTicks = newTicks;

        updatePosition(x, y, z, getRenderableObject(&dataManager, sphere1Id));

        if (x <= - 10) {
			k = 1;
		}
		else if(x >= 10){
			k = - 1;
		}

		x = x + (velocity * k * deltaTime);

        // Renderer update
        isRunning = update(&dataManager.renderer, deltaTime);
        //isRunning = updateInstance(&mRenderer, detaTime);
    }

    cleanRenderer(&dataManager.renderer);
}