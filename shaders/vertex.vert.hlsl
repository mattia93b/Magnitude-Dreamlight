static float4 gl_Position;
static float3 a_position;
static float4 v_color;
static float4 a_color;

struct SPIRV_Cross_Input
{
    float3 a_position : TEXCOORD0;
    float4 a_color : TEXCOORD1;
};

struct SPIRV_Cross_Output
{
    float4 v_color : TEXCOORD0;
    float4 gl_Position : SV_Position;
};

void main_inner()
{
    gl_Position = float4(a_position, 1.0f);
    v_color = a_color;
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    a_position = stage_input.a_position;
    a_color = stage_input.a_color;
    main_inner();
    SPIRV_Cross_Output stage_output;
    stage_output.gl_Position = gl_Position;
    stage_output.v_color = v_color;
    return stage_output;
}
