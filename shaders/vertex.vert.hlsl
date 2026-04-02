// MODEL MATRIX BUFFER
StructuredBuffer<float4x4> modelMatrixBuffer : register(t0, space0);
// INPUT
struct SPIRV_Cross_Input
{
    float3 a_position : TEXCOORD0;
    float3 a_normals : TEXCOORD1;
    float2 a_uv : TEXCOORD2;
    uint modelMatrixIndex : TEXCOORD3;
    uint materialIndex : TEXCOORD4;
};
// OUTPUT
struct SPIRV_Cross_Output
{
    float3 v_position : TEXCOORD0;
    float3 v_normals : TEXCOORD1;
    uint materialIndex : TEXCOORD2;
    float2 v_uv : TEXCOORD3;
    float4 gl_Position : SV_Position;
};
// UNIFORMS
#define MAX_OBJECTS 100
cbuffer UniformBlock : register(b0, space1){
    float4x4 u_ProjectionMatrix : packoffset(c0);
    float4x4 u_ViewMatrix : packoffset(c4);
    float4x4 u_ModelMatrix[MAX_OBJECTS] : packoffset(c8);
};

// MAIN
SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    float3 a_position = stage_input.a_position;
    uint safeIndex = min((uint)stage_input.modelMatrixIndex, MAX_OBJECTS - 1);

    float4 worldPos     = mul(modelMatrixBuffer[safeIndex], float4(a_position, 1.0f));
    float4 viewPos      = mul(u_ViewMatrix, worldPos);
    float4 gl_Position  = mul(u_ProjectionMatrix, viewPos);
    
    float3x3 normalMatrix = (float3x3)modelMatrixBuffer[safeIndex];

    SPIRV_Cross_Output stage_output;
    stage_output.gl_Position    = gl_Position;
    stage_output.v_normals      = normalize(mul(normalMatrix, stage_input.a_normals));
    stage_output.v_position     = mul(modelMatrixBuffer[safeIndex], float4(stage_input.a_position, 1.0)).xyz;
    stage_output.materialIndex  = stage_input.materialIndex;
    stage_output.v_uv           = stage_input.a_uv; 
    return stage_output;
}
