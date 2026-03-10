package magnitudeCore

// logger
import "core:log"
// SDL3 bindings
import sdl "vendor:sdl3"
// math
import "core:math/linalg"

// Uniform struct to send to GPU
UBO::struct #align(16){
    projMat : matrix[4,4]f32,
    viewMat : matrix[4,4]f32,
    modelMat : [100]matrix[4,4]f32,
}

// Light info
LightInfo::struct #align(16){
    lightPosition : linalg.Vector4f32,
    lightColor : linalg.Vector4f32, 
    lightIntensity : linalg.Vector4f32, 
}