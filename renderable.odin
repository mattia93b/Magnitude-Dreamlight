package main

// logger
import "core:log"
// math
import "core:math/linalg"

Renderable::struct{
    vertex: [dynamic]linalg.Vector3f32,
    index: [dynamic]u16,
    normals: [dynamic]linalg.Vector3f32,
    rgba: linalg.Vector4f32,
    modelMatrix:matrix[4,4]f32,
    material:Material,
}

createColoredCube::proc(x:f32, y:f32, z:f32, width:f32, height:f32, color:[4]f32) -> Renderable{
    // RENDERABLE
    cube := Renderable{}

    // VERTEX
    // front
    append(&cube.vertex, linalg.Vector3f32{0.0, 0.0, 0.0}); //0
    append(&cube.vertex, linalg.Vector3f32{width, 0.0, 0.0}); //1
    append(&cube.vertex, linalg.Vector3f32{width, height, 0.0}); //2
    append(&cube.vertex, linalg.Vector3f32{0.0, height, 0.0}); //3
    // back
    append(&cube.vertex, linalg.Vector3f32{0.0, 0.0, width}); //4
    append(&cube.vertex, linalg.Vector3f32{width, 0.0, width}); //5
    append(&cube.vertex, linalg.Vector3f32{width, height, width}); //6
    append(&cube.vertex, linalg.Vector3f32{0.0, height, width}); //7
    //left
    append(&cube.vertex, linalg.Vector3f32{0.0, 0.0, width}); //4
    append(&cube.vertex, linalg.Vector3f32{0.0, 0.0, 0.0}); //0
    append(&cube.vertex, linalg.Vector3f32{0.0, height, 0.0}); //3
    append(&cube.vertex, linalg.Vector3f32{0.0, height, width}); //7
    //right
    append(&cube.vertex, linalg.Vector3f32{width, 0.0, 0.0}); //1
    append(&cube.vertex, linalg.Vector3f32{width, 0.0, width}); //5
    append(&cube.vertex, linalg.Vector3f32{width, height, width}); //6
    append(&cube.vertex, linalg.Vector3f32{width, height, 0.0}); //2
    //top
    append(&cube.vertex, linalg.Vector3f32{0.0, height, 0.0}); //3
    append(&cube.vertex, linalg.Vector3f32{width, height, 0.0}); //2
    append(&cube.vertex, linalg.Vector3f32{width, height, width}); //6
    append(&cube.vertex, linalg.Vector3f32{0.0, height, width}); //7
    //bottom
    append(&cube.vertex, linalg.Vector3f32{0.0, 0.0, width}); //4
    append(&cube.vertex, linalg.Vector3f32{width, 0.0, width}); //5
    append(&cube.vertex, linalg.Vector3f32{width, 0.0, 0.0}); //1
    append(&cube.vertex, linalg.Vector3f32{0.0, 0.0, 0.0}); //0


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


    // COLOR
    cube.rgba = color;


    // MODEL MATRIX
    cube.modelMatrix = linalg.matrix4_translate_f32({x, y, z});

    cube.material = obsidian();

    return cube;
}


createColoredSphere::proc(xPos:f32, yPos:f32, zPos:f32, radius:f64, stackCount:int, sectorCount:int, color:[4]f32)  -> Renderable {

    sphere := Renderable{};

    PI :f64 = linalg.acos(-1.0);

    x, y, z, xy:f64;                              // vertex position
    nx, ny, nz : f64; 
    lengthInv :f64= 1.0 / radius;                 // normal
    s, t:f32;                                     // texCoord

    sectorStep :f64= 2 * PI / cast(f64)sectorCount;
    stackStep :f64= PI / cast(f64)stackCount;
    sectorAngle, stackAngle:f64;

    verticesV :[dynamic] linalg.Vector3f32;
    normalsV:[dynamic] linalg.Vector3f32;
    //std::vector<maths::vec3> textureCoordV;

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
            //s = (float)j / sectorCount;
            //t = (float)i / stackCount;
            //addTexCoord(s, t);
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
    for i = 0; i < count - 1; i = i + 3 {
        j = j + 2;
        append(&sphere.vertex, verticesV[i]);
        append(&sphere.vertex, verticesV[i + 1]);
        append(&sphere.vertex, verticesV[i + 2]);

        append(&sphere.normals, normalsV[i]);
        append(&sphere.normals, normalsV[i + 1]);
        append(&sphere.normals, normalsV[i + 2]);

        //interleavedVertices.push_back(texCoords[j]);
        //interleavedVertices.push_back(texCoords[j + 1]);
    }

    // COLOR
    sphere.rgba = color;

    // MODEL MATRIX
    sphere.modelMatrix = linalg.matrix4_translate_f32({xPos, yPos, zPos});

    sphere.material = obsidian();

    return sphere;

}


