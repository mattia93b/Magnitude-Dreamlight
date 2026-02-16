static float4 FragColor;
static float4 v_color;

struct Material 
{
    float4 ambient;
    float4 diffuse;
    float4 specular;
    float shininess;
};

StructuredBuffer<Material> materials : register(t0, space2);

struct SPIRV_Cross_Input
{
    //float4 v_color : TEXCOORD0;
    float3 v_position : TEXCOORD0;
    float3 v_normals : TEXCOORD1;
    float4 l_position : TEXCOORD2;
    float4 cameraPosition : TEXCOORD3;
    uint materialIndex : TEXCOORD4;
};

struct SPIRV_Cross_Output
{
    float4 FragColor : SV_Target0;
};

// MAIN 
SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    float4 lightPos = stage_input.l_position;//float4(0.0, 15.0, 10.0, 0.0);

    uint index = stage_input.materialIndex;

    float4 matAmbient = materials[index].ambient;
    float4 matDiffuse = materials[index].diffuse;
    float4 matSpecular = materials[index].specular;
    float matShininess = max(materials[index].shininess, 32.0);
    
    // Ambient
    float ambientStrength = 0.5;
    float4 lightColor = float4(float3(1.0, 1.0, 1.0), 1.0);
    float3 ambient = lightColor.xyz * matAmbient.xyz;
    // Diffuse
    float3 norm = normalize(stage_input.v_normals);
    float3 lightDir = normalize(lightPos.xyz - stage_input.v_position);
    float diff = max(dot(norm, lightDir), 0.0);
    float3 diffuse = diff * (lightColor.xyz * matDiffuse.xyz);
    //float3 result = (ambient + diffuse) * stage_input.v_color.xyz;
    // Specular
    //float specularStrength = 0.5;
    float3 viewDir = normalize(stage_input.cameraPosition.xyz - stage_input.v_position);
    float3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), matShininess);
    float3 specular = lightColor.xyz * (spec * matSpecular.xyz);
    
    float3 result = (ambient + diffuse + specular); //* stage_input.v_color.xyz;

    SPIRV_Cross_Output stage_output;
    stage_output.FragColor = float4(result, 1.0);
    return stage_output;
}
