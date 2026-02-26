package main

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"

Renderable::struct{
    vertex: [dynamic]linalg.Vector3f32,
    index: [dynamic]u16,
    normals: [dynamic]linalg.Vector3f32,
    UVs: [dynamic]linalg.Vector2f32,
    modelMatrix:matrix[4,4]f32,
    material:Material,
    materialPBR: MaterialPBR,
    texture:^sdl.Surface,
}


updatePosition::proc(x:f32, y:f32, z:f32, renderable:^Renderable){
    // MODEL MATRIX
    renderable.modelMatrix = linalg.matrix4_translate_f32({x, y, z});
}

createColoredCube::proc(x:f32, y:f32, z:f32, width:f32, height:f32, texturePath:cstring = "") -> Renderable{
    // RENDERABLE
    cube := Renderable{}

    hw := width / 2.0
    hh := height / 2.0
    hd := width / 2.0

    // front
    append(&cube.vertex, linalg.Vector3f32{-hw, -hh, -hd}) // 0
    append(&cube.vertex, linalg.Vector3f32{ hw, -hh, -hd}) // 1
    append(&cube.vertex, linalg.Vector3f32{ hw,  hh, -hd}) // 2
    append(&cube.vertex, linalg.Vector3f32{-hw,  hh, -hd}) // 3

    // back
    append(&cube.vertex, linalg.Vector3f32{-hw, -hh,  hd}) // 4
    append(&cube.vertex, linalg.Vector3f32{ hw, -hh,  hd}) // 5
    append(&cube.vertex, linalg.Vector3f32{ hw,  hh,  hd}) // 6
    append(&cube.vertex, linalg.Vector3f32{-hw,  hh,  hd}) // 7

    // left
    append(&cube.vertex, linalg.Vector3f32{-hw, -hh,  hd}) 
    append(&cube.vertex, linalg.Vector3f32{-hw, -hh, -hd}) 
    append(&cube.vertex, linalg.Vector3f32{-hw,  hh, -hd}) 
    append(&cube.vertex, linalg.Vector3f32{-hw,  hh,  hd}) 

    // right
    append(&cube.vertex, linalg.Vector3f32{ hw, -hh, -hd}) 
    append(&cube.vertex, linalg.Vector3f32{ hw, -hh,  hd}) 
    append(&cube.vertex, linalg.Vector3f32{ hw,  hh,  hd}) 
    append(&cube.vertex, linalg.Vector3f32{ hw,  hh, -hd}) 

    // top 
    append(&cube.vertex, linalg.Vector3f32{-hw,  hh, -hd}) 
    append(&cube.vertex, linalg.Vector3f32{ hw,  hh, -hd}) 
    append(&cube.vertex, linalg.Vector3f32{ hw,  hh,  hd}) 
    append(&cube.vertex, linalg.Vector3f32{-hw,  hh,  hd}) 

    // bottom 
    append(&cube.vertex, linalg.Vector3f32{-hw, -hh,  hd}) 
    append(&cube.vertex, linalg.Vector3f32{ hw, -hh,  hd}) 
    append(&cube.vertex, linalg.Vector3f32{ hw, -hh, -hd}) 
    append(&cube.vertex, linalg.Vector3f32{-hw, -hh, -hd})


    // INDEX 
    offset := 0;
    for i := 0; i < 31; i += 6
    {
        append(&cube.index, cast(u16)(offset + 0));
        append(&cube.index, cast(u16)(offset + 1));
        append(&cube.index, cast(u16)(offset + 2));

        append(&cube.index, cast(u16)(offset + 2));
        append(&cube.index, cast(u16)(offset + 3));
        append(&cube.index, cast(u16)(offset + 0));

        offset += 4;

    }


    // NORMALS
    // front
    append(&cube.normals, linalg.Vector3f32{0.0, 0.0, -1.0}); //0
    append(&cube.normals, linalg.Vector3f32{0.0, 0.0, -1.0}); //1
    append(&cube.normals, linalg.Vector3f32{0.0, 0.0, -1.0}); //2
    append(&cube.normals, linalg.Vector3f32{0.0, 0.0, -1.0}); //3
    // back
    append(&cube.normals, linalg.Vector3f32{0.0, 0.0, 1.0}); //4
    append(&cube.normals, linalg.Vector3f32{0.0, 0.0, 1.0}); //5
    append(&cube.normals, linalg.Vector3f32{0.0, 0.0, 1.0}); //6
    append(&cube.normals, linalg.Vector3f32{0.0, 0.0, 1.0}); //7
    //left
    append(&cube.normals, linalg.Vector3f32{-1.0, 0.0, 0.0}); //4
    append(&cube.normals, linalg.Vector3f32{-1.0, 0.0, 0.0}); //0
    append(&cube.normals, linalg.Vector3f32{-1.0, 0.0, 0.0}); //3
    append(&cube.normals, linalg.Vector3f32{-1.0, 0.0, 0.0}); //7
    //right
    append(&cube.normals, linalg.Vector3f32{1.0, 0.0, 0.0}); //1
    append(&cube.normals, linalg.Vector3f32{1.0, 0.0, 0.0}); //5
    append(&cube.normals, linalg.Vector3f32{1.0, 0.0, 0.0}); //6
    append(&cube.normals, linalg.Vector3f32{1.0, 0.0, 0.0}); //2
    //top
    append(&cube.normals, linalg.Vector3f32{0.0, 1.0, 0.0}); //4
    append(&cube.normals, linalg.Vector3f32{0.0, 1.0, 0.0}); //5
    append(&cube.normals, linalg.Vector3f32{0.0, 1.0, 0.0}); //1
    append(&cube.normals, linalg.Vector3f32{0.0, 1.0, 0.0}); //0
    //bottom
    append(&cube.normals, linalg.Vector3f32{0.0, -1.0, 0.0}); //3
    append(&cube.normals, linalg.Vector3f32{0.0, -1.0, 0.0}); //2
    append(&cube.normals, linalg.Vector3f32{0.0, -1.0, 0.0}); //6
    append(&cube.normals, linalg.Vector3f32{0.0, -1.0, 0.0}); //7

    // UVs
    append(&cube.UVs, linalg.Vector2f32{0, 0});
    append(&cube.UVs, linalg.Vector2f32{0, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 0});

    append(&cube.UVs, linalg.Vector2f32{0, 0});
    append(&cube.UVs, linalg.Vector2f32{0, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 0});

    append(&cube.UVs, linalg.Vector2f32{0, 0});
    append(&cube.UVs, linalg.Vector2f32{0, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 0});

    append(&cube.UVs, linalg.Vector2f32{0, 0});
    append(&cube.UVs, linalg.Vector2f32{0, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 0});

    append(&cube.UVs, linalg.Vector2f32{0, 0});
    append(&cube.UVs, linalg.Vector2f32{0, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 0});

    append(&cube.UVs, linalg.Vector2f32{0, 0});
    append(&cube.UVs, linalg.Vector2f32{0, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 1});
    append(&cube.UVs, linalg.Vector2f32{1, 0});


    // TEXTURE
    if texturePath != "" {
        cube.texture = loadTexturePNG(texturePath, 4);
    }
    

    // MODEL MATRIX
    cube.modelMatrix = linalg.matrix4_translate_f32({x, y, z});

    cube.material = redPlastic();

    cube.materialPBR = SR_Aluminum();

    return cube;
}


