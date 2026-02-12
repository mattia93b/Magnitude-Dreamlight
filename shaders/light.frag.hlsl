
struct SPIRV_Cross_Output
{
    float4 FragColor : SV_Target0;
};


SPIRV_Cross_Output main()
{
    SPIRV_Cross_Output stage_output;
    stage_output.FragColor = float4(1.0, 1.0, 1.0, 1.0); 
    return stage_output;
}