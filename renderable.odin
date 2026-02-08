package main

// logger
import "core:log"
// math
import "core:math/linalg"

Renderable::struct{
    vertex: [dynamic]Vertex,
    index: [dynamic]u16,
    modelMatrix:matrix[4,4]f32,
}

Vertex::struct{
    width,height,z :f32,    // vec3 position
    r,g,b,a: f32,           // vec4 color
    modelMatrixIndex: u32,
}

createColoredCube::proc(x:f32, y:f32, z:f32, width:f32, height:f32, color:[4]f32) -> Renderable{
    // RENDERABLE
    cube := Renderable{}

    // VERTEX
    // front
    append(&cube.vertex, Vertex{width=0.0, height=0.0, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //0
    append(&cube.vertex, Vertex{width=width, height=0.0, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //1
    append(&cube.vertex, Vertex{width=width, height=height, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //2
    append(&cube.vertex, Vertex{width=0.0, height=height, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //3
    // back
    append(&cube.vertex, Vertex{width=0.0, height=0.0, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //4
    append(&cube.vertex, Vertex{width=width, height=0.0, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //5
    append(&cube.vertex, Vertex{width=width, height=height, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //6
    append(&cube.vertex, Vertex{width=0.0, height=height, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //7
    //left
    append(&cube.vertex, Vertex{width=0.0, height=0.0, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //4
    append(&cube.vertex, Vertex{width=0.0, height=0.0, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //0
    append(&cube.vertex, Vertex{width=0.0, height=height, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //3
    append(&cube.vertex, Vertex{width=0.0, height=height, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //7
    //right
    append(&cube.vertex, Vertex{width=width, height=0.0, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //1
    append(&cube.vertex, Vertex{width=width, height=0.0, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //5
    append(&cube.vertex, Vertex{width=width, height=height, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //6
    append(&cube.vertex, Vertex{width=width, height=height, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //2
    //top
    append(&cube.vertex, Vertex{width=0.0, height=height, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //3
    append(&cube.vertex, Vertex{width=width, height=height, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //2
    append(&cube.vertex, Vertex{width=width, height=height, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //6
    append(&cube.vertex, Vertex{width=0.0, height=height, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //7
    //bottom
    append(&cube.vertex, Vertex{width=0.0, height=0.0, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //4
    append(&cube.vertex, Vertex{width=width, height=0.0, z=width, r=color[0], g=color[1], b=color[2], a=color[3]}); //5
    append(&cube.vertex, Vertex{width=width, height=0.0, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //1
    append(&cube.vertex, Vertex{width=0.0, height=0.0, z=0.0, r=color[0], g=color[1], b=color[2], a=color[3]}); //0

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

    // MODEL MATRIX
    cube.modelMatrix = linalg.matrix4_translate_f32({x, y, z});

    return cube;
}