createColoredSphere::proc(xPos:f32, yPos:f32, zPos:f32, radius:f64, stackCount:int, sectorCount:int)  -> Renderable {

    sphere := Renderable{};

    PI :f64 = linalg.acos(-1.0);

    x, y, z, xy:f64;                              // vertex position
    nx, ny, nz : f64; 
    lengthInv :f64= 1.0 / radius;                 // normal
    s, t:f32;                                     // texCoord

    sectorStep :f64= 2 * PI / cast(f64)sectorCount;
    stackStep :f64= PI / cast(f64)stackCount;
    sectorAngle, stackAngle:f64;

    verticesV : [dynamic] linalg.Vector3f32;
    normalsV : [dynamic] linalg.Vector3f32;
    uvsV : [dynamic]linalg.Vector2f32;

    for i :int= 0; i <= stackCount; i=i+1 {
        stackAngle = PI / 2 - cast(f64)i * cast(f64)stackStep;        // starting from pi/2 to -pi/2
        xy = radius * linalg.cos(stackAngle);             // r * cos(u)
        z = radius * linalg.sin(stackAngle);              // r * sin(u)

        // add (sectorCount+1) vertices per stack
        // the first and last vertices have same position and normal, but different tex coords
        for j :int= 0; j <= sectorCount; j=j+1 {
            sectorAngle = cast(f64)j * sectorStep;           // starting from 0 to 2pi

            // vertex position
            x = xy * linalg.cos(sectorAngle);             // r * cos(u) * cos(v)
            y = xy * linalg.sin(sectorAngle);             // r * cos(u) * sin(v)
            append(&verticesV, linalg.Vector3f32{cast(f32)x, cast(f32)y, cast(f32)z});

            // normalized vertex normal
            nx = x * lengthInv;
            ny = y * lengthInv;
            nz = z * lengthInv;
            append(&normalsV, linalg.Vector3f32{cast(f32)nx, cast(f32)ny, cast(f32)nz});

            // vertex tex coord between [0, 1]
            s = cast(f32)j / cast(f32)sectorCount;
            t = cast(f32)i / cast(f32)stackCount;
            append(&uvsV, linalg.Vector2f32{s, t});
        }

    }


    // indices
    //  k1--k1+1
    //  |  / |
    //  | /  |
    //  k2--k2+1
    k1, k2 : int;
    for i :int= 0; i < stackCount; i=i+1 {
        k1 = i * (sectorCount + 1);     // beginning of current stack
        k2 = k1 + sectorCount + 1;      // beginning of next stack

        for j :int= 0; j < sectorCount; j=j+1 {
           
            // 2 triangles per sector excluding 1st and last stacks
            if (i != 0)
            {
                append(&sphere.index, cast(u16)k1);   // k1---k2---k1+1
                append(&sphere.index, cast(u16)k2);   // k1---k2---k1+1
                append(&sphere.index, cast(u16)(k1 + 1));   // k1---k2---k1+1
            }

            if (i != (stackCount - 1))
            {
                append(&sphere.index, cast(u16)(k1 + 1)); // k1+1---k2---k2+1
                append(&sphere.index ,cast(u16)(k2)); // k1+1---k2---k2+1
                append(&sphere.index, cast(u16)(k2 + 1)); // k1+1---k2---k2+1
            }
            // increment at the end of operation
            k1=k1+1;
            k2=k2+1;
        }
    }


    i, j:int;
    j = 0;
    count :int= len(verticesV);
    for i = 0; i < count; i = i + 1 {
        
        append(&sphere.vertex, verticesV[i])

        append(&sphere.normals, normalsV[i])

        append(&sphere.UVs, uvsV[i])
    }

    // TEXTURE

    // MODEL MATRIX
    sphere.modelMatrix = linalg.matrix4_translate_f32({xPos, yPos, zPos});

    sphere.material = gold();

    sphere.materialPBR = SR_Gold();

    return sphere;

}


