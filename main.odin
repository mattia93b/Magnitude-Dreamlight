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
    
    // Renderer definition
    mRenderer : ^Renderer = &dataManager.renderer;

    // Load vertex shader
    vertexShader := loadShader(dataManager.gpuDevice, "shaders/compiled/"+ DEFAULT_RENDER_API +"/vertex.vert." + SHADER_EXT, .VERTEX, 1, 0);
    // New datamanger System
    vertexShaderIndex := createShader(&dataManager, "shaders/compiled/"+ DEFAULT_RENDER_API +"/vertex.vert." + SHADER_EXT, .VERTEX, 1, 0);
    log.infof("Shader Index: ", vertexShaderIndex);
    // Load fragment shader
    //fragmentShader := loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/fragment.frag." + SHADER_EXT, .FRAGMENT, 2, 1);
    fragmentShader := loadShader(dataManager.gpuDevice, "shaders/compiled/"+ DEFAULT_RENDER_API +"/fragmentMaterialPBR.frag." + SHADER_EXT, .FRAGMENT, 2, 1, 16);
    // New datamanger System
    fragmentShaderIndex := createShader(&dataManager, "shaders/compiled/"+ DEFAULT_RENDER_API +"/fragmentMaterialPBR.frag." + SHADER_EXT, .FRAGMENT, 2, 1, 16);
    log.infof("Shader Index: ", fragmentShaderIndex);
    // Load Light vertex shader
    lightVertexShader := loadShader(dataManager.gpuDevice, "shaders/compiled/"+ DEFAULT_RENDER_API +"/light.vert." + SHADER_EXT, .VERTEX, 3, 0);
    // Load Light fragment shader
    lightFragmentShader := loadShader(dataManager.gpuDevice, "shaders/compiled/"+ DEFAULT_RENDER_API +"/light.frag." + SHADER_EXT, .FRAGMENT, 0, 0);

    // Load Light vertex shader
    //instanceVertexShader := loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/instanceVertex.vert." + SHADER_EXT, .VERTEX, 1, 0);
    // Load Light fragment shader
    //instanceFragmentShader := loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/instanceFragment.frag." + SHADER_EXT, .FRAGMENT, 2, 1);

    // Create Graphic Pipeline
    //createGraphicPipeline(&mRenderer, vertexShader, fragmentShader);
    // New datamanger System
    createGraphicPipelineDataManager(&dataManager, vertexShaderIndex, fragmentShaderIndex);
    // Create Light Graphic Pipeline
    createGraphicPipeline(mRenderer, lightVertexShader, lightFragmentShader);
    // Create Instance Graphic Pipeline
    //createGraphicPipeline(&mRenderer, instanceVertexShader, instanceFragmentShader);

    // Scene
    box   := createColoredCube(0.0, 10.0, -20.0, 5.0, 5.0);
    box.material = jade();
    box.materialPBR = SR_Aluminum();
    base  := createColoredCube(0.0, 3.0, -10.0, 32.0, 0.5, "resources/textures/textureDefault.png");
    base.material = obsidian();
    base.materialPBR = SR_Aluminum();
	cube1 := createColoredCube(2.0, 5.0, -10.0, 3.0, 3.0);
    cube1.material = bronze();
    cube1.materialPBR = SR_Aluminum();
	cube2 := createColoredCube(6.0, 5.0, -10.0, 3.0, 3.0);
    cube2.material = silver();
    cube2.materialPBR = SR_Aluminum();
	cube3 := createColoredCube(-2.0, 5.0, -10.0, 3.0, 3.0);
    cube3.material = emerald();
    cube3.materialPBR = SR_Aluminum();
	cube4 := createColoredCube(-6.0, 5.0, -10.0, 3.0, 3.0);
    cube4.material = redPlastic()
    cube4.materialPBR = SR_Aluminum();

    addRenderable(mRenderer, &box);
    addRenderable(mRenderer, &base);
    addRenderable(mRenderer, &cube1);
    addRenderable(mRenderer, &cube2);
    addRenderable(mRenderer, &cube3);
    addRenderable(mRenderer, &cube4);

    sphere1 := createColoredSphere(-6.0, 10.0, -10.0, 2.0, 25.0, 25.0);

    addRenderable(mRenderer, &sphere1);

    sphere2 := createColoredSphere(6.0, 10.0, -10.0, 2.0, 25.0, 25.0);

    addRenderable(mRenderer, &sphere2);

    addLight(mRenderer, {0.0, 15.0, 10.0});

    // Upload renderable in buffer
    pushRenderableInBuffer(mRenderer);
    //pushRenderableInBufferForInstance(&mRenderer);


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

        updatePosition(x, y, z, &sphere1);

        if (x <= - 10) {
			k = 1;
		}
		else if(x >= 10){
			k = - 1;
		}

		x = x + (velocity * k * deltaTime);

        // Renderer update 
        isRunning = update(mRenderer, deltaTime);
        //isRunning = updateInstance(&mRenderer, detaTime);
    }

    cleanRenderer(mRenderer);
}