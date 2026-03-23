// INPUT
struct SPIRV_Cross_Input
{
    float3 v_position : TEXCOORD0;
    float2 v_uv : TEXCOORD1;
};
// OUTPUT
struct SPIRV_Cross_Output
{
    float4 FragColor : SV_Target0;
};
// MAIN
SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    SPIRV_Cross_Output stage_output;
    stage_output.FragColor = float4(0.0, 1.0, 0.0, 1.0);
    return stage_output;
}