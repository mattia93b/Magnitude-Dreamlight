package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// Magnitude Core
import "magnitudeCore"

MATERIA_SCENE :: false;

main::proc(){
    context.logger = log.create_console_logger();
    // Texture Atlas Demo
    //createTextureAtlas();

    // Data Manager Creation
    dataManager : magnitudeCore.DataManager;
    // Create Renderer
    magnitudeCore.createRenderer(&dataManager);

    // Load vertex shader
    vertexShaderIndex := magnitudeCore.createShader(&dataManager, "shaders/compiled/"+ magnitudeCore.DEFAULT_RENDER_API +"/vertex.vert." + magnitudeCore.SHADER_EXT, .VERTEX, 1, 0);
    // Load fragment shader
    fragmentShaderIndex := magnitudeCore.createShader(&dataManager, "shaders/compiled/"+ magnitudeCore.DEFAULT_RENDER_API +"/fragmentMaterialPBR.frag." + magnitudeCore.SHADER_EXT, .FRAGMENT, 2, 1, 16);
    // Load Light vertex shader
    lightVertexShaderIndex := magnitudeCore.createShader(&dataManager, "shaders/compiled/"+ magnitudeCore.DEFAULT_RENDER_API +"/light.vert." + magnitudeCore.SHADER_EXT, .VERTEX, 3, 0);
    // Load Light fragment shader
    lightFragmentShaderIndex := magnitudeCore.createShader(&dataManager, "shaders/compiled/"+ magnitudeCore.DEFAULT_RENDER_API +"/light.frag." + magnitudeCore.SHADER_EXT, .FRAGMENT, 0, 0);

    // Load Light vertex shader
    //instanceVertexShader := loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/instanceVertex.vert." + SHADER_EXT, .VERTEX, 1, 0);
    // Load Light fragment shader
    //instanceFragmentShader := loadShader(&mRenderer, "shaders/compiled/"+ DEFAULT_RENDER_API +"/instanceFragment.frag." + SHADER_EXT, .FRAGMENT, 2, 1);

    // Create Graphic Pipeline
    //createGraphicPipeline(&mRenderer, vertexShader, fragmentShader);
    // New datamanger System
    magnitudeCore.createGraphicPipelineDataManager(&dataManager, vertexShaderIndex, fragmentShaderIndex);
    // Create Light Graphic Pipeline
    magnitudeCore.createGraphicPipelineDataManager(&dataManager, lightVertexShaderIndex, lightFragmentShaderIndex);
    // Create Instance Graphic Pipeline
    //createGraphicPipeline(&mRenderer, instanceVertexShader, instanceFragmentShader);

    // Material

    defaultMaterial := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/textures/textureDefault.png", 
        "resources/textures/textureDefault_specular.png",
        "resources/textures/textureDefault_specular.png", 
        "resources/materials/elegant-stone-tiles-bl/elegant-stone-tiles_normal-ogl.png",
        "resources/materials/elegant-stone-tiles-bl/elegant-stone-tiles_ao.png");
    /*wood := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/dark-wood-stain-bl/dark-wood-stain_albedo.png", 
        "resources/materials/dark-wood-stain-bl/dark-wood-stain_metallic.png",
        "resources/materials/dark-wood-stain-bl/dark-wood-stain_roughness.png", 
        "resources/materials/dark-wood-stain-bl/dark-wood-stain_normal-ogl.png",
        "resources/materials/dark-wood-stain-bl/dark-wood-stain_ao.png");
    wood2 := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/WoodFloor043_2K-PNG/WoodFloor043_2K-PNG_Color.png", 
        "resources/materials/WoodFloor043_2K-PNG/WoodFloor043_2K-PNG_Metalness.png", 
        "resources/materials/WoodFloor043_2K-PNG/WoodFloor043_2K-PNG_Roughness.png",
        "resources/materials/WoodFloor043_2K-PNG/WoodFloor043_2K-PNG_NormalDX.png",
        "resources/materials/WoodFloor043_2K-PNG/WoodFloor043_2K-PNG_AmbientOcclusion.png"); 
    stone := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/elegant-stone-tiles-bl/elegant-stone-tiles_albedo.png", 
        "resources/materials/elegant-stone-tiles-bl/elegant-stone-tiles_metallic.png",  
        "resources/materials/elegant-stone-tiles-bl/elegant-stone-tiles_roughness.png",
        "resources/materials/elegant-stone-tiles-bl/elegant-stone-tiles_normal-ogl.png",
        "resources/materials/elegant-stone-tiles-bl/elegant-stone-tiles_ao.png"); 
    brick := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/old-subway-brick-bl/old-subway-brick_albedo.png", 
        "resources/materials/old-subway-brick-bl/old-subway-brick_metallic.png", 
        "resources/materials/old-subway-brick-bl/old-subway-brick_roughness.png",
        "resources/materials/old-subway-brick-bl/old-subway-brick_normal-ogl.png",
        "resources/materials/old-subway-brick-bl/old-subway-brick_ao.png"); 
    copper := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/oxidized-copper-bl/oxidized-copper-albedo.png", 
        "resources/materials/oxidized-copper-bl/oxidized-copper-metal.png",  
        "resources/materials/oxidized-copper-bl/oxidized-coppper-roughness.png",
        "resources/materials/oxidized-copper-bl/oxidized-copper-normal-ogl.png",
        "resources/materials/oxidized-copper-bl/oxidized-copper-metal.png"); 
    gold := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/light-gold-bl/lightgold_albedo.png", 
        "resources/materials/light-gold-bl/lightgold_metallic.png", 
        "resources/materials/light-gold-bl/lightgold_roughness.png",
        "resources/materials/light-gold-bl/lightgold_normal-ogl.png",
        "resources/materials/light-gold-bl/lightgold_metallic.png"); 
    Rock063 := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/Rock063_8K-PNG/Rock063_8K-PNG_Color.png", 
        "resources/materials/Rock063_8K-PNG/Rock063_8K-PNG_Displacement.png", 
        "resources/materials/Rock063_8K-PNG/Rock063_8K-PNG_Roughness.png",
        "resources/materials/Rock063_8K-PNG/Rock063_8K-PNG_NormalDX.png",
        "resources/materials/Rock063_8K-PNG/Rock063_8K-PNG_AmbientOcclusion.png");
    river := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/river-rock1-bl/river_rock1_albedo.png", 
        "resources/materials/river-rock1-bl/river_rock1_Metallic.png", 
        "resources/materials/river-rock1-bl/river_rock1_Roughness.png",
        "resources/materials/river-rock1-bl/river_rock1_Normal-ogl.png",
        "resources/materials/river-rock1-bl/river_rock1_ao.png"); 
    oxidized_metal := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/oxidized-metal-clad-bl/oxidized-metal-clad_albedo.png", 
        "resources/materials/oxidized-metal-clad-bl/oxidized-metal-clad_metallic.png", 
        "resources/materials/oxidized-metal-clad-bl/oxidized-metal-clad_roughness.png",
        "resources/materials/oxidized-metal-clad-bl/oxidized-metal-clad_normal-ogl.png",
        "resources/materials/oxidized-metal-clad-bl/oxidized-metal-clad_ao.png"); 
    fancy_carved_wood := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/fancy-carved-wood-bl/fancy-carved-wood_albedo.png", 
        "resources/materials/fancy-carved-wood-bl/fancy-carved-wood_metallic.png", 
        "resources/materials/fancy-carved-wood-bl/fancy-carved-wood_roughness.png",
        "resources/materials/fancy-carved-wood-bl/fancy-carved-wood_normal-ogl.png",
        "resources/materials/fancy-carved-wood-bl/fancy-carved-wood_ao.png"); 
    worn_factory := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/worn-factory-siding-bl/worn-factory-siding_albedo.png", 
        "resources/materials/worn-factory-siding-bl/worn-factory-siding_metallic.png", 
        "resources/materials/worn-factory-siding-bl/worn-factory-siding_roughness.png",
        "resources/materials/worn-factory-siding-bl/worn-factory-siding_normal-ogl.png",
        "resources/materials/worn-factory-siding-bl/worn-factory-siding_ao.png"); 
    cloudy_veined_quartz := magnitudeCore.createMaterialInScene(&dataManager, 
        "resources/materials/cloudy-veined-quartz-bl/cloudy-veined-quartz_albedo.png", 
        "resources/materials/cloudy-veined-quartz-bl/cloudy-veined-quartz_metallic.png", 
        "resources/materials/cloudy-veined-quartz-bl/cloudy-veined-quartz_roughness.png",
        "resources/materials/cloudy-veined-quartz-bl/cloudy-veined-quartz_normal-ogl.png",
        "resources/materials/cloudy-veined-quartz-bl/cloudy-veined-quartz_ao.png"); 
    */


    // Scene
    //boxId := magnitudeCore.createCube(&dataManager, 0.0, 10.0, -20.0, 5.0, 5.0, Rock063);
    baseId  := magnitudeCore.createCube(&dataManager, 0.0, 3.0, -10.0, 32.0, 0.5, defaultMaterial);

    /*if MATERIA_SCENE {
        //
        cube1Id := magnitudeCore.createCube(&dataManager, -10.0, 5.0, -15.0, 3.0, 3.0, wood);
        cube2Id := magnitudeCore.createCube(&dataManager, -6.0, 5.0, -15.0, 3.0, 3.0, wood2);
        cube3Id := magnitudeCore.createCube(&dataManager, -2.0, 5.0, -15.0, 3.0, 3.0, stone);
        cube4Id := magnitudeCore.createCube(&dataManager, 2.0, 5.0, -15.0, 3.0, 3.0, brick);
        cube5Id := magnitudeCore.createCube(&dataManager, 6.0, 5.0, -15.0, 3.0, 3.0, copper);
        cube6Id := magnitudeCore.createCube(&dataManager, 10.0, 5.0, -15.0, 3.0, 3.0, gold);
        //
        cube7Id := magnitudeCore.createCube(&dataManager, -10.0, 5.0, -5.0, 3.0, 3.0, Rock063);
        cube8Id := magnitudeCore.createCube(&dataManager, -6.0, 5.0, -5.0, 3.0, 3.0, river);
        cube9Id := magnitudeCore.createCube(&dataManager, -2.0, 5.0, -5.0, 3.0, 3.0, oxidized_metal);
        cube10Id := magnitudeCore.createCube(&dataManager, 2.0, 5.0, -5.0, 3.0, 3.0, fancy_carved_wood);
        cube11Id := magnitudeCore.createCube(&dataManager, 6.0, 5.0, -5.0, 3.0, 3.0, worn_factory);
        cube12Id := magnitudeCore.createCube(&dataManager, 10.0, 5.0, -5.0, 3.0, 3.0, cloudy_veined_quartz);

        //sphereId := magnitudeCore.createSphere(&dataManager, -6.0, 10.0, -10.0, 1.5, 25.0, 25.0, gold);
        //
        sphere1Id := magnitudeCore.createSphere(&dataManager, -10.0, 10.0, -15.0, 1.5, 25.0, 25.0, wood);
        sphere2Id := magnitudeCore.createSphere(&dataManager, -6.0, 10.0, -15.0, 1.5, 25.0, 25.0, wood2);
        sphere3Id := magnitudeCore.createSphere(&dataManager, -2.0, 10.0, -15.0, 1.5, 25.0, 25.0, stone);
        sphere4Id := magnitudeCore.createSphere(&dataManager, 2.0, 10.0, -15.0, 1.5, 25.0, 25.0, brick);
        sphere5Id := magnitudeCore.createSphere(&dataManager, 6.0, 10.0, -15.0, 1.5, 25.0, 25.0, copper);
        sphere6Id := magnitudeCore.createSphere(&dataManager, 10.0, 10.0, -15.0, 1.5, 25.0, 25.0, gold);
        //
        sphere7Id := magnitudeCore.createSphere(&dataManager, -10.0, 5.0, 0.0, 1.5, 25.0, 25.0, Rock063);
        sphere8Id := magnitudeCore.createSphere(&dataManager, -6.0, 5.0, 0.0, 1.5, 25.0, 25.0, river);
        sphere9Id := magnitudeCore.createSphere(&dataManager, -2.0, 5.0, 0.0, 1.5, 25.0, 25.0, oxidized_metal);
        sphere10Id := magnitudeCore.createSphere(&dataManager, 2.0, 5.0, 0.0, 1.5, 25.0, 25.0, fancy_carved_wood);
        sphere11Id := magnitudeCore.createSphere(&dataManager, 6.0, 5.0, 0.0, 1.5, 25.0, 25.0, worn_factory);
        sphere12Id := magnitudeCore.createSphere(&dataManager, 10.0, 5.0, 0.0, 1.5, 25.0, 25.0, cloudy_veined_quartz);
    }*/

    cubeCollision1 := magnitudeCore.createCube(&dataManager, -10.0, 5.0, -15.0, 3.0, 3.0, defaultMaterial, {5,0,0}, false);
    cubeCollision2 := magnitudeCore.createCube(&dataManager, 10.0, 5.0, -15.0, 3.0, 3.0, defaultMaterial, {-5,0,0}, false);

    cubeCollision3 := magnitudeCore.createCube(&dataManager, 0.0, 15.0, -5.0, 3.0, 3.0, defaultMaterial, {0,-5,0}, false);
    cubeCollision4 := magnitudeCore.createCube(&dataManager, 0.0, -5.0, -5.0, 3.0, 3.0, defaultMaterial, {0,5,0}, false);

    cubeCollision5 := magnitudeCore.createCube(&dataManager, 5.0, 5.0, -10.0, 3.0, 3.0, defaultMaterial, {0,0,5}, false);
    cubeCollision6 := magnitudeCore.createCube(&dataManager, 5.0, 5.0, 10.0, 3.0, 3.0, defaultMaterial, {0,0,-5}, false);

    magnitudeCore.addLightToScene(&dataManager, {0.0, 15.0, 10.0});

    // Upload renderable in buffer
    //pushRenderableInBuffer(mRenderer);
    //pushRenderableInBufferForInstance(&mRenderer);
    magnitudeCore.uploadAllDataToGPU(&dataManager);


    // Set isRunning true to start the loop
    isRunning := true;

    lastTicks := sdl.GetTicks();

    x :f32= -10.0; 
	y :f32= 6.0;
	z :f32= -1.0;
	k :f32= 1;
    velocity :f32= 30;

    updatePosition := true;

    // GameLoop
    for isRunning {
        
        newTicks:= sdl.GetTicks();
        deltaTime := f32(newTicks - lastTicks) / 1000;
        lastTicks = newTicks;

        r1 := magnitudeCore.getRenderableObject(&dataManager, cubeCollision1);
        r2 := magnitudeCore.getRenderableObject(&dataManager, cubeCollision2);
        r3 := magnitudeCore.getRenderableObject(&dataManager, cubeCollision3);
        r4 := magnitudeCore.getRenderableObject(&dataManager, cubeCollision4);
        r5 := magnitudeCore.getRenderableObject(&dataManager, cubeCollision5);
        r6 := magnitudeCore.getRenderableObject(&dataManager, cubeCollision6);


        if(r1.position.x <= -10){
            magnitudeCore.setVelocity((r1.velocity.x *-1), 0.0, 0.0, r1);
        }
        if(r2.position.x >= 10){
            magnitudeCore.setVelocity((r2.velocity.x *-1), 0.0, 0.0, r2);
        }

        magnitudeCore.resolve_swept(r1, r2, deltaTime);

        if(r3.position.y >= 15){
            magnitudeCore.setVelocity(0.0,(r3.velocity.y *-1), 0.0, r3);
        }
        if(r4.position.y <= -5){
            magnitudeCore.setVelocity(0.0,(r4.velocity.y *-1), 0.0, r4);
        }

        magnitudeCore.resolve_swept(r3, r4, deltaTime);

        if(r5.position.z <= -11){
            magnitudeCore.setVelocity(0.0, 0.0, (r5.velocity.z *-1), r5);
        }
        if(r6.position.z >= 11){
            magnitudeCore.setVelocity(0.0, 0.0,(r6.velocity.z *-1), r6);
        }

       magnitudeCore.resolve_swept(r5, r6, deltaTime);

        
        magnitudeCore.updateAllPhysics(&dataManager, deltaTime);

        // Renderer update
        isRunning = magnitudeCore.update(&dataManager.renderer, deltaTime);
        //isRunning = updateInstance(&mRenderer, detaTime);
    }

    magnitudeCore.cleanRenderer(&dataManager.renderer);
}