#pragma pack_matrix(column_major)
static float4 gl_Position;
static float3 a_position;
static float4 v_color;
static float4 a_color;
static uint modelMatrixIndex;
static uint materialIndex;

struct SPIRV_Cross_Input
{
    float3 a_position : TEXCOORD0;
    float4 a_color : TEXCOORD1;
    float3 a_normals : TEXCOORD2;
    uint modelMatrixIndex : TEXCOORD3;
    uint materialIndex : TEXCOORD4;
};

struct SPIRV_Cross_Output
{
    //float4 v_color : TEXCOORD0;
    float3 v_position : TEXCOORD0;
    float3 v_normals : TEXCOORD1;
    float4 l_position :TEXCOORD2;
    float4 cameraPosition : TEXCOORD3;
    uint materialIndex:TEXCOORD4;
    float4 gl_Position : SV_Position;
};

void main_inner(float4x4 projectionMatrix, float4x4 viewMatrix, float4x4 modelMatrix)
{
    float4 worldPos = mul(modelMatrix, float4(a_position, 1.0f));
    float4 viewPos  = mul(viewMatrix, worldPos);
    gl_Position     = mul(projectionMatrix, viewPos);
    v_color = a_color;

    //v_color = float4(1.0, 0.0, 0.0, 1.0);
}

// Uniforms
#define MAX_OBJECTS 100
cbuffer UniformBlock : register(b0, space1){
    float4x4 ProjectionMatrix : packoffset(c0);
    float4x4 ViewMatrix : packoffset(c4);
    float4x4 ModelMatrix[MAX_OBJECTS] : packoffset(c8);
};

cbuffer lightInfo : register(b1, space1){
    float4 lightPosition :  packoffset(c0);
    float4 lightColor :     packoffset(c1);
    float4 lightIntensity : packoffset(c2);
};

cbuffer cameraInfo : register(b2, space1){
    float4 cameraPosition :  packoffset(c0);
};

// MAIN
SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    a_position = stage_input.a_position;
    a_color = stage_input.a_color;

    uint safeIndex = min((uint)stage_input.modelMatrixIndex, MAX_OBJECTS - 1);
    main_inner(ProjectionMatrix, ViewMatrix, ModelMatrix[safeIndex]);
    
    float3x3 normalMatrix = (float3x3)ModelMatrix[safeIndex];

    SPIRV_Cross_Output stage_output;
    stage_output.gl_Position = gl_Position;
    stage_output.v_normals = normalize(mul(normalMatrix, stage_input.a_normals));
    //stage_output.v_normals = stage_input.a_normals;
    stage_output.v_position = mul(ModelMatrix[safeIndex], float4(stage_input.a_position, 1.0)).xyz;
    //stage_output.v_color = v_color;
    stage_output.l_position = lightPosition;
    stage_output.cameraPosition = cameraPosition;
    stage_output.materialIndex = stage_input.materialIndex;
    return stage_output;
}
