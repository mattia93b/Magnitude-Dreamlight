static const float PI = 3.14159265359;

struct Material 
{
    uint texture_idx_albedo;
    uint texture_idx_metallic;
    uint texture_idx_roughness;
    uint texture_idx_normal;
    uint texture_idx_ao;
};

// TEXTURE
Texture2D u_Textures[16] : register(t0, space2);
SamplerState u_Sampler   : register(s0, space2);
// MATERIAL BUFFER
StructuredBuffer<Material> materials : register(t16, space2);

// INPUT
struct SPIRV_Cross_Input
{
    float3 v_position : TEXCOORD0;
    float3 v_normals : TEXCOORD1;
    uint materialIndex : TEXCOORD2;
    float2 v_uv : TEXCOORD3;
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

// SUPPORT FUNCTION
float DistributionGGX(float3 N, float3 H, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;

    float num = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness) {
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;

    float num = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    return num / denom;
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughness) {
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}

float3 FresnelSchlick(float cosTheta, float3 F0) {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

// MAIN 
SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    uint index = stage_input.materialIndex;

    uint k = 16 * uint(materials[index].texture_idx_albedo / 16);

    uint texIdx = materials[index].texture_idx_albedo - k;
    uint texIdx_metallic = materials[index].texture_idx_metallic - k;
    uint texIdx_roughness = materials[index].texture_idx_roughness - k;
    uint texIdx_normal = materials[index].texture_idx_normal - k;
    uint texIdx_ao = materials[index].texture_idx_ao - k;

    float3 normalSample = u_Textures[texIdx_normal].Sample(u_Sampler, stage_input.v_uv).rgb;
    float3 N_tangent = normalSample * 2.0 - 1.0;

    float3 N_geo = normalize(stage_input.v_normals);
    float3 dp1   = ddx(stage_input.v_position);
    float3 dp2   = ddy(stage_input.v_position);
    float2 duv1  = ddx(stage_input.v_uv);
    float2 duv2  = ddy(stage_input.v_uv);

    float3 T = normalize(dp1 * duv2.y - dp2 * duv1.y);
    float3 B = normalize(cross(N_geo, T));
    float3x3 TBN = float3x3(T, B, N_geo);


    float4 texColor = u_Textures[texIdx].Sample(u_Sampler, stage_input.v_uv);

    float3 albedo = texColor.rgb;
    float metallic = u_Textures[texIdx_metallic].Sample(u_Sampler, stage_input.v_uv).r;
    float roughness = u_Textures[texIdx_roughness].Sample(u_Sampler, stage_input.v_uv).r;
    roughness = max(roughness, 0.03);
    float ao = u_Textures[texIdx_ao].Sample(u_Sampler, stage_input.v_uv).r;

    float3 N = normalize(mul(N_tangent, TBN));
    float3 V = normalize(u_cameraPosition.xyz - stage_input.v_position);

    float3 F0 = float3(0.04, 0.04, 0.04); 
    //F0 = materials[index].specular_color;
    F0 = lerp(F0, albedo, metallic);

    float3 L = normalize(u_lightPosition.xyz - stage_input.v_position);
    float3 H = normalize(V + L);
    
    float distance = length(u_lightPosition.xyz - stage_input.v_position);
    float attenuation = 1.0 / (distance * distance);
    //float attenuation = 1.0;
    float3 radiance = u_lightColor.xyz * u_lightIntensity.x * attenuation;

    float NDF = DistributionGGX(N, H, roughness);   
    float G   = GeometrySmith(N, V, L, roughness);    
    float3 F  = FresnelSchlick(max(dot(H, V), 0.0), F0);      

    float3 numerator    = NDF * G * F; 
    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
    float3 specular = numerator / denominator;

    float3 kS = F;
    float3 kD = float3(1.0, 1.0, 1.0) - kS;
    kD *= 1.0 - metallic;

    float NdotL = max(dot(N, L), 0.0);

    float3 Lo = (kD * albedo / PI + specular) * radiance * NdotL;

    float3 ambient = float3(0.03, 0.03, 0.03) * albedo * ao;

    float3 color = ambient + Lo;

    color = color / (color + float3(1.0, 1.0, 1.0));
    color = pow(color, float3(1.0/2.2, 1.0/2.2, 1.0/2.2));

    SPIRV_Cross_Output stage_output;
    stage_output.FragColor = float4(color, 1.0);
    return stage_output;
}
