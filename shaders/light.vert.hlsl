static float4 gl_Position;

struct SPIRV_Cross_Input
{
    float3 a_position : TEXCOORD0;
    float4 a_color : TEXCOORD1;
    float3 a_normals : TEXCOORD2;
    uint modelMatrixIndex : TEXCOORD3;
};

struct SPIRV_Cross_Output
{
    float4 gl_Position : SV_Position;
};


// Uniforms
#define MAX_OBJECTS 100
cbuffer UniformBlock : register(b0, space1){
    float4x4 ProjectionMatrix : packoffset(c0);
    float4x4 ViewMatrix : packoffset(c4);
    float4x4 ModelMatrix[MAX_OBJECTS] : packoffset(c8);
};


SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input){

    float4 worldPos = mul(ModelMatrix[stage_input.modelMatrixIndex], float4(stage_input.a_position, 1.0f));
    float4 viewPos  = mul(ViewMatrix, worldPos);
    gl_Position     = mul(ProjectionMatrix, viewPos);
    
    SPIRV_Cross_Output stage_output;
    stage_output.gl_Position = gl_Position;
    return stage_output;
}