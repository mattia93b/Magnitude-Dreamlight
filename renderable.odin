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

    return cube;
}