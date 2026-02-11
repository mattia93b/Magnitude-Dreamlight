static float4 FragColor;
static float4 v_color;

struct SPIRV_Cross_Input
{
    float4 v_color : TEXCOORD0;
};

struct SPIRV_Cross_Output
{
    float4 FragColor : SV_Target0;
};

void main_inner()
{
    FragColor = v_color;
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    float ambientStrenght = 0.1;
    float4 lightColor = float4(1.0, 1.0, 1.0, 1.0) * ambientStrenght;
    v_color = stage_input.v_color * lightColor;
    main_inner();
    SPIRV_Cross_Output stage_output;
    stage_output.FragColor = FragColor;
    return stage_output;
}
