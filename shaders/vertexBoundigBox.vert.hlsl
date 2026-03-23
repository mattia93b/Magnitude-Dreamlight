// INPUT
struct SPIRV_Cross_Input
{
    float3 a_position : TEXCOORD0;
    uint modelMatrixIndex : TEXCOORD1;
};
// OUTPUT
struct SPIRV_Cross_Output
{
    float3 v_position : TEXCOORD0;
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

    float4 worldPos     = mul(u_ModelMatrix[safeIndex], float4(a_position, 1.0f));
    float4 viewPos      = mul(u_ViewMatrix, worldPos);
    float4 gl_Position  = mul(u_ProjectionMatrix, viewPos);

    SPIRV_Cross_Output stage_output;
    stage_output.gl_Position    = gl_Position;
    stage_output.v_position     = mul(u_ModelMatrix[safeIndex], float4(stage_input.a_position, 1.0)).xyz;
    return stage_output;
}