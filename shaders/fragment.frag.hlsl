static float4 FragColor;
static float4 v_color;

struct SPIRV_Cross_Input
{
    float4 v_color : TEXCOORD0;
    float3 v_position : TEXCOORD1;
    float3 v_normals : TEXCOORD2;
    float4 l_position : TEXCOORD3;
};

struct SPIRV_Cross_Output
{
    float4 FragColor : SV_Target0;
};

// MAIN 
SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    float4 lightPos = stage_input.l_position;//float4(0.0, 15.0, 10.0, 0.0);

    // Ambient
    float ambientStrength = 0.5;
    float4 lightColor = float4(float3(1.0, 1.0, 1.0), 1.0);
    float3 ambient = ambientStrength * lightColor.xyz;
    // Diffuse
    float3 norm = normalize(stage_input.v_normals);
    float3 lightDir = normalize(lightPos.xyz - stage_input.v_position);
    float diff = max(dot(norm, lightDir), 0.0);
    float3 diffuse = diff * lightColor.xyz;
    float3 result = (ambient + diffuse) * stage_input.v_color.xyz;

    SPIRV_Cross_Output stage_output;
    stage_output.FragColor = float4(result, 1.0);
    return stage_output;
}
