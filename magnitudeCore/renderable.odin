package magnitudeCore

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"
import "core:math"

Renderable::struct{
    vertex: [dynamic]linalg.Vector3f32,
    index: [dynamic]u16,
    normals: [dynamic]linalg.Vector3f32,
    UVs: [dynamic]linalg.Vector2f32,
    collisionCorners: [8]linalg.Vector3f32,
    collisionIndices: [24]u32,
    modelMatrix:matrix[4,4]f32,
    materialID:u32,
    aabb_min    : linalg.Vector3f32,
    aabb_max    : linalg.Vector3f32,
    position    : linalg.Vector3f32,
    velocity    : linalg.Vector3f32,
    is_static   : bool,
    physics_resolved : bool,
}


setPosition::proc(x:f32, y:f32, z:f32, renderable:^Renderable){
    // POSITION
    renderable.position = {x, y, z};
    // MODEL MATRIX
    renderable.modelMatrix = linalg.matrix4_translate_f32({x, y, z});
}

setVelocity::proc(Vx:f32, Vy:f32, Vz:f32, renderable:^Renderable){
    // VELOCITY
    renderable.velocity = {Vx, Vy, Vz};
}

createColoredCube::proc(xPos:f32, yPos:f32, zPos:f32, width:f32, height:f32, materialID:u32, velocity:linalg.Vector3f32={0,0,0}, is_Static:bool = true) -> Renderable {

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


    // MATERIAL
    cube.materialID = materialID;

    // MODEL MATRIX
    cube.modelMatrix = linalg.matrix4_translate_f32({xPos, yPos, zPos});

    // POSITION
    cube.position = {xPos, yPos, zPos};

    // VELOCITY
    cube.velocity = velocity;

    // IS STATIC
    cube.is_static = is_Static;

    // COLLISION
    cube.aabb_min, cube.aabb_max = compute_local_aabb(&cube);

    lo := cube.aabb_min
    hi := cube.aabb_max

    cube.collisionCorners = [8]linalg.Vector3f32{
        {lo.x, lo.y, lo.z},
        {hi.x, lo.y, lo.z},
        {lo.x, hi.y, lo.z},
        {hi.x, hi.y, lo.z},
        {lo.x, lo.y, hi.z},
        {hi.x, lo.y, hi.z},
        {lo.x, hi.y, hi.z},
        {hi.x, hi.y, hi.z},
    }

    cube.collisionIndices = [24]u32{
        0, 1,  1, 3,  3, 2,  2, 0,
        4, 5,  5, 7,  7, 6,  6, 4,
        0, 4,  1, 5,  2, 6,  3, 7,
    }

    return cube;
}


createColoredSphere::proc(xPos:f32, yPos:f32, zPos:f32, radius:f64, stackCount:int, sectorCount:int, materialID:u32, velocity:linalg.Vector3f32={0,0,0}, is_Static:bool = true)  -> Renderable {
    
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

    // MATERIAL
    sphere.materialID = materialID;

    // MODEL MATRIX
    sphere.modelMatrix = linalg.matrix4_translate_f32({xPos, yPos, zPos});

    // POSITION
    sphere.position = {xPos, yPos, zPos};

    // VELOCITY
    sphere.velocity = velocity;

    // IS STATIC
    sphere.is_static = is_Static;

    // COLLISION
    sphere.aabb_min, sphere.aabb_max = compute_local_aabb(&sphere);
    
    lo := sphere.aabb_min
    hi := sphere.aabb_max

    sphere.collisionCorners = [8]linalg.Vector3f32{
        {lo.x, lo.y, lo.z},
        {hi.x, lo.y, lo.z},
        {lo.x, hi.y, lo.z},
        {hi.x, hi.y, lo.z},
        {lo.x, lo.y, hi.z},
        {hi.x, lo.y, hi.z},
        {lo.x, hi.y, hi.z},
        {hi.x, hi.y, hi.z},
    }

    sphere.collisionIndices = [24]u32{
        0, 1,  1, 3,  3, 2,  2, 0,
        4, 5,  5, 7,  7, 6,  6, 4,
        0, 4,  1, 5,  2, 6,  3, 7,
    }

    return sphere;

}


