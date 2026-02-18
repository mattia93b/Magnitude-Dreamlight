
struct Material 
{
    float4 ambient;
    float4 diffuse;
    float4 specular;
    float shininess;
};
// MATERIAL BUFFER
StructuredBuffer<Material> materials : register(t0, space2);
// INPUT
struct SPIRV_Cross_Input
{
    float3 v_position : TEXCOORD0;
    float3 v_normals : TEXCOORD1;
    uint materialIndex : TEXCOORD2;
};
// OUTPUT
struct SPIRV_Cross_Output
{
    float4 FragColor : SV_Target0;
};
// UNIFORMS
cbuffer lightInfo : register(b0, space3){
    float4 u_lightPosition :  packoffset(c0);
    float4 u_lightColor :     packoffset(c1);
    float4 u_lightIntensity : packoffset(c2);
};

cbuffer cameraInfo : register(b1, space3){
    float4 u_cameraPosition :  packoffset(c0);
};

// MAIN 
SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    float4 lightPos = u_lightPosition;

    uint index = stage_input.materialIndex;

    float4 matAmbient = materials[index].ambient;
    float4 matDiffuse = materials[index].diffuse;
    float4 matSpecular = materials[index].specular;
    float matShininess = max(materials[index].shininess, 32.0);
    
    // Ambient
    float ambientStrength = 0.5;
    float4 lightColor = u_lightColor;
    float3 ambient = lightColor.xyz * matAmbient.xyz;
    // Diffuse
    float3 norm = normalize(stage_input.v_normals);
    float3 lightDir = normalize(lightPos.xyz - stage_input.v_position);
    float diff = max(dot(norm, lightDir), 0.0);
    float3 diffuse = diff * (lightColor.xyz * matDiffuse.xyz);
    //float3 result = (ambient + diffuse) * stage_input.v_color.xyz;
    // Specular
    //float specularStrength = 0.5;
    float3 viewDir = normalize(u_cameraPosition.xyz - stage_input.v_position);
    float3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), matShininess);
    float3 specular = lightColor.xyz * (spec * matSpecular.xyz);
    
    float3 result = (ambient + diffuse + specular); //* stage_input.v_color.xyz;

    SPIRV_Cross_Output stage_output;
    stage_output.FragColor = float4(result, 1.0);
    return stage_output;
}