compute_local_aabb :: proc(r: ^Renderable) -> (min_pt, max_pt: linalg.Vector3f32) {
    min_pt = linalg.Vector3f32{max(f32), max(f32), max(f32)}
    max_pt = linalg.Vector3f32{-max(f32), -max(f32), -max(f32)}

    for v in r.vertex {
        p := linalg.Vector3f32{v.x, v.y, v.z}
        min_pt = linalg.min(min_pt, p)
        max_pt = linalg.max(max_pt, p)
    }
    return
}

get_world_aabb :: proc(r: ^Renderable) -> (min_pt, max_pt: linalg.Vector3f32) {
    lo := r.aabb_min
    hi := r.aabb_max

    corners := [8]linalg.Vector4f32{
        {lo.x, lo.y, lo.z, 1},
        {hi.x, lo.y, lo.z, 1},
        {lo.x, hi.y, lo.z, 1},
        {hi.x, hi.y, lo.z, 1},
        {lo.x, lo.y, hi.z, 1},
        {hi.x, lo.y, hi.z, 1},
        {lo.x, hi.y, hi.z, 1},
        {hi.x, hi.y, hi.z, 1},
    }

    min_pt = linalg.Vector3f32{max(f32), max(f32), max(f32)}
    max_pt = linalg.Vector3f32{-max(f32), -max(f32), -max(f32)}

    for c in corners {
        world := (r.modelMatrix * c).xyz
        min_pt = linalg.min(min_pt, world)
        max_pt = linalg.max(max_pt, world)
    }
    return
}


swept_aabb :: proc(r1: ^Renderable, vel1: linalg.Vector3f32, r2: ^Renderable, vel2: linalg.Vector3f32) -> (toi: f32, normal: linalg.Vector3f32) {

    min1, max1 := get_world_aabb(r1)
    min2, max2 := get_world_aabb(r2)

    rel_vel := vel1 - vel2

    entry, exit: linalg.Vector3f32

    for i in 0..<3 {
        if rel_vel[i] > 0 {
            entry[i] = (min2[i] - max1[i]) / rel_vel[i]
            exit[i]  = (max2[i] - min1[i]) / rel_vel[i]
        } else if rel_vel[i] < 0 {
            entry[i] = (max2[i] - min1[i]) / rel_vel[i]
            exit[i]  = (min2[i] - max1[i]) / rel_vel[i]
        } else {
            entry[i] = -max(f32)
            exit[i]  =  max(f32)
        }
    }

    t_entry := max(entry.x, max(entry.y, entry.z))
    t_exit  := min(exit.x,  min(exit.y,  exit.z))

    if t_entry > t_exit || t_entry > 1.0 || t_exit < 0 {
        return max(f32), {}
    }

    if entry.x > entry.y && entry.x > entry.z {
        normal = {-1 if rel_vel.x > 0 else 1, 0, 0}
    } else if entry.y > entry.z {
        normal = {0, -1 if rel_vel.y > 0 else 1, 0}
    } else {
        normal = {0, 0, -1 if rel_vel.z > 0 else 1}
    }

    return t_entry, normal
}

resolve_swept :: proc(r1: ^Renderable, r2: ^Renderable, deltaTime: f32) -> bool {
    if r1.is_static && r2.is_static do return false

    vel1 := r1.velocity * deltaTime;
    vel2 := r2.velocity * deltaTime;

    toi, normal := swept_aabb(r1, vel1, r2, vel2);

    if toi > 1.0 do return false; 

    remaining := 1.0 - toi;

    if !r1.is_static {
        r1.position += vel1 * toi;
        r1.velocity  = reflect(r1.velocity, normal);
        r1.position += r1.velocity * deltaTime * remaining;
        r1.modelMatrix = linalg.matrix4_translate_f32(r1.position);
        r1.physics_resolved = true;
    }
    if !r2.is_static {
        r2.position += vel2 * toi;
        r2.velocity  = reflect(r2.velocity, -normal);
        r2.position += r2.velocity * deltaTime * remaining;
        r2.modelMatrix = linalg.matrix4_translate_f32(r2.position);
        r2.physics_resolved = true;
    }

    return true
}

reflect :: proc(vel: linalg.Vector3f32, normal: linalg.Vector3f32) -> linalg.Vector3f32 {
    return vel - 2 * linalg.dot(vel, normal) * normal;
}

updatePhysics :: proc(r:^Renderable, dt:f32){
    if r.is_static do return
    if r.physics_resolved {
        r.physics_resolved = false
        return
    }
    r.position += r.velocity * dt
    r.modelMatrix = linalg.matrix4_translate_f32(r.position)
